//
//  XBFilteredVideoView.m
//  XBImageFilters
//
//  Created by xissburg on 5/19/13.
//
//

#import "XBFilteredVideoView.h"
#import <AVFoundation/AVFoundation.h>
@import OpenGLES;

@interface XBFilteredVideoView ()

@property (nonatomic, strong) AVURLAsset *asset;
@property (nonatomic, strong) AVAssetReader *assetReader;
@property (nonatomic, strong) AVAssetReaderTrackOutput *videoTrackOutput;
@property (nonatomic, strong) AVAssetReaderTrackOutput *audioTrackOutput;
@property (assign, nonatomic) GLint videoWidth, videoHeight;
@property (assign, nonatomic) CVOpenGLESTextureCacheRef videoTextureCache;
@property (assign, nonatomic) CVOpenGLESTextureRef videoMainTexture;
@property (assign, nonatomic) BOOL playWhenReady;
@property (strong, nonatomic) dispatch_source_t timer;

@property (strong, nonatomic) AVAssetWriter *assetWriter;
@property (strong, nonatomic) AVAssetWriterInput *writerVideoInput;
@property (strong, nonatomic) AVAssetWriterInput *writerAudioInput;
@property (strong, nonatomic) AVAssetWriterInputPixelBufferAdaptor *writerPixelBufferAdaptor;

@end

@implementation XBFilteredVideoView

- (void)_XBFilteredVideoViewInit
{
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0
    CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &_videoTextureCache);
#else
    CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)self.context, NULL, &_videoTextureCache);
#endif
    if (ret != kCVReturnSuccess) {
        NSLog(@"Error at CVOpenGLESTextureCacheCreate: %d", ret);
    }
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self _XBFilteredVideoViewInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self _XBFilteredVideoViewInit];
}

- (void)dealloc
{
    [self stop];
}

- (void)setVideoURL:(NSURL *)videoURL
{
    [self setVideoURL:videoURL withCompletion:nil];
}

- (void)setVideoURL:(NSURL *)videoURL withCompletion:(void (^)(void))completion
{
    if (videoURL == _videoURL) {
        return;
    }
    _videoURL = [videoURL copy];
    
    self.asset = [AVURLAsset assetWithURL:videoURL];
    
    void (^block)(void) = ^{
        NSError *error = nil;
        if ([self.asset statusOfValueForKey:@"tracks" error:&error] != AVKeyValueStatusLoaded) {
            NSLog(@"Failed to load tracks: %@", error);
            return;
        }
        
        [self createAssetReader];
        
        if (self.playWhenReady) {
            [self play];
        }
        
        if (completion) {
            completion();
        }
    };
    
    NSError *error = nil;
    if ([self.asset statusOfValueForKey:@"tracks" error:&error] == AVKeyValueStatusLoaded) {
        block();
    }
    else {
        [self.asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler:^{
            dispatch_async(dispatch_get_main_queue(), block);
        }];
    }
}

- (void)createAssetReader
{
    NSError *error = nil;
    self.assetReader = [[AVAssetReader alloc] initWithAsset:self.asset error:&error];
    if (self.assetReader == nil) {
        NSLog(@"Failed to initialize AssetReader: %@", error);
        return;
    }
    
    AVAssetTrack *videoTrack = [self.asset tracksWithMediaType:AVMediaTypeVideo][0];
    id outputSettings = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
    self.videoTrackOutput = [[AVAssetReaderTrackOutput alloc] initWithTrack:videoTrack outputSettings:outputSettings];
    self.videoTrackOutput.alwaysCopiesSampleData = NO;
    self.videoWidth = videoTrack.naturalSize.width;
    self.videoHeight = videoTrack.naturalSize.height;
    self.contentSize = CGSizeMake(self.videoWidth, self.videoHeight);
    
    CGAffineTransform t = videoTrack.preferredTransform;
    GLKMatrix4 r = GLKMatrix4Make(t.a, t.b, 0, 0, t.c, t.d, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1);
    GLKMatrix4 s = GLKMatrix4MakeScale(1, -1, 1);
    self.contentTransform = GLKMatrix4Multiply(s, r);
    
    [self.assetReader addOutput:self.videoTrackOutput];
    
    NSArray *audioTracks = [self.asset tracksWithMediaType:AVMediaTypeAudio];
    if (audioTracks.count > 0) {
        self.audioTrackOutput = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:audioTracks[0] outputSettings:nil];
        [self.assetReader addOutput:self.audioTrackOutput];
    }
    else {
        self.audioTrackOutput = nil;
    }
    
    if (![self.assetReader startReading]) {
        NSLog(@"Failed to start reading from asset: %@", self.assetReader.error);
        return;
    }
}

- (void)play
{
    if (self.assetReader == nil) {
        [self createAssetReader];
    }
    
    if (self.assetReader.status != AVAssetReaderStatusReading) {
        self.playWhenReady = YES;
        return;
    }
    
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(self.timer, dispatch_time(DISPATCH_TIME_NOW, 0), (1/self.videoTrackOutput.track.nominalFrameRate) * 1e9, 1e8);
    dispatch_source_set_event_handler(self.timer, ^{
        [self draw];
    });
    dispatch_resume(self.timer);
    _playing = YES;
}

- (void)stop
{
    self.playWhenReady = NO;
    [self.assetReader cancelReading];
    self.assetReader = nil;
    if (self.timer != NULL) {
        self.timer = NULL;
    }
    _playing = NO;
}

- (void)cleanUpTextures
{
    if (self.videoMainTexture != NULL) {
        CFRelease(self.videoMainTexture);
        self.videoMainTexture = NULL;
    }
    
    CVOpenGLESTextureCacheFlush(self.videoTextureCache, 0);
}

- (void)draw
{
    if (self.assetReader.status == AVAssetReaderStatusReading) {
        CMSampleBufferRef sampleBuffer = [self.videoTrackOutput copyNextSampleBuffer];
        if (sampleBuffer) {
            [EAGLContext setCurrentContext:self.context];
            
            [self cleanUpTextures];
            CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
            // Compensate for padding. A small black line will be visible on the right. Also adjust the texture coordinate transform to fix this.
            GLint width = (GLint)CVPixelBufferGetWidth(imageBuffer);
            GLint height = (GLint)CVPixelBufferGetHeight(imageBuffer);
            
            if (width != self.videoWidth || height != self.videoHeight) {
                self.videoWidth = width;
                self.videoHeight = height;
                self.contentSize = CGSizeMake(width, height);
                float ratio = (float)CVPixelBufferGetWidth(imageBuffer)/width;
                self.texCoordTransform = (GLKMatrix2){ratio, 0, 0, 1}; // Apply a horizontal stretch to hide the row padding
            }
            
            [self _setTextureDataWithTextureCache:self.videoTextureCache texture:&_videoMainTexture imageBuffer:imageBuffer];
            [self display];
            
            CMSampleBufferInvalidate(sampleBuffer);
            CFRelease(sampleBuffer);
        }
        else {
            [self stop];
            
            if (self.replay) {
                [self createAssetReader];
                [self play];
            }
        }
    }
    else {
        [self stop];
        if (self.assetReader.status == AVAssetReaderStatusFailed) {
            NSLog(@"%@", self.assetReader.error);
        }
    }
}

- (void)saveFilteredVideoToURL:(NSURL *)URL completion:(void (^)(BOOL success, NSError *error))completion
{
    NSError *error = nil;
    self.assetWriter = [[AVAssetWriter alloc] initWithURL:URL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (self.assetWriter == nil) {
        if (completion) {
            completion(NO, error);
        }
        return;
    }
    
    self.assetWriter.movieFragmentInterval = CMTimeMakeWithSeconds(1.0, 1000);
    
    int numPixels = self.videoWidth * self.videoHeight;
    int bitsPerPixel = numPixels < 640 * 480? 4.05: 11.4;
    int bitsPerSecond = numPixels * bitsPerPixel;
    
    id compressionSettings = @{AVVideoAverageBitRateKey: @(bitsPerSecond), AVVideoMaxKeyFrameIntervalKey: @30};
    id videoOutputSettings = @{AVVideoCodecKey: AVVideoCodecH264, AVVideoWidthKey: @(self.videoWidth), AVVideoHeightKey: @(self.videoHeight), AVVideoCompressionPropertiesKey: compressionSettings};
    self.writerVideoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoOutputSettings];
    self.writerVideoInput.expectsMediaDataInRealTime = NO;
    self.writerVideoInput.transform = self.videoTrackOutput.track.preferredTransform;
    [self.assetWriter addInput:self.writerVideoInput];
    
    id pixelBufferAttributes = @{(__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA), (__bridge NSString *)kCVPixelBufferWidthKey: @(self.videoWidth), (__bridge NSString *)kCVPixelBufferHeightKey: @(self.videoHeight)};
    self.writerPixelBufferAdaptor = [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:self.writerVideoInput sourcePixelBufferAttributes:pixelBufferAttributes];
    
    if (self.audioTrackOutput != nil) {
        AudioChannelLayout audioChannelLayout;
        bzero(&audioChannelLayout, sizeof(audioChannelLayout));
        audioChannelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;
        self.writerAudioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:nil];
        self.writerAudioInput.expectsMediaDataInRealTime = NO;
        [self.assetWriter addInput:self.writerAudioInput];
    }
    else {
        self.writerAudioInput = nil;
    }
    
    if (![self.assetWriter startWriting]) {
        if (completion) {
            completion(NO, self.assetWriter.error);
        }
        return;
    }
    
    [self stop];
    [self createAssetReader];
    [self.assetWriter startSessionAtSourceTime:kCMTimeZero];
    
    CVOpenGLESTextureCacheRef textureCache;
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0
    CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, self.context, NULL, &textureCache);
#else
    CVReturn ret = CVOpenGLESTextureCacheCreate(kCFAllocatorDefault, NULL, (__bridge void *)self.context, NULL, &textureCache);
#endif
    if (ret != kCVReturnSuccess) {
        if (completion) {
            NSString *description = [NSString stringWithFormat:@"Error at CVOpenGLESTextureCacheCreate: %d", ret];
            completion(NO, [[NSError alloc] initWithDomain:@"XBImageFiltersDomain" code:ret userInfo:@{NSLocalizedDescriptionKey: description}]);
        }
        return;
    }
    
    CVPixelBufferRef pixelBuffer;
    CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, self.writerPixelBufferAdaptor.pixelBufferPool, &pixelBuffer);
    
    CVOpenGLESTextureRef textureTarget;
    CVOpenGLESTextureCacheCreateTextureFromImage(kCFAllocatorDefault, textureCache, pixelBuffer, NULL, GL_TEXTURE_2D, GL_RGBA, self.videoWidth, self.videoHeight, GL_BGRA, GL_UNSIGNED_BYTE, 0, &textureTarget);
    glBindTexture(GL_TEXTURE_2D, CVOpenGLESTextureGetName(textureTarget));
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, CVOpenGLESTextureGetName(textureTarget), 0);
    
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        if (completion) {
            NSString *description = [NSString stringWithFormat:@"Failed to create framebuffer: %x", status];
            completion(NO, [[NSError alloc] initWithDomain:@"XBImageFiltersDomain" code:ret userInfo:@{NSLocalizedDescriptionKey: description}]);
        }
        return;
    }
    
    GLKMatrix4 previousContentTransform = self.contentTransform;
    UIViewContentMode previousContentMode = self.contentMode;
    self.contentTransform = GLKMatrix4Identity;
    self.contentMode = UIViewContentModeScaleToFill;
    
    __block BOOL finishedProcessingVideo = NO;
    __block BOOL finishedProcessingAudio = self.writerAudioInput == nil;
    
    [self.writerVideoInput requestMediaDataWhenReadyOnQueue:dispatch_get_main_queue() usingBlock:^{
        if (self.assetReader.status == AVAssetReaderStatusReading) {
            CMSampleBufferRef sampleBuffer = [self.videoTrackOutput copyNextSampleBuffer];
            if (sampleBuffer) {
                [EAGLContext setCurrentContext:self.context];
                [self cleanUpTextures];
                
                CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                // Compensate for padding. A small black line will be visible on the right. Also adjust the texture coordinate transform to fix this.
                GLint width = (GLint)CVPixelBufferGetWidth(imageBuffer);
                GLint height = (GLint)CVPixelBufferGetHeight(imageBuffer);
                
                if (width != self.videoWidth || height != self.videoHeight) {
                    self.videoWidth = width;
                    self.videoHeight = height;
                    self.contentSize = CGSizeMake(width, height);
                    float ratio = (float)CVPixelBufferGetWidth(imageBuffer)/width;
                    self.texCoordTransform = (GLKMatrix2){ratio, 0, 0, 1}; // Apply a horizontal stretch to hide the row padding
                }
                
                [self _setTextureDataWithTextureCache:self.videoTextureCache texture:&_videoMainTexture imageBuffer:imageBuffer];
                [self displayWithFramebuffer:framebuffer width:width height:height present:NO];
                glFinish();
                
                CMTime presentationTimeStamp = CMSampleBufferGetOutputPresentationTimeStamp(sampleBuffer);
                if (![self.writerPixelBufferAdaptor appendPixelBuffer:pixelBuffer withPresentationTime:presentationTimeStamp]) {
                    NSLog(@"Failed to append pixel buffer at time %lld", presentationTimeStamp.value);
                }
                
                CMSampleBufferInvalidate(sampleBuffer);
                CFRelease(sampleBuffer);
            }
            else {
                glDeleteFramebuffers(1, &framebuffer);
                [self.writerVideoInput markAsFinished];
                self.assetWriter = nil;
                self.writerVideoInput = nil;
                self.writerPixelBufferAdaptor = nil;
                CFRelease(textureCache);
                CFRelease(textureTarget);
                CVPixelBufferRelease(pixelBuffer);
                
                self.contentTransform = previousContentTransform;
                self.contentMode = previousContentMode;
                finishedProcessingVideo = YES;
                
                if (self.assetReader.status == AVAssetReaderStatusCompleted) {
                    if (finishedProcessingAudio && completion) {
                        completion(YES, nil);
                    }
                }
                else if (self.assetReader.status == AVAssetReaderStatusFailed) {
                    if (finishedProcessingAudio && completion) {
                        completion(NO, self.assetReader.error);
                    }
                }
                else {
                    if (finishedProcessingAudio && completion) {
                        completion(NO, nil);
                    }
                }
            }
        }
    }];
    
    [self.writerAudioInput requestMediaDataWhenReadyOnQueue:dispatch_get_main_queue() usingBlock:^{
        CMSampleBufferRef sampleBuffer = [self.audioTrackOutput copyNextSampleBuffer];
        if (sampleBuffer) {
            if (![self.writerAudioInput appendSampleBuffer:sampleBuffer]) {
                NSLog(@"Failed to append audio sample buffer.");
            }
            CMSampleBufferInvalidate(sampleBuffer);
            CFRelease(sampleBuffer);
        }
        else {
            [self.writerAudioInput markAsFinished];
            finishedProcessingAudio = YES;
            
            if (self.assetReader.status == AVAssetReaderStatusCompleted) {
                if (finishedProcessingVideo && completion) {
                    completion(YES, nil);
                }
            }
            else if (self.assetReader.status == AVAssetReaderStatusFailed) {
                if (finishedProcessingVideo && completion) {
                    completion(NO, self.assetReader.error);
                }
            }
            else {
                if (finishedProcessingVideo && completion) {
                    completion(NO, nil);
                }
            }
        }
    }];
}

@end
