//
//  XBFilteredCameraView.h
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "XBFilteredView.h"

typedef enum {
    XBCameraPositionBack = 1,
    XBCameraPositionFront = 2
} XBCameraPosition;

extern NSString *const XBCaptureQualityPhoto;
extern NSString *const XBCaptureQualityHigh;
extern NSString *const XBCaptureQualityMedium;
extern NSString *const XBCaptureQualityLow;
extern NSString *const XBCaptureQuality1280x720;
extern NSString *const XBCaptureQualityiFrame1280x720;
extern NSString *const XBCaptureQualityiFrame960x540;
extern NSString *const XBCaptureQuality640x480;
extern NSString *const XBCaptureQuality352x288;

@class XBFilteredCameraView;

@protocol XBFilteredCameraViewDelegate <NSObject>

@optional
- (void)filteredCameraViewDidBeginAdjustingFocus:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidFinishAdjustingFocus:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidBeginAdjustingExposure:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidFinishAdjustingExposure:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidBeginAdjustingWhiteBalance:(XBFilteredCameraView *)filteredCameraView;
- (void)filteredCameraViewDidFinishAdjustingWhiteBalance:(XBFilteredCameraView *)filteredCameraView;

@end

@interface XBFilteredCameraView : XBFilteredView <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (weak, nonatomic) IBOutlet id<XBFilteredCameraViewDelegate> delegate;
@property (assign, nonatomic) XBCameraPosition cameraPosition;
@property (assign, nonatomic) CGPoint focusPoint; // Only supported if cameraPosition is XBCameraPositionBack
@property (assign, nonatomic) CGPoint exposurePoint;

/*
 * Starts/stops capturing and rendering the camera image with filters applied in realtime.
 */
- (void)startCapturing;
- (void)stopCapturing;

- (void)takeAPhotoWithCompletion:(void (^)(UIImage *image))completion;

@end
