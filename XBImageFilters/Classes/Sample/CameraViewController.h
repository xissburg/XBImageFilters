//
//  CameraViewController.h
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBFilteredCameraView.h"

@interface CameraViewController : UIViewController

@property (weak, nonatomic) IBOutlet XBFilteredCameraView *cameraView;

- (IBAction)takeAPictureButtonTouchUpInside:(id)sender;
- (IBAction)changeFilterButtonTouchUpInside:(id)sender;
- (IBAction)flashLightButtonTouchUpInside:(id)sender;
@end
