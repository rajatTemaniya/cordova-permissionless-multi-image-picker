# Cordova Permissionless Multi Image Picker

A lightweight Cordova plugin for selecting multiple images on **Android** and **iOS** without requesting storage or media permissions.

## Why This Plugin Exists

Traditional image picker plugins often require media or storage permissions such as:

- READ_EXTERNAL_STORAGE (Android 12 and below)
- READ_MEDIA_IMAGES (Android 13+)

These permissions can trigger additional Play Store review requirements and are unnecessary when using the modern Android Photo Picker API.

Modern Android provides a system Photo Picker that allows users to select images **without granting storage access** to the application.

Similarly, iOS provides `PHPickerViewController`, which allows image selection without requesting full photo library access.

This plugin was created to leverage these modern platform APIs and provide a simple Cordova interface that:

✅ Requires **no storage permissions**

✅ Requires **no media permissions**

✅ Supports **multiple image selection**

✅ Works on **Android and iOS**

✅ Returns ready-to-use `file://` URIs

<p>
  <strong>⚠️ Note:</strong>
  <span style="color:red">
    This is NOT a camera plugin. If required capturing image using device camera use this plugin with cordova-plugin-camera
  </span>
</p>


## Features

- Select one or multiple images
- No `READ_MEDIA_IMAGES`
- No `READ_EXTERNAL_STORAGE`
- No `WRITE_EXTERNAL_STORAGE`
- No `NSPhotoLibraryUsageDescription`
- Native Android Photo Picker support
- Native iOS PHPicker support
- Returns local `file://` paths
- Works with `cordova-plugin-camera`

---

## Supported Platforms

| Platform | Supported |
|----------|------------|
| Android | ✅ |
| iOS | ✅ |

---

## Installation

### NPM

```bash
cordova plugin add @rajattemaniya/cordova-plugin-permissionless-multi-image-picker
```

### GitHub

```bash
cordova plugin add https://github.com/rajatTemaniya/cordova-permissionless-multi-image-picker.git
```

---

## Usage

```javascript
const fileOptions = {
  maxImages: 5
};

cordova.plugins.PermissionlessMultiImagePicker.pickImages(
  function (results) {

    // Plugin always returns file:// URIs
    const files = Array.isArray(results) ? results: [results];

  },
  function (error) {

    console.error(error);

  },
  fileOptions
);
```

---

## Options

| Option | Type | Description |
|----------|----------|----------|
| maxImages | Number | Maximum images allowed. Use 0 for unlimited selection. |

### Example

```javascript
{
  maxImages: 10
}
```

---

## Response

Success callback returns an array of local file URIs.

```javascript
[
  "file:///data/user/0/com.app/cache/image1.jpg",
  "file:///data/user/0/com.app/cache/image2.jpg"
]
```

or on iOS

```javascript
[
  "file:///var/mobile/Containers/Data/Application/.../tmp/img_1.jpg",
  "file:///var/mobile/Containers/Data/Application/.../tmp/img_2.jpg"
]
```

---

## Android Implementation

This plugin uses the modern Android Photo Picker API.

Benefits:

- No storage permissions
- No media permissions
- Compliant with Android 13+
- Compatible with Google Play privacy requirements

No permissions are added to your AndroidManifest.xml.

---

## iOS Implementation

This plugin uses Apple's native `PHPickerViewController`.

Benefits:

- No photo library permission prompt
- No full library access
- User selects only the images they want to share
- Better privacy model

No `NSPhotoLibraryUsageDescription` entry is required.

Selected images are copied into the application's temporary directory and returned as `file://` URIs.

---

## Permission Requirements

### Android

None.

```xml
<!-- Not Required -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
```

### iOS

None.

```xml
<!-- Not Required -->
NSPhotoLibraryUsageDescription
```

## Compatibility

| Platform | Version |
|-----------|----------|
| cordova-android | 10+ |
| cordova-ios | 6+ |
| Android | 11+ |
| iOS | 14+ |

---

## License

MIT

---

## Author

**Rajat Temaniya**

GitHub:
https://github.com/rajatTemaniya

LinkedIn:
https://www.linkedin.com/in/rajat-temaniya-3b9524112/

---

## Contributing

Issues and pull requests are welcome.

If you find platform-specific issues or compatibility problems, please open an issue on GitHub.

---

## Motivation

This plugin was created after encountering Google Play warnings related to legacy storage and media permissions used by traditional image picker plugins.

The goal was simple:

> Allow users to pick images using the platform's modern native picker APIs without requesting broad photo or storage access.

By relying on Android Photo Picker and iOS PHPicker, applications can remain compliant with modern privacy expectations while providing a seamless image selection experience.