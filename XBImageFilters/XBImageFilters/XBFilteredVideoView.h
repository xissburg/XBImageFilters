//
//  XBFilteredVideoView.h
//  XBImageFilters
//
//  Created by xissburg on 5/19/13.
//
//

#import "XBFilteredView.h"

@interface XBFilteredVideoView : XBFilteredView

@property (nonatomic, copy) NSURL *videoURL;
@property (nonatomic, assign) BOOL replay;
@property (nonatomic, readonly, getter = isPlaying) BOOL playing;

- (void)play;
- (void)stop;
- (void)setVideoURL:(NSURL *)videoURL withCompletion:(void (^)(void))completion;
- (void)saveFilteredVideoToURL:(NSURL *)URL completion:(void (^)(BOOL success, NSError *error))completion;

@end
