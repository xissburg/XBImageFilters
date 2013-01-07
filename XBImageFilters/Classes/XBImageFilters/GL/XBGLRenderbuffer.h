//
//  XBGLRenderbuffer.h
//  XBImageFilters
//
//  Created by xissburg on 11/5/12.
//
//

#import <Foundation/Foundation.h>

@class CAEAGLLayer;

@interface XBGLRenderbuffer : NSObject

@property (nonatomic, readonly) GLuint name;
@property (nonatomic, readonly) CGSize size;

- (BOOL)storageFromGLLayer:(CAEAGLLayer *)layer;

@end
