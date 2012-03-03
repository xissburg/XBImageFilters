//
//  XBFilteredCameraView.m
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBFilteredCameraView.h"

@interface XBFilteredCameraView ()

@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (assign, nonatomic) size_t videoWidth, videoHeight;

@end

@implementation XBFilteredCameraView

@synthesize captureSession = _captureSession;
@synthesize videoWidth = _videoWidth, videoHeight = _videoHeight;

- (void)_XBFilteredCameraViewInit
{
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.contentTransform = GLKMatrix4Multiply(GLKMatrix4MakeScale(-1, 1, 1), GLKMatrix4MakeRotation(-M_PI_2, 0, 0, 1)); // Compensate for weird camera rotation
    
    self.videoHeight = self.videoWidth = 0;
    
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    [self.captureSession beginConfiguration];
    
    NSError *error = nil;
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    
    if (!input) {
        NSLog(@"Failed to create device input: %@", [error localizedDescription]);
    }
    
    [self.captureSession addInput:input];
    
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureSession addOutput:output];
    output.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [output setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    
    [self.captureSession commitConfiguration];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _XBFilteredCameraViewInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _XBFilteredCameraViewInit];
}

#pragma mark - Methods

- (void)startCapturing
{
    [self.captureSession startRunning];
}

- (void)stopCapturing
{
    [self.captureSession stopRunning];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    if (width != self.videoWidth || height != self.videoHeight) {
        self.videoWidth = width;
        self.videoHeight = height;
        self.contentSize = CGSizeMake(height, width);
        [self _setTextureData:baseAddress width:self.videoWidth height:self.videoHeight];
    }
    else {
        [self _updateTextureWithData:baseAddress];
    }
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

@end
