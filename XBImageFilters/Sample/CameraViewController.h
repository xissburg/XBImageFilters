//
//  CameraViewController.h
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBFilteredCameraView.h"

@interface CameraViewController : UIViewController <XBFilteredCameraViewDelegate>

@property (weak, nonatomic) IBOutlet XBFilteredCameraView *cameraView;
@property (weak, nonatomic) IBOutlet UILabel *filterLabel;
@property (weak, nonatomic) IBOutlet UILabel *secondsPerFrameLabel;

- (IBAction)takeAPictureButtonTouchUpInside:(id)sender;
- (IBAction)changeFilterButtonTouchUpInside:(id)sender;
- (IBAction)cameraButtonTouchUpInside:(id)sender;

@end
