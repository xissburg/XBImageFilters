//
//  CameraViewController.m
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "CameraViewController.h"
#import <QuartzCore/QuartzCore.h>

#define kVSPathsKey @"vsPaths"
#define kFSPathsKey @"fsPaths"

@interface CameraViewController ()

@property (nonatomic, copy) NSArray *filterPathArray;
@property (nonatomic, copy) NSArray *filterNameArray;
@property (nonatomic, assign) NSUInteger filterIndex;

@end

@implementation CameraViewController

@synthesize cameraView = _cameraView;
@synthesize cameraTargetView = _cameraTargetView;
@synthesize filterPathArray = _filterPathArray;
@synthesize filterNameArray = _filterNameArray;
@synthesize filterIndex = _filterIndex;
@synthesize filterLabel;
@synthesize secondsPerFrameLabel;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tgr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cameraViewTapAction:)];
    [self.cameraView addGestureRecognizer:tgr];
    [self.cameraTargetView hideAnimated:NO];
    self.cameraView.updateSecondsPerFrame = YES;
    
    [self setupFilterPaths];
    self.filterIndex = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.cameraView startCapturing];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [self.cameraView stopCapturing];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#pragma mark - Properties

- (void)setFilterIndex:(NSUInteger)filterIndex
{
    _filterIndex = filterIndex;
    
    self.filterLabel.text = [self.filterNameArray objectAtIndex:self.filterIndex];
    
    NSDictionary *paths = [self.filterPathArray objectAtIndex:self.filterIndex];
    NSArray *fsPaths = [paths objectForKey:kFSPathsKey];
    NSArray *vsPaths = [paths objectForKey:kVSPathsKey];
    NSError *error = nil;
    if (vsPaths != nil) {
        [self.cameraView setFilterFragmentShaderPaths:fsPaths vertexShaderPaths:vsPaths error:&error];
    }
    else {
        [self.cameraView setFilterFragmentShaderPaths:fsPaths error:&error];
    }
    
    if (error != nil) {
        NSLog(@"Error setting shader: %@", [error localizedDescription]);
    }
    
    // Perform a few filter-specific initialization steps, like setting additional textures and uniforms
    NSString *filterName = [self.filterNameArray objectAtIndex:self.filterIndex];
    if ([filterName isEqualToString:@"Overlay"]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"LucasCorrea" ofType:@"png"];
        XBGLTexture *texture = [[XBGLTexture alloc] initWithContentsOfFile:path options:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], GLKTextureLoaderOriginBottomLeft, nil] error:NULL];
        XBGLProgram *program = [self.cameraView.programs objectAtIndex:0];
        [program bindSamplerNamed:@"s_overlay" toXBTexture:texture unit:1];
        [program setValue:(void *)&GLKMatrix2Identity forUniformNamed:@"u_rawTexCoordTransform"];
    }
    else if ([filterName isEqualToString:@"Sharpen"]) {
        GLKMatrix2 rawTexCoordTransform = (GLKMatrix2){self.cameraView.cameraPosition == XBCameraPositionBack? 1: -1, 0, 0, -0.976};
        XBGLProgram *program = [self.cameraView.programs objectAtIndex:1];
        [program bindSamplerNamed:@"s_mainTexture" toTexture:self.cameraView.mainTexture unit:1];
        [program setValue:(void *)&rawTexCoordTransform forUniformNamed:@"u_rawTexCoordTransform"];
    }
}

#pragma mark - Methods

- (void)setupFilterPaths
{
    NSString *defaultVSPath = [[NSBundle mainBundle] pathForResource:@"DefaultVertexShader" ofType:@"glsl"];
    NSString *defaultFSPath = [[NSBundle mainBundle] pathForResource:@"DefaultFragmentShader" ofType:@"glsl"];
    NSString *overlayFSPath = [[NSBundle mainBundle] pathForResource:@"OverlayFragmentShader" ofType:@"glsl"];
    NSString *overlayVSPath = [[NSBundle mainBundle] pathForResource:@"OverlayVertexShader" ofType:@"glsl"];
    NSString *luminancePath = [[NSBundle mainBundle] pathForResource:@"LuminanceFragmentShader" ofType:@"glsl"];
    NSString *blurFSPath = [[NSBundle mainBundle] pathForResource:@"BlurFragmentShader" ofType:@"glsl"];
    NSString *sharpFSPath = [[NSBundle mainBundle] pathForResource:@"UnsharpMaskFragmentShader" ofType:@"glsl"];
    NSString *hBlurVSPath = [[NSBundle mainBundle] pathForResource:@"HBlurVertexShader" ofType:@"glsl"];
    NSString *vBlurVSPath = [[NSBundle mainBundle] pathForResource:@"VBlurVertexShader" ofType:@"glsl"];
    NSString *discretizePath = [[NSBundle mainBundle] pathForResource:@"DiscretizeShader" ofType:@"glsl"];
    NSString *pixelatePath = [[NSBundle mainBundle] pathForResource:@"PixelateShader" ofType:@"glsl"];
    NSString *suckPath = [[NSBundle mainBundle] pathForResource:@"SuckShader" ofType:@"glsl"];
    
    // Setup a combination of these filters
    self.filterPathArray = [[NSArray alloc] initWithObjects:
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:defaultFSPath], kFSPathsKey, nil], // No Filter
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:overlayFSPath], kFSPathsKey, [NSArray arrayWithObject:overlayVSPath], kVSPathsKey, nil], // Overlay
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:suckPath], kFSPathsKey, nil], // Spread
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:pixelatePath], kFSPathsKey, nil], // Pixelate
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:discretizePath], kFSPathsKey, nil], // Discretize
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:luminancePath], kFSPathsKey, nil], // Luminance
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:blurFSPath], kFSPathsKey, [NSArray arrayWithObject:hBlurVSPath], kVSPathsKey,nil], // Horizontal Blur
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObject:blurFSPath], kFSPathsKey, [NSArray arrayWithObject:vBlurVSPath], kVSPathsKey,nil], // Vertical Blur
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:blurFSPath, blurFSPath, nil], kFSPathsKey, [NSArray arrayWithObjects:vBlurVSPath, hBlurVSPath, nil], kVSPathsKey, nil], // Blur
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:luminancePath, blurFSPath, blurFSPath, nil], kFSPathsKey, [NSArray arrayWithObjects:defaultVSPath, vBlurVSPath, hBlurVSPath, nil], kVSPathsKey, nil], // Blur B&W
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:blurFSPath, sharpFSPath, nil], kFSPathsKey, [NSArray arrayWithObjects:vBlurVSPath, hBlurVSPath, nil], kVSPathsKey, nil], // Sharpen
             [NSDictionary dictionaryWithObjectsAndKeys:[NSArray arrayWithObjects:blurFSPath, blurFSPath, discretizePath, nil], kFSPathsKey, [NSArray arrayWithObjects:vBlurVSPath, hBlurVSPath, defaultVSPath, nil], kVSPathsKey, nil], nil]; // Discrete Blur
    
    self.filterNameArray = [[NSArray alloc] initWithObjects:@"No Filter", @"Overlay", @"Spread", @"Pixelate", @"Discretize", @"Luminance", @"Horizontal Blur", @"Vertical Blur", @"Blur", @"Blur B&W", @"Sharpen", @"Discrete Blur", nil];
}

#pragma mark - Button Actions

- (IBAction)takeAPictureButtonTouchUpInside:(UIButton *)sender
{
    sender.enabled = NO;
    
    // Perform filter specific setup before taking the photo
    NSString *filterName = [self.filterNameArray objectAtIndex:self.filterIndex];
    if ([filterName isEqualToString:@"Overlay"]) {
        GLKMatrix2 rawTexCoordTransform = self.cameraView.rawTexCoordTransform;
        XBGLProgram *program = [self.cameraView.programs objectAtIndex:0];
        [program setValue:(void *)&rawTexCoordTransform forUniformNamed:@"u_rawTexCoordTransform"];
    }
    else if ([filterName isEqualToString:@"Sharpen"]) {
        GLKMatrix2 rawTexCoordTransform = GLKMatrix2Multiply(self.cameraView.rawTexCoordTransform, (GLKMatrix2){self.cameraView.cameraPosition == XBCameraPositionBack? 1: -1, 0, 0, -1});
        XBGLProgram *program = [self.cameraView.programs objectAtIndex:1];
        [program setValue:(void *)&rawTexCoordTransform forUniformNamed:@"u_rawTexCoordTransform"];
    }
    
    [self.cameraView takeAPhotoWithCompletion:^(UIImage *image) {
        UIImageView *imageView = [[UIImageView alloc] initWithImage:image];
        [self.view addSubview:imageView];
        imageView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        imageView.contentMode = UIViewContentModeScaleAspectFit;
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
        
        // Restore filter-specific state
        NSString *filterName = [self.filterNameArray objectAtIndex:self.filterIndex];
        if ([filterName isEqualToString:@"Overlay"]) {
            XBGLProgram *program = [self.cameraView.programs objectAtIndex:0];
            [program setValue:(void *)&GLKMatrix2Identity forUniformNamed:@"u_rawTexCoordTransform"];
        }
        else if ([filterName isEqualToString:@"Sharpen"]) {
            GLKMatrix2 rawTexCoordTransform = (GLKMatrix2){self.cameraView.cameraPosition == XBCameraPositionBack? 1: -1, 0, 0, -0.976};
            XBGLProgram *program = [self.cameraView.programs objectAtIndex:1];
            [program setValue:(void *)&rawTexCoordTransform forUniformNamed:@"u_rawTexCoordTransform"];
        }
        
        sender.enabled = YES;
    }];
}

- (IBAction)changeFilterButtonTouchUpInside:(id)sender
{
    self.filterIndex = (self.filterIndex + 1) % self.filterPathArray.count;
}

- (IBAction)cameraButtonTouchUpInside:(id)sender 
{
    self.cameraView.cameraPosition = self.cameraView.cameraPosition == XBCameraPositionBack? XBCameraPositionFront: XBCameraPositionBack;
    
    // The Sharpen filter needs to update its rawTexCoordTransform because it displays the mainTexture itself (raw camera texture) which flips
    // when we swap between the front/back camera.
    if ([[self.filterNameArray objectAtIndex:self.filterIndex] isEqualToString:@"Sharpen"]) {
        GLKMatrix2 rawTexCoordTransform = (GLKMatrix2){self.cameraView.cameraPosition == XBCameraPositionBack? 1: -1, 0, 0, -0.976};
        XBGLProgram *program = [self.cameraView.programs objectAtIndex:1];
        [program setValue:(void *)&rawTexCoordTransform forUniformNamed:@"u_rawTexCoordTransform"];
    }
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

- (void)filteredView:(XBFilteredView *)filteredView didChangeMainTexture:(GLuint)mainTexture
{
    // The Sharpen filter uses the mainTexture (raw camera image) which might change names (because of the CVOpenGLESTextureCache), then we
    // need to update it whenever it changes.
    if ([[self.filterNameArray objectAtIndex:self.filterIndex] isEqualToString:@"Sharpen"]) {
        XBGLProgram *program = [self.cameraView.programs objectAtIndex:1];
        [program bindSamplerNamed:@"s_mainTexture" toTexture:self.cameraView.mainTexture unit:1];
    }
}

- (void)filteredCameraView:(XBFilteredCameraView *)filteredCameraView didUpdateSecondsPerFrame:(NSTimeInterval)secondsPerFrame
{
    self.secondsPerFrameLabel.text = [NSString stringWithFormat:@"spf: %.4f", secondsPerFrame];
}

@end
