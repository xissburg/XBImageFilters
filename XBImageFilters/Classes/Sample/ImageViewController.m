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
    
    // NSString *luminancePath = [[NSBundle mainBundle] pathForResource:@"LuminanceFragmentShader" ofType:@"glsl"];
    NSString *hBlurPath = [[NSBundle mainBundle] pathForResource:@"HGaussianBlur" ofType:@"glsl"];
    NSString *vBlurPath = [[NSBundle mainBundle] pathForResource:@"VGaussianBlur" ofType:@"glsl"];
    NSArray *paths = [[NSArray alloc] initWithObjects:vBlurPath, hBlurPath, nil];
    [self.filteredImageView setFilterFragmentShadersFromFiles:paths error:NULL];
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
