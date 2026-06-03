package multiimagepicker;

import android.net.Uri;
import android.webkit.MimeTypeMap;
import android.util.Log;

import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.ActivityResultRegistry;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.List;

public class PermissionlessMultiImagePicker extends CordovaPlugin {

    private static final String TAG = "MultiImagePicker";
    private static final String ACTION_PICK = "pickImages";
    private static final String REGISTRY_KEY = "multi_image_picker_key";

    private CallbackContext callbackContext;

    @Override
    public boolean execute(String action, JSONArray args, CallbackContext callbackContext)
            throws JSONException {

        if (ACTION_PICK.equals(action)) {
            this.callbackContext = callbackContext;

            int maxImages = 100;
            try {
                if (args.length() > 0 && !args.isNull(0)) {
                    int val = args.getInt(0);
                    if (val > 0) maxImages = val;
                }
            } catch (JSONException e) {
                Log.w(TAG, "Invalid maxImages arg, using default: " + maxImages);
            }

            final int finalMaxImages = Math.max(2, maxImages);
        
            cordova.getActivity().runOnUiThread(() -> {
                try {
                    // Use ActivityResultRegistry directly — bypasses lifecycle state restriction
                    // This is the correct approach for Cordova plugins where pluginInitialize
                    // is called after RESUMED state, making registerForActivityResult unusable
                    ActivityResultRegistry registry =
                        cordova.getActivity().getActivityResultRegistry();

                    ActivityResultLauncher<PickVisualMediaRequest> launcher =
                        registry.register(
                            REGISTRY_KEY,
                            new ActivityResultContracts.PickMultipleVisualMedia(finalMaxImages),
                            uris -> {
                               
                                if (uris == null || uris.isEmpty()) {
                                    callbackContext.error("cancelled");
                                    return;
                                }

                                cordova.getThreadPool().execute(() -> {
                                    try {
                                        JSONArray result = new JSONArray();
                                        for (Uri uri : uris) {
                                            String filePath = copyToCache(uri);
                                            if (filePath != null) {
                                                result.put(filePath);
                                            }
                                        }

                                        if (result.length() > 0) {
                                            callbackContext.success(result);
                                        } else {
                                            callbackContext.error("failed to process images");
                                        }
                                    } catch (Exception e) {
                                        Log.e(TAG, "Error processing images", e);
                                        callbackContext.error("error: " + e.getMessage());
                                    }
                                });
                            }
                        );

                    launcher.launch(
                        new PickVisualMediaRequest.Builder()
                            .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE)
                            .build()
                    );

                } catch (Exception e) {
                    Log.e(TAG, "Failed to launch picker", e);
                    callbackContext.error("failed to launch picker: " + e.getMessage());
                }
            });

            return true;
        }
        return false;
    }

    private String copyToCache(Uri contentUri) {
        try {
            android.content.ContentResolver resolver =
                cordova.getActivity().getContentResolver();

            String mimeType = resolver.getType(contentUri);
            String ext = MimeTypeMap.getSingleton()
                .getExtensionFromMimeType(mimeType != null ? mimeType : "image/jpeg");
            if (ext == null) ext = "jpg";

            File cacheDir = new File(cordova.getActivity().getCacheDir(), "multiimagepicker");
            if (!cacheDir.exists()) cacheDir.mkdirs();

            String lastSeg = contentUri.getLastPathSegment();
            String safeSeg = (lastSeg != null)
                ? lastSeg.replaceAll("[^a-zA-Z0-9]", "_") : "img";
            String fileName = "img_" + System.currentTimeMillis()
                + "_" + safeSeg + "." + ext;

            File outFile = new File(cacheDir, fileName);

            try (InputStream in  = resolver.openInputStream(contentUri);
                 OutputStream out = new FileOutputStream(outFile)) {

                if (in == null) {
                    return null;
                }

                byte[] buf = new byte[8192];
                int len;
                while ((len = in.read(buf)) != -1) {
                    out.write(buf, 0, len);
                }
            }

            return "file://" + outFile.getAbsolutePath();

        } catch (Exception e) {
            Log.e(TAG, "copyToCache failed", e);
            return null;
        }
    }
}