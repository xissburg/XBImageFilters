//
//  XBFilteredImageView.h
//  XBImageFilters
//
//  Created by xiss burg on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>

@interface XBFilteredImageView : UIView <GLKViewDelegate>

@property (strong, nonatomic) UIImage *image;
@property (assign, nonatomic) GLKMatrix4 contentTransfom;

- (void)setFilterFragmentShaderFromFile:(NSString *)path error:(NSError *__autoreleasing *)error;

@end
