//
//  UIView+XDRefresh.h
//  仿微信朋友圈下拉刷新
//  作者：谢兴达（XD）
//  Created by 谢兴达 on 2017/4/14.
//  Copyright © 2017年 谢兴达. All rights reserved.
//  https://github.com/Xiexingda/XDRefresh.git

#import <UIKit/UIKit.h>

@interface UIView (XDRefresh)
/**
 下拉刷新

 @param scrollView 需要添加刷新的tableview
 @param position icon位置（默认：{10，34}navBar左上角）
 @param block 刷新回调
 */
- (void)XD_refreshWithObject:(UIScrollView *)scrollView atPoint:(CGPoint)position downRefresh:(void(^)(void))block;

/**
 结束刷新动作
 */
- (void)XD_endRefresh;

/**
 开始刷新
 */
- (void)XD_beginRefresh;

/**
 释放观察者，用于手动释放，否则将会在界面退出时自动释放
 */
- (void)XD_freeReFresh;

@end



@interface RefreshView : UIScrollView
//刷新view的icon
@property (nonatomic, strong)UIImageView *refreshIcon;

@end
