//
//  ViewController.m
//  Demo
//
//  Created by 谢兴达 on 2017/4/18.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import "ViewController.h"
#import "UIView+XDRefresh.h"

@interface ViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (nonatomic, strong) UITableView *tableview;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"微信朋友圈下拉刷新";
    _tableview = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    _tableview.delegate = self;
    _tableview.dataSource = self;
    _tableview.tableHeaderView = [[UIView alloc]initWithFrame:CGRectMake(0,
                                                                         0,
                                                                         self.view.bounds.size.width,
                                                                         400)];
    _tableview.tableHeaderView.backgroundColor = [UIColor lightGrayColor];
    _tableview.contentInset = UIEdgeInsetsMake(-100, 0, 0, 0);
    _tableview.tableFooterView = [UIView new];
    [self.view addSubview:_tableview];
    
    
    /**
     添加下拉刷新
     
     */
    __weak typeof(self) weakSelf = self;
    [self.view XD_refreshWithObject:_tableview atPoint:CGPointZero downRefresh:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //开始刷新
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //3 秒后结束刷新
            [strongSelf.view XD_endRefresh];
        });
    }];
}




- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 20;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"testcell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"testcell"];
    }
    cell.textLabel.text = @"XD_下拉刷新测试";
    return cell;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
