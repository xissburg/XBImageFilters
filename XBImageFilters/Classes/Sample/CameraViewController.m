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
    //NSString *hBlurPath = [[NSBundle mainBundle] pathForResource:@"HGaussianBlur" ofType:@"glsl"];
    //NSString *vBlurPath = [[NSBundle mainBundle] pathForResource:@"VGaussianBlur" ofType:@"glsl"];
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
    return YES;
}

@end
