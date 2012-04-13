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
@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput;
@property (strong, nonatomic) AVCaptureStillImageOutput *stillImageOutput;
@property (assign, nonatomic) size_t videoWidth, videoHeight;

- (void)setupOutputs;

@end

@implementation XBFilteredCameraView

@synthesize captureSession = _captureSession;
@synthesize device = _device;
@synthesize input = _input;
@synthesize videoDataOutput = _videoDataOutput;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize videoWidth = _videoWidth, videoHeight = _videoHeight;
@synthesize delegate = _delegate;
@synthesize cameraPosition = _cameraPosition;

- (void)_XBFilteredCameraViewInit
{
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.contentTransform = GLKMatrix4Multiply(GLKMatrix4MakeScale(-1, 1, 1), GLKMatrix4MakeRotation(-M_PI_2, 0, 0, 1)); // Compensate for weird camera rotation
    
    self.videoHeight = self.videoWidth = 0;
    
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
    
    // Use the rear camera by default
    self.cameraPosition = XBCameraPositionBack;
    
    [self setupOutputs];
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

- (void)dealloc
{
    [self stopCapturing];
    [self removeObservers];
}

#pragma - Properties

- (void)setCameraPosition:(XBCameraPosition)cameraPosition
{
    // Attempt to obtain the requested device. If not found, the state of this object is not changed and a warning is printed.
    AVCaptureDevice *newDevice = nil;
    NSArray *devices = [AVCaptureDevice devices];
    for (AVCaptureDevice *device in devices) {
        if ([device hasMediaType:AVMediaTypeVideo] && 
            ((device.position == AVCaptureDevicePositionBack && cameraPosition == XBCameraPositionBack) || 
             (device.position == AVCaptureDevicePositionFront && cameraPosition == XBCameraPositionFront))) {
            newDevice = device;
            break;
        }
    }

    if (newDevice == nil) {
        NSLog(@"XBFilteredCameraView: Failed to set camera position. No device found in the %@.", cameraPosition == XBCameraPositionFront? @"front": (cameraPosition == XBCameraPositionBack? @"back": @"unknown position"));
        return;
    }
    
    _cameraPosition = cameraPosition;
    self.device = newDevice;
    
    [self.captureSession beginConfiguration];
    [self.captureSession removeInput:self.input];
    
    NSError *error = nil;    
    self.input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:&error];
    
    if (self.input) {
        [self.captureSession addInput:self.input];
    }
    else {
        NSLog(@"XBFilteredCameraView: Failed to create device input: %@", [error localizedDescription]);
    }
    
    [self.captureSession commitConfiguration];
}

- (void)setDevice:(AVCaptureDevice *)device
{
    [self removeObservers];
    _device = device;
    [self.device addObserver:self forKeyPath:@"adjustingFocus" options:0 context:NULL];
    [self.device addObserver:self forKeyPath:@"adjustingExposure" options:0 context:NULL];
    [self.device addObserver:self forKeyPath:@"adjustingWhiteBalance" options:0 context:NULL];
}

- (CGPoint)focusPoint
{
    return CGPointMake(self.device.focusPointOfInterest.x*self.bounds.size.width, self.device.focusPointOfInterest.y*self.bounds.size.height);
}

- (void)setFocusPoint:(CGPoint)focusPoint
{
    NSError *error = nil;
    if (![self.device lockForConfiguration:&error]) {
        NSLog(@"XBFilteredCameraView: Failed to set focus point: %@", [error localizedDescription]);
        return;
    }
    
    self.device.focusPointOfInterest = CGPointMake(focusPoint.x/self.bounds.size.width, focusPoint.y/self.bounds.size.height);
    self.device.focusMode = AVCaptureFocusModeAutoFocus;
    self.device.focusMode = AVCaptureFocusModeContinuousAutoFocus;
    [self.device unlockForConfiguration];
}

- (CGPoint)exposurePoint
{
    return CGPointMake(self.device.exposurePointOfInterest.x*self.bounds.size.width, self.device.exposurePointOfInterest.y*self.bounds.size.height);
}

- (void)setExposurePoint:(CGPoint)exposurePoint
{
    NSError *error = nil;
    if (![self.device lockForConfiguration:&error]) {
        NSLog(@"XBFilteredCameraView: Failed to set exposure point: %@", [error localizedDescription]);
        return;
    }
    
    self.device.exposurePointOfInterest = CGPointMake(exposurePoint.x/self.bounds.size.width, exposurePoint.y/self.bounds.size.height);
    self.device.exposureMode = AVCaptureExposureModeAutoExpose;
    [self.device unlockForConfiguration];
}

#pragma mark - Methods

- (void)startCapturing
{
    [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [self.captureSession startRunning];
}

- (void)stopCapturing
{
    [self.videoDataOutput setSampleBufferDelegate:nil queue:NULL];
    [self.captureSession stopRunning];
}

#pragma mark - Private Methods

- (void)setupOutputs
{
    [self.captureSession beginConfiguration];
    
    [self.captureSession removeOutput:self.videoDataOutput];
    [self.captureSession removeOutput:self.stillImageOutput];
    
    self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    self.videoDataOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
    [self.videoDataOutput setSampleBufferDelegate:self queue:dispatch_get_main_queue()];
    [self.captureSession addOutput:self.videoDataOutput];
    
    self.stillImageOutput = [[AVCaptureStillImageOutput alloc] init];
    self.stillImageOutput.outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG, AVVideoCodecKey, [NSNumber numberWithInt:kCVPixelFormatType_32BGRA], kCVPixelBufferPixelFormatTypeKey, nil];
    [self.captureSession addOutput:self.stillImageOutput];

    [self.captureSession commitConfiguration];
}

- (void)removeObservers
{
    [self.device removeObserver:self forKeyPath:@"adjustingFocus"];
    [self.device removeObserver:self forKeyPath:@"adjustingExposure"];
    [self.device removeObserver:self forKeyPath:@"adjustingWhiteBalance"];
}

#pragma mark - Key-Value Observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object == self.device) {
        if ([keyPath isEqualToString:@"adjustingFocus"]) {
            if (self.device.adjustingFocus && [self.delegate respondsToSelector:@selector(filteredCameraViewDidBeginAdjustingFocus:)]) {
                [self.delegate filteredCameraViewDidBeginAdjustingFocus:self];
            }
            else if (!self.device.adjustingFocus && [self.delegate respondsToSelector:@selector(filteredCameraViewDidFinishAdjustingFocus:)]) {
                [self.delegate filteredCameraViewDidFinishAdjustingFocus:self];
            }
        }
        else if ([keyPath isEqualToString:@"adjustingExposure"]) {
            if (self.device.adjustingExposure && [self.delegate respondsToSelector:@selector(filteredCameraViewDidBeginAdjustingExposure:)]) {
                [self.delegate filteredCameraViewDidBeginAdjustingExposure:self];
            }
            else if (!self.device.adjustingExposure && [self.delegate respondsToSelector:@selector(filteredCameraViewDidFinishAdjustingExposure:)]) {
                [self.delegate filteredCameraViewDidFinishAdjustingExposure:self];
            }
        }
        else if ([keyPath isEqualToString:@"adjustingWhiteBalance"]) {
            if (self.device.adjustingWhiteBalance && [self.delegate respondsToSelector:@selector(filteredCameraViewDidBeginAdjustingWhiteBalance:)]) {
                [self.delegate filteredCameraViewDidBeginAdjustingWhiteBalance:self];
            }
            else if (!self.device.adjustingWhiteBalance && [self.delegate respondsToSelector:@selector(filteredCameraViewDidFinishAdjustingWhiteBalance:)]) {
                [self.delegate filteredCameraViewDidFinishAdjustingWhiteBalance:self];
            }
        }
        else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
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
