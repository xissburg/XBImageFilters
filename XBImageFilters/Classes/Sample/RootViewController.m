//
//  RootViewController.m
//  XBImageFilters
//
//  Created by xiss burg on 3/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "RootViewController.h"

#define kTitleKey @"title"
#define kSegueKey @"segue"

@interface RootViewController ()

@property (copy, nonatomic) NSArray *sampleViewControllers;

@end

@implementation RootViewController

@synthesize sampleViewControllers;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sampleViewControllers = [[NSArray alloc] initWithObjects:
                                  [[NSDictionary alloc] initWithObjectsAndKeys:@"Image Filter", kTitleKey, @"ImageFilterSegue", kSegueKey, nil],
                                  [[NSDictionary alloc] initWithObjectsAndKeys:@"Camera Filter", kTitleKey, @"CameraFilterSegue", kSegueKey, nil], nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.sampleViewControllers.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    cell.textLabel.text = [[self.sampleViewControllers objectAtIndex:indexPath.row] objectForKey:kTitleKey];
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self performSegueWithIdentifier:[[self.sampleViewControllers objectAtIndex:indexPath.row] objectForKey:kSegueKey] sender:nil];
}

@end
