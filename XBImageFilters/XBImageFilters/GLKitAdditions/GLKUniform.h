//
//  GLKUniform.h
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GLKShaderVariable.h"

@interface GLKUniform : GLKShaderVariable

@property (assign, nonatomic) void *value;

@end
