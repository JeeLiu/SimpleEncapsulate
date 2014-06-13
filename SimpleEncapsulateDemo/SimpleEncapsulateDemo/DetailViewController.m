//
//  DetailViewController.m
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-13.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import "DetailViewController.h"
#import <AFNetworking/UIKit+AFNetworking.h>
#import "BookInfo.h"
#import "SearchResult.h"
#import "WebViewController.h"

@interface DetailViewController ()

@end

@implementation DetailViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    SEURIInfo *info = [SEURIInfo infoWithMessageId:2];
    info.relativePath = self.book.id;
    [self fetchWithMsgId:2 params:nil];
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - data handling

- (void)handleData:(id)data withMsgId:(NSInteger)msgId
{
    if (msgId == 2) {
        BookInfo *info = data;
        self.titleLabel.text = info.title;
        self.authorLabel.text = [info.author componentsJoinedByString:@","];
        if (info.summary) {
            self.summaryView.text = info.summary;
        } else {
            self.summaryView.text = @"没有简介";
        }
        [self.logo setImageWithURL:[NSURL URLWithString:info.image]];
        self.info = info;
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

- (void)handleError:(NSError *)error withMsgId:(NSInteger)msgId
{
    NSLog(@"%@", error);
}

- (void)fetchingDidStartWithMsgId:(NSInteger)msgId
{
    [self.waitingView startAnimating];
}

- (void)fetchingDidEndWithMsgId:(NSInteger)msgId
{
    [self.waitingView stopAnimating];
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    WebViewController *detail = [segue destinationViewController];
    detail.title = self.info.title;
    UIWebView *webView = (UIWebView *)detail.view;
    [webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.info.alt]]];
}

@end
