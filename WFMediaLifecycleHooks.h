#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
FOUNDATION_EXPORT id<AVCapturePhotoCaptureDelegate> WFPhotoDelegateForCapture(
    AVCapturePhotoOutput *output, AVCapturePhotoSettings *settings, id<AVCapturePhotoCaptureDelegate> target);
FOUNDATION_EXPORT void WFTrackPhotoUploadTask(NSURLSessionUploadTask *task, NSData *body);
FOUNDATION_EXPORT void WFTrackPhotoFileUploadTask(NSURLSessionUploadTask *task, NSURL *file);
