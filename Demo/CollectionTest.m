//
//  CollectionTest.m
//  Demo
//
//  Created by 谢兴达 on 2018/9/26.
//  Copyright © 2018年 谢兴达. All rights reserved.
//

#import "CollectionTest.h"
#import "CollectCell.h"
#import "UIView+XDRefresh.h"

#define KWIDTH [UIScreen mainScreen].bounds.size.width
#define CellID @"collectioncellid"
@interface CollectionTest ()<UICollectionViewDelegateFlowLayout,UICollectionViewDataSource>
@property (nonatomic, strong) UICollectionView *collect;
@property (nonatomic, strong) UICollectionViewFlowLayout *layout;
@end

@implementation CollectionTest
- (void)dealloc {
    [self.view XD_freeReFresh];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _layout = [[UICollectionViewFlowLayout alloc]init];
    _layout.itemSize = CGSizeMake(KWIDTH, 200);
    _layout.minimumLineSpacing = 0;
    _layout.minimumInteritemSpacing = 0;
    
    _collect = [[UICollectionView alloc]initWithFrame:self.view.bounds collectionViewLayout:_layout];
    _collect.dataSource = self;
    _collect.delegate = self;
    _collect.contentInset = UIEdgeInsetsMake(-100, 0, 0, 0);
    [self.view addSubview:_collect];
    
    [_collect registerClass:[CollectCell class] forCellWithReuseIdentifier:CellID];
    
    /**
     添加下拉刷新
     
     */
    __weak typeof(self) weakSelf = self;
    [self.view XD_refreshWithObject:_collect atPoint:CGPointZero downRefresh:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        //开始刷新
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //3 秒后结束刷新
            [strongSelf.view XD_endRefresh];
        });
    }];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 30;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    CollectCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:CellID forIndexPath:indexPath];
    return cell;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
