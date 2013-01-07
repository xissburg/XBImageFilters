//
//  ImageViewController.m
//  XBImageFilters
//
//  Created by xiss burg on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageViewController.h"

@implementation ImageViewController
@synthesize imageView;
@synthesize filteredImageView;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.filteredImageView.image = self.imageView.image;
    self.filteredImageView.contentMode = UIViewContentModeBottom;
    
    NSString *hBlurVSPath = [[NSBundle mainBundle] pathForResource:@"HBlurVertexShader" ofType:@"glsl"];
    NSString *vBlurVSPath = [[NSBundle mainBundle] pathForResource:@"VBlurVertexShader" ofType:@"glsl"];
    NSString *blurFSPath = [[NSBundle mainBundle] pathForResource:@"BlurFragmentShader" ofType:@"glsl"];
    NSArray *vsPaths = [[NSArray alloc] initWithObjects:vBlurVSPath, hBlurVSPath, nil];
    NSArray *fsPaths = [[NSArray alloc] initWithObjects:blurFSPath, blurFSPath, nil];
    NSError *error = nil;
    if (![self.filteredImageView setFilterFragmentShaderPaths:fsPaths vertexShaderPaths:vsPaths error:&error]) {
        NSLog(@"%@", [error localizedDescription]);
    }
}

- (void)viewDidUnload
{
    [self setImageView:nil];
    [self setFilteredImageView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

@end
