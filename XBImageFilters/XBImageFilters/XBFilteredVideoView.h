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

- (void)play;
- (void)pause;
- (void)stop;
- (void)saveFilteredVideoToURL:(NSURL *)URL;

@end
