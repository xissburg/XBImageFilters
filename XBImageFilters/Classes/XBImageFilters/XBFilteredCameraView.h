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

@interface XBFilteredCameraView : XBFilteredView <AVCaptureVideoDataOutputSampleBufferDelegate>

- (void)startCapturing;
- (void)stopCapturing;

@end
