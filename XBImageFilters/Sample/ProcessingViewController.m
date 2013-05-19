//
//  ProcessingViewController.m
//  XBImageFilters
//
//  Created by Dirk-Willem van Gulik on 28-03-12.
//  Copyright (c) 2012 webWeaving.org. All rights reserved.
//

#import "ProcessingViewController.h"
#import "UIImage+XBImageFilters.h"

@interface ProcessingViewController ()

@end

@implementation ProcessingViewController
@synthesize ctrl, imageView;

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    images = [NSDictionary dictionaryWithObjectsAndKeys:
              @"http://mascot.crystalxp.net/png/fagoon-marvin-4622.png", @"Marvin over the wire",
              @"marvin.png", @"Marvin Local",
              @"basn0g01.png",@"black & white",
              @"basn0g02.png",@"2 bit (4 level) grayscale",
              @"basn0g04.png",@"4 bit (16 level) grayscale",
              @"basn0g08.png",@"8 bit (256 level) grayscale",
              @"basn0g16.png",@"16 bit (64k level) grayscale",
              @"basn2c08.png",@"3x8 bits rgb color",
              @"basn2c16.png",@"3x16 bits rgb color",
              @"basn3p01.png",@"1 bit (2 color) paletted",
              @"basn3p02.png",@"2 bit (4 color) paletted",
              @"basn3p04.png",@"4 bit (16 color) paletted",
              @"basn3p08.png",@"8 bit (256 color) paletted",
              @"basn4a08.png",@"8 bit grayscale + 8 bit alpha",
              @"basn4a16.png",@"16 bit grayscale + 16 bit alpha",
              @"basn6a08.png",@"3x8 bits rgb color + 8 bit alpha",
              @"basn6a16.png",@"3x16 bits rgb color + 16 bit alpha",
              @"russian-ball.jpeg",@"Russian ball",
              nil];
    
    labels = [[images allKeys] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];

    [ctrl selectRow:0 inComponent:0 animated:NO];
    [self pickerView:ctrl didSelectRow:0 inComponent:0];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UIPickerViewDataSource

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView 
{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component 
{
    return [labels count];
}

#pragma mark - UIPickerViewDelegate

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component 
{
    return [labels objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // We first assume it is a local image - and then try to fetch it as a
    // URL if it looks like one.
    //
    NSString *fileName = [images objectForKey:[labels objectAtIndex:row]];
    UIImage * img =[UIImage imageNamed:fileName];
    if (img == nil) {
        NSURL * url = [NSURL URLWithString:fileName];
        NSData * incomingData = [NSData dataWithContentsOfURL:url];
        if (incomingData)
            img =[UIImage imageWithData:incomingData];
    }
    
    if (img == nil) {
        NSLog(@"Loading %@ gone awol.", fileName);
        return;
    }
 
    NSString *luminancePath = [[NSBundle mainBundle] pathForResource:@"Luminance" ofType:@"fsh"];
    NSArray *shaders = [[NSArray alloc] initWithObjects:luminancePath, nil];

#if 0
    imageView.image = [img imageByApplyingShaders:shaders];
#else
    UIImage * newImg =  [img imageByApplyingShaders:shaders];
    
    // We're using UIImageJPEGRepresentation rather than UIImagePNGRepresentation here
    // as the latter will not honour our orientation. (radar bug #11137002. JPEG
    // does though.
    //
    NSData * data = UIImageJPEGRepresentation(newImg,1.0);
    imageView.image = [UIImage imageWithData:data];
#endif
}

@end
