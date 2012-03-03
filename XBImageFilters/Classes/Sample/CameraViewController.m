//
//  CameraViewController.m
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()

@end

@implementation CameraViewController
@synthesize cameraView;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *luminancePath = [[NSBundle mainBundle] pathForResource:@"LuminanceFragmentShader" ofType:@"glsl"];
    NSString *hBlurPath = [[NSBundle mainBundle] pathForResource:@"HGaussianBlur" ofType:@"glsl"];
    NSString *vBlurPath = [[NSBundle mainBundle] pathForResource:@"VGaussianBlur" ofType:@"glsl"];
    NSArray *paths = [[NSArray alloc] initWithObjects:luminancePath, nil];
    [self.cameraView setFilterFragmentShadersFromFiles:paths error:nil];
    [self.cameraView startCapturing];
}

- (void)viewDidUnload
{
    [self setCameraView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Button Actions

- (IBAction)takeAPictureButtonTouchUpInside:(id)sender 
{
    UIImage *image = [self.cameraView takeScreenshot];
    [self.cameraView stopCapturing];
    
    UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
    [self.view addSubview:imageView];
    imageView.frame = CGRectMake(self.view.frame.size.width/2 - image.size.width/2, self.view.frame.size.height/2 - image.size.height/2, image.size.width, image.size.height);
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width, 40)];
    label.textAlignment = UITextAlignmentCenter;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:18];
    label.text = @"This is an UIImageView";
    [imageView addSubview:label];
    
    imageView.layer.shadowRadius = 10;
    imageView.layer.shadowColor = [UIColor blackColor].CGColor;
    imageView.layer.shadowOpacity = 0.6;
    imageView.layer.shadowOffset = CGSizeMake(0, 3);
    imageView.layer.shadowPath = CGPathCreateWithRect(imageView.bounds, &CGAffineTransformIdentity);
    
    imageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
    imageView.alpha = 0.5;
    
    [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
        imageView.transform = CGAffineTransformMakeScale(0.75, 0.75);
        imageView.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:2 options:0 animations:^{
            imageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
            imageView.alpha = 0;
        } completion:^(BOOL finished) {
            [imageView removeFromSuperview];
            [self.cameraView startCapturing];
        }];
    }];
}

@end
