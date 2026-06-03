#import <Cordova/CDV.h>
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
@import UniformTypeIdentifiers;

@interface PermissionlessMultiImagePicker : CDVPlugin <PHPickerViewControllerDelegate>
- (void)pickImages:(CDVInvokedUrlCommand*)command;
@property (copy)   NSString*       callbackId;
@property (strong) NSMutableArray* collectedPaths;
@property (assign) NSInteger       expectedCount;
@end

@implementation PermissionlessMultiImagePicker

- (void)pickImages:(CDVInvokedUrlCommand*)command {
    self.callbackId = command.callbackId;

    NSInteger maxImages = 0;
    if (command.arguments.count > 0 && command.arguments[0] != [NSNull null]) {
        maxImages = [command.arguments[0] integerValue];
    }

    PHPickerConfiguration *config = [[PHPickerConfiguration alloc] init];
    config.filter         = [PHPickerFilter imagesFilter];
    config.selectionLimit = maxImages;

    self.collectedPaths = [NSMutableArray new];
    self.expectedCount  = 0;

    PHPickerViewController *picker =
        [[PHPickerViewController alloc] initWithConfiguration:config];
    picker.delegate = self;
    [self.viewController presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker
didFinishPicking:(NSArray<PHPickerResult *> *)results {

    [picker dismissViewControllerAnimated:YES completion:nil];

    if (results.count == 0) {
        CDVPluginResult *result = [CDVPluginResult
            resultWithStatus:CDVCommandStatus_ERROR
            messageAsString:@"cancelled"];
        [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
        return;
    }

    self.expectedCount  = results.count;
    self.collectedPaths = [NSMutableArray new];

    for (PHPickerResult *pickerResult in results) {
        // loadFileRepresentationForContentType gives a direct file URL
        // no type checking needed, works iOS 16+
        if (@available(iOS 16.0, *)) {
            [pickerResult.itemProvider
                loadFileRepresentationForContentType:UTTypeImage
                openInPlace:NO
                completionHandler:^(NSURL *url, BOOL openedInPlace, NSError *error) {
                    NSString *filePath = nil;
                    if (url && !error) {
                        filePath = [self copyURLToTemp:url];
                    }
                    [self handleCollectedPath:filePath];
                }];
        } else {
            // Fallback for iOS 14-15
            [pickerResult.itemProvider
                loadItemForTypeIdentifier:UTTypeImage.identifier
                options:nil
                completionHandler:^(id<NSSecureCoding> item, NSError *error) {
                    NSString *filePath = nil;
                    id obj = (id)item;
                    if ([obj isKindOfClass:[NSURL class]]) {
                        filePath = [self copyURLToTemp:(NSURL *)obj];
                    } else if ([obj isKindOfClass:[UIImage class]]) {
                        filePath = [self writeImageToTemp:(UIImage *)obj];
                    }
                    [self handleCollectedPath:filePath];
                }];
        }
    }
}

- (void)handleCollectedPath:(NSString *)filePath {
    @synchronized(self.collectedPaths) {
        if (filePath) {
            [self.collectedPaths addObject:filePath];
        } else {
            self.expectedCount--;
        }

        if ((NSInteger)self.collectedPaths.count == self.expectedCount) {
            CDVPluginResult *result = [CDVPluginResult
                resultWithStatus:CDVCommandStatus_OK
                messageAsArray:self.collectedPaths];
            [self.commandDelegate sendPluginResult:result
                                       callbackId:self.callbackId];
        }
    }
}

- (NSString *)copyURLToTemp:(NSURL *)sourceURL {
    NSString *tmpDir  = NSTemporaryDirectory();
    NSString *ext     = sourceURL.pathExtension.length > 0
                            ? sourceURL.pathExtension : @"jpg";
    NSString *fileName = [NSString stringWithFormat:@"img_%lld_%@.%@",
                          (long long)([[NSDate date] timeIntervalSince1970] * 1000),
                          [[NSUUID UUID] UUIDString], ext];
    NSString *destPath = [tmpDir stringByAppendingPathComponent:fileName];

    NSError *copyError = nil;
    [[NSFileManager defaultManager] copyItemAtPath:sourceURL.path
                                            toPath:destPath
                                             error:&copyError];
    if (copyError) return nil;
    return [@"file://" stringByAppendingString:destPath];
}

- (NSString *)writeImageToTemp:(UIImage *)image {
    NSString *tmpDir   = NSTemporaryDirectory();
    NSString *fileName = [NSString stringWithFormat:@"img_%lld_%@.jpg",
                          (long long)([[NSDate date] timeIntervalSince1970] * 1000),
                          [[NSUUID UUID] UUIDString]];
    NSString *destPath = [tmpDir stringByAppendingPathComponent:fileName];

    NSData *jpegData = UIImageJPEGRepresentation(image, 0.9);
    if (!jpegData) return nil;
    [jpegData writeToFile:destPath atomically:YES];
    return [@"file://" stringByAppendingString:destPath];
}

@end