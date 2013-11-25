//
//  VideoViewController.m
//  XBImageFilters
//
//  Created by xissburg on 5/19/13.
//
//

#import "VideoViewController.h"

@interface VideoViewController ()

@end

@implementation VideoViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    /*
    NSString *hBlurVSPath = [[NSBundle mainBundle] pathForResource:@"HBlur" ofType:@"vsh"];
    NSString *vBlurVSPath = [[NSBundle mainBundle] pathForResource:@"VBlur" ofType:@"vsh"];
    NSString *blurFSPath = [[NSBundle mainBundle] pathForResource:@"Blur" ofType:@"fsh"];
    NSArray *vsPaths = @[vBlurVSPath, hBlurVSPath];
    NSArray *fsPaths = @[blurFSPath, blurFSPath];
    NSError *error = nil;
    if (![self.videoView setFilterFragmentShaderPaths:fsPaths vertexShaderPaths:vsPaths error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    float blurRadius = 0.04;
    for (GLKProgram *p in self.videoView.programs) {
        [p setValue:&blurRadius forUniformNamed:@"u_radius"];
    }*/
    
    NSString *fsPath = [[NSBundle mainBundle] pathForResource:@"Luminance" ofType:@"fsh"];
    NSError *error = nil;
    if (![self.videoView setFilterFragmentShaderPath:fsPath error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    
    self.videoView.replay = YES;
    self.videoView.contentMode = UIViewContentModeScaleAspectFit;
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    //NSURL *requestURL = [NSURL URLWithString:@"http://xissburg.com/wp-content/uploads/IMG_2171.MOV"];
    NSURL *requestURL = [NSURL URLWithString:@"http://xissburg.com/wp-content/uploads/IMG_1844.MOV"];
    NSURLRequest *request = [NSURLRequest requestWithURL:requestURL];
    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] show];
        }
        else {
            NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
            NSString *videoPath = [documentsPath stringByAppendingPathComponent:requestURL.lastPathComponent];
            NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
            [data writeToURL:videoURL atomically:YES];
            
            self.videoView.videoURL = videoURL;
            [self.videoView play];
        }
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    }];
}

#pragma mark - Buttons

- (void)saveButtonTouchUpInside:(id)sender
{
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *videoPath = [documentsPath stringByAppendingPathComponent:@"FilteredVideo.mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:videoPath error:&error]) {
            NSLog(@"Failed to delete video file: %@", error);
        }
    }
    
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    [self.videoView saveFilteredVideoToURL:videoURL completion:^(BOOL success, NSError *error) {
        if (success) {
            NSLog(@"Filtered video saved.");
        }
        else {
            NSLog(@"Failed to save video: %@", error);
        }
    }];
}

@end
