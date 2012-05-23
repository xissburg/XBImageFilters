//
//  CameraViewController.m
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CameraViewController.h"

@interface CameraViewController ()
{
    NSArray *paths;
    int filterIndex;
}
@end

@implementation CameraViewController

@synthesize cameraView = _cameraView;
@synthesize cameraTargetView = _cameraTargetView;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    [self.cameraView addGestureRecognizer:tgr];
    
    [self.cameraTargetView hideAnimated:NO];
    
    [self loadFilters];
    filterIndex = 1;
    NSArray *files =  [paths objectAtIndex:0];

    NSError *error = nil;
    if (![self.cameraView setFilterFragmentShadersFromFiles:files error:&error]) {
        NSLog(@"Error setting shader: %@", [error localizedDescription]);
    }
    
    //self.cameraView.flashMode = XBFlashModeOn;
    [self.cameraView startCapturing];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Methods

- (void)loadFilters
{
    NSString *luminancePath = [[NSBundle mainBundle] pathForResource:@"LuminanceFragmentShader" ofType:@"glsl"];
    NSString *hBlurPath = [[NSBundle mainBundle] pathForResource:@"HGaussianBlur" ofType:@"glsl"];
    NSString *vBlurPath = [[NSBundle mainBundle] pathForResource:@"VGaussianBlur" ofType:@"glsl"];
    NSString *defaultPath = [[NSBundle mainBundle] pathForResource:@"DefaultFragmentShader" ofType:@"glsl"];
    NSString *discretizePath = [[NSBundle mainBundle] pathForResource:@"DiscretizeShader" ofType:@"glsl"];
    NSString *pixelatePath = [[NSBundle mainBundle] pathForResource:@"PixelateShader" ofType:@"glsl"];
    NSString *suckPath = [[NSBundle mainBundle] pathForResource:@"SuckShader" ofType:@"glsl"];
    
    // Setup a combination of these filters
    paths = [[NSArray alloc] initWithObjects:
             [[NSArray alloc] initWithObjects:defaultPath, nil],
             [[NSArray alloc] initWithObjects:suckPath, nil],
             [[NSArray alloc] initWithObjects:pixelatePath, nil],
             [[NSArray alloc] initWithObjects:discretizePath, nil],
             [[NSArray alloc] initWithObjects:luminancePath, nil], 
             [[NSArray alloc] initWithObjects:hBlurPath, nil],
             [[NSArray alloc] initWithObjects:vBlurPath, nil],
             [[NSArray alloc] initWithObjects:hBlurPath, vBlurPath, nil],
             [[NSArray alloc] initWithObjects:luminancePath, hBlurPath, vBlurPath, nil],
             [[NSArray alloc] initWithObjects:hBlurPath, vBlurPath, discretizePath, nil], nil];
}

#pragma mark - Button Actions

- (IBAction)takeAPictureButtonTouchUpInside:(id)sender 
{
    [self.cameraView takeAPhotoWithCompletion:^(UIImage *image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [self.view addSubview:imageView];
        imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, imageView.frame.size.width, 40)];
        label.textAlignment = UITextAlignmentCenter;
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [UIColor whiteColor];
        label.font = [UIFont systemFontOfSize:18];
        label.text = @"This is an UIImageView";
        [imageView addSubview:label];
        
        imageView.transform = CGAffineTransformMakeScale(0.01, 0.01);
        imageView.alpha = 0.5;
        
        [UIView animateWithDuration:0.3 delay:0 options:0 animations:^{
            imageView.transform = CGAffineTransformMakeScale(0.9, 0.9);
            imageView.alpha = 1;
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 delay:4 options:0 animations:^{
                imageView.transform = CGAffineTransformMakeScale(1.1, 1.1);
                imageView.alpha = 0;
            } completion:^(BOOL finished) {
                [imageView removeFromSuperview];
            }];
        }];
        
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
    }];
}

- (IBAction)changeFilterButtonTouchUpInside:(id)sender
{
    NSArray *files = [paths objectAtIndex:filterIndex];

    NSError *error = nil;
    if (![self.cameraView setFilterFragmentShadersFromFiles:files error:&error]) {
        NSLog(@"Error setting shader: %@", [error localizedDescription]);
    }
    
    filterIndex++;
    if (filterIndex > paths.count - 1) {
        filterIndex = 0;
    }
}

- (IBAction)cameraButtonTouchUpInside:(id)sender 
{
    self.cameraView.cameraPosition = self.cameraView.cameraPosition == XBCameraPositionBack? XBCameraPositionFront: XBCameraPositionBack;
}

#pragma mark - Gesture recognition

- (void)cameraViewTapAction:(UITapGestureRecognizer *)tgr
{
    if (tgr.state == UIGestureRecognizerStateRecognized) {
        CGPoint location = [tgr locationInView:self.cameraView];
        self.cameraView.focusPoint = location;
        self.cameraView.exposurePoint = location;
        
        if (self.cameraView.exposurePointSupported || self.cameraView.focusPointSupported) {
            self.cameraTargetView.center = self.cameraView.exposurePoint;
            [self.cameraTargetView showAnimated:YES];
        }
    }
}

#pragma mark - XBFilteredCameraViewDelegate

- (void)filteredCameraViewDidBeginAdjustingFocus:(XBFilteredCameraView *)filteredCameraView
{
    // NSLog(@"Focus point: %f, %f", self.cameraView.focusPoint.x, self.cameraView.focusPoint.y);
}

- (void)filteredCameraViewDidFinishAdjustingFocus:(XBFilteredCameraView *)filteredCameraView
{
    // NSLog(@"Focus point: %f, %f", self.cameraView.focusPoint.x, self.cameraView.focusPoint.y);
    [self.cameraTargetView hideAnimated:YES];
}

- (void)filteredCameraViewDidFinishAdjustingExposure:(XBFilteredCameraView *)filteredCameraView
{
    [self.cameraTargetView hideAnimated:YES];
}

@end
