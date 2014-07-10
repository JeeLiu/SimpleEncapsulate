//
//  ViewController.m
//  SimpleEncapsulateDemo
//
//  Created by yhtian on 14-6-12.
//  Copyright (c) 2014年 yhtian. All rights reserved.
//

#import "ViewController.h"
#import <SimpleEncapsulate/SimpleEncapsulate.h>
#import "SearchResult.h"
#import "SearchParam.h"
#import "DetailViewController.h"

@interface ViewController ()<UISearchBarDelegate>
@end

@implementation ViewController

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"data"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    [self addObserver:self forKeyPath:@"data" options:NSKeyValueObservingOptionNew context:NULL];

    //从URIInfo.plist文件中加载所有的请求信息
    [SEURIInfo loadInfoFromFile:[[NSBundle mainBundle] pathForResource:@"URIInfo" ofType:@"plist"]];
    //创建一个数据库表
    NSString *sql = @"create table if not exists bookinfo (id text primary key, title text)";
    [[SEDatabase sharedDatabase] updateWithQuery:sql error:nil];

    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:@"DefaultCell"];
    //获取缓存在数据库中的内容
    sql = @"select * from bookinfo";
    [[SEDatabase sharedDatabase] fetchAsyncWithQuery:sql regClass:[Book class] completionHandler:^(NSArray *data) {
        self.data = data;
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - tableview delegate and dataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.data count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"DefaultCell"];
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.font = [UIFont systemFontOfSize:14];
    Book *books = self.data[indexPath.row];
    cell.textLabel.text = books.title;
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    DetailViewController *detail = [self.storyboard instantiateViewControllerWithIdentifier:@"DetailViewController"];
    detail.book = self.data[indexPath.row];
    [self.navigationController pushViewController:detail animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self.view endEditing:YES];
}

#pragma mark - data handling

- (void)handleData:(id)data withMsgId:(NSInteger)msgId
{
    //数据返回时的操作
    SearchResult *result = data;
    if (result.total) {
        self.data = result.books;
        NSMutableArray *array = @[].mutableCopy;
        NSString *sql;
        // 存入数据库
        for (Book *book in self.data) {
            sql = [NSString stringWithFormat:@"insert or replace into bookinfo (id, title) values"
                   " (\"%@\", \"%@\")", book.id, book.title];
            [array addObject:sql];
        }
        [[SEDatabase sharedDatabase] updateBatchWithQueries:array completionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"%@", error);
            } else {
                NSLog(@"success!");
            }
        }];
    }
}

- (void)handleError:(NSError *)error withMsgId:(NSInteger)msgId
{
    NSLog(@"%@", error);
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    //取消前一次查询，同时延时200毫秒接着查询
    [[SEDatabase sharedDatabase] cancelQueryWithTag:1];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
                       NSString *sql = [NSString stringWithFormat:@"select * from bookinfo where title like \"%%%@%%\"", searchText];
                       [[SEDatabase sharedDatabase] fetchAsyncWithQuery:sql tag:1 regClass:[Book class] completionHandler:^(NSArray *data) {
                           self.data = data;
                       }];
    });
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    SearchParam *param = [[SearchParam alloc] init];
    param.q = searchBar.text;
    param.start = 0;
    param.count = 50;
    //根据关键字查询图书，param可以是AMCObject的子类，也可以是NSDictionary或者NSArray的数据
    //msgid分为两部分，低位0xFFFF为MAINMSG，高位0xFFFF为SUBMSG，这样一个主的请求可以附带多个
    //请求，msgid可以定义在一个头文件中，方便到处使用。注意，如果使用了plist，则key为对应的msgid。
    //参见URIInfo.plist。
    [self fetchWithMsgId:1 params:param];
    [searchBar resignFirstResponder];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    [self.tableView reloadData];
}

@end
