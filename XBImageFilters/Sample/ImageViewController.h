//
//  ImageViewController.h
//  XBImageFilters
//
//  Created by xiss burg on 2/15/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "XBFilteredImageView.h"

@interface ImageViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet XBFilteredImageView *filteredImageView;

@end
