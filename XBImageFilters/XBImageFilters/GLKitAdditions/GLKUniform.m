//
//  GLKUniform.m
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "GLKUniform.h"

@implementation GLKUniform

@synthesize value = _value;

- (id)initWithName:(NSString *)name location:(GLint)location size:(GLint)size type:(GLenum)type
{
    self = [super initWithName:name location:location size:size type:type];
    if (self) {
        _value = malloc(self.typeSize * self.size);
        memset(_value, 0, self.typeSize * self.size);
    }
    return self;
}

- (void)dealloc
{
    free(_value);
}

#pragma mark - Methods

- (void)setValue:(void *)value
{
    if (_value == value) {
        return;
    }
    
    memcpy(_value, value, self.typeSize * self.size);
}

@end