//
//  ProcessingViewController.h
//  XBImageFilters
//
//  Created by Dirk-Willem van Gulik on 28-03-12.
//  Copyright (c) 2012 webWeaving.org. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ProcessingViewController : UIViewController <UIPickerViewDataSource, UIPickerViewDelegate> {
    NSDictionary *images;
    NSArray *labels;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIPickerView *ctrl;

@end
