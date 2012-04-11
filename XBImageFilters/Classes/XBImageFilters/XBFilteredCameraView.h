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
@property (assign, nonatomic) CGPoint focusPoint;
@property (assign, nonatomic) CGPoint exposurePoint;

- (void)startCapturing;
- (void)stopCapturing;

@end
