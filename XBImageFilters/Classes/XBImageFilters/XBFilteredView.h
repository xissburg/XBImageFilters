//
//  XBFilteredView.h
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface XBFilteredView : UIView <GLKViewDelegate>

@property (assign, nonatomic) GLKMatrix4 contentTransfom;

- (void)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error;
- (void)setFilterFragmentShadersFromFiles:(NSArray *)paths error:(NSError *__autoreleasing *)error;

/* These methods are conceptually protected and should not be called directly. They are intended to be called by subclasses. */
- (void)_setTextureData:(GLvoid *)textureData width:(GLint)width height:(GLint)height;
- (void)_updateTextureWithData:(GLvoid *)textureData;
- (void)_deleteMainTexture;

@end
