//
//  XBGLShaderVariable.h
//  XBImageFilters
//
//  Created by xiss burg on 2/20/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XBGLShaderVariable : NSObject

@property (readonly, copy, nonatomic) NSString *name;
@property (readonly, nonatomic) GLint location;
@property (readonly, nonatomic) GLint size;
@property (readonly, nonatomic) GLenum type;
@property (readonly, nonatomic) GLint typeSize;

- (id)initWithName:(NSString *)name location:(GLint)location size:(GLint)size type:(GLenum)type;

@end

size_t TypeSizeForType(GLenum type);
