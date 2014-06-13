//
//  ViewController.h
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-12.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UITableViewController

@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;
@property(nonatomic, strong) NSArray *data;

@end
