//
//  VideoViewController.h
//  XBImageFilters
//
//  Created by xissburg on 5/19/13.
//
//

#import <UIKit/UIKit.h>
#import "XBFilteredVideoView.h"

@interface VideoViewController : UIViewController

@property (nonatomic, weak) IBOutlet XBFilteredVideoView *videoView;

- (IBAction)saveButtonTouchUpInside:(id)sender;

@end
