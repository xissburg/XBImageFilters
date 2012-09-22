//
//  XBTextureInfo.m
//  XBImageFilters
//
//  Created by xiss burg on 7/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XBTextureInfo.h"

@implementation XBTextureInfo

@synthesize name = _name, target = _target, width = _width, height = _height, alphaState = _alphaState, textureOrigin = _textureOrigin, containsMipmaps = _containsMipmaps;

- (id)initWithName:(GLuint)name target:(GLenum)target width:(GLuint)width height:(GLuint)height
{
    self = [super init];
    if (self) {
        _name = name;
        _target = target;
        _width = width;
        _height = height;
    }
    return self;
}

@end
