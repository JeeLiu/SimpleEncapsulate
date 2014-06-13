//
//  DetailViewController.h
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-13.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Book, BookInfo;

@interface DetailViewController : UIViewController
@property(nonatomic, strong) Book *book;
@property(nonatomic, strong) BookInfo *info;

@property (weak, nonatomic) IBOutlet UIImageView *logo;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *authorLabel;
@property (weak, nonatomic) IBOutlet UITextView *summaryView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *waitingView;

@end
