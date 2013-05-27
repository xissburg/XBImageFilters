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
    //self.videoView.contentMode = UIViewContentModeScaleAspectFit;
    
    NSString *hBlurVSPath = [[NSBundle mainBundle] pathForResource:@"HBlur" ofType:@"vsh"];
    NSString *vBlurVSPath = [[NSBundle mainBundle] pathForResource:@"VBlur" ofType:@"vsh"];
    NSString *blurFSPath = [[NSBundle mainBundle] pathForResource:@"Blur" ofType:@"fsh"];
    NSArray *vsPaths = [[NSArray alloc] initWithObjects:vBlurVSPath, hBlurVSPath, nil];
    NSArray *fsPaths = [[NSArray alloc] initWithObjects:blurFSPath, blurFSPath, nil];
    NSError *error = nil;
    if (![self.videoView setFilterFragmentShaderPaths:fsPaths vertexShaderPaths:vsPaths error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
    float blurRadius = 0.04;
    for (GLKProgram *p in self.videoView.programs) {
        [p setValue:&blurRadius forUniformNamed:@"u_radius"];
    }
    
    self.videoView.replay = YES;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://xissburg.com/wp-content/uploads/IMG_1844.MOV"]];
    [NSURLConnection sendAsynchronousRequest:request queue:NSOperationQueue.mainQueue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *videoPath = [[documentsPath stringByAppendingPathComponent:@"video"] stringByAppendingPathExtension:@"mov"];
        NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
        [data writeToURL:videoURL atomically:YES];
        
        self.videoView.videoURL = videoURL;
        [self.videoView play];
    }];
}

#pragma mark - Buttons

- (void)saveButtonTouchUpInside:(id)sender
{
    NSString *documentsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *videoPath = [documentsPath stringByAppendingPathComponent:@"FilteredView.mov"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:videoPath]) {
        NSError *error = nil;
        if (![[NSFileManager defaultManager] removeItemAtPath:videoPath error:&error]) {
            NSLog(@"Failed to delete video file: %@", error);
        }
    }
    
    NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
    NSError *error = nil;
    if (![self.videoView saveFilteredVideoToURL:videoURL error:&error completion:^{
        NSLog(@"Filtered video saved.");
    }]) {
        NSLog(@"Failed to save video: %@", error);
    }
}

@end
