//
//  UIView+XDRefresh.m
//  仿微信朋友圈下拉刷新
//
//  Created by 谢兴达 on 2017/4/14.
//  Copyright © 2017年 谢兴达. All rights reserved.
//

#import "UIView+XDRefresh.h"
#import <objc/runtime.h>

#define MARGINTOP   50      //刷新icon区间
#define ICONSIZE    30      //下拉刷新icon 的大小

#define CircleTime  0.8     //旋转一圈所用时间
#define IconBackTime 0.2    //icon刷新完返回最顶端的时间

static char Refresh_Key, ScrollView_Key, Block_Key, MarginTop_Key, Animation_Key, RefreshStatus_Key;

@implementation UIView (XDRefresh)
/**animation**/
- (void)setAnimation:(CABasicAnimation *)animation {
    objc_setAssociatedObject(self, &Animation_Key, animation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (CABasicAnimation *)animation {
    return objc_getAssociatedObject(self, &Animation_Key);
}

/**refreshblock**/
- (void)setRefreshBlock:(void (^)(void))refreshBlock {
    objc_setAssociatedObject(self, &Block_Key, refreshBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void (^)(void))refreshBlock {
    return objc_getAssociatedObject(self, &Block_Key);
}

/**freshView**/
- (void)setRefreshView:(RefreshView *)refreshView {
    objc_setAssociatedObject(self, &Refresh_Key, refreshView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (RefreshView *)refreshView {
    return objc_getAssociatedObject(self, &Refresh_Key);
}

/**承接用的tableview**/
- (void)setExtenScrollView:(UIScrollView *)extenScrollView {
    objc_setAssociatedObject(self, &ScrollView_Key, extenScrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
- (UIScrollView *)extenScrollView {
    return objc_getAssociatedObject(self, &ScrollView_Key);
}

/**实时记录下拉初始状态**/
- (void)setMarginTop:(CGFloat)marginTop {
    objc_setAssociatedObject(self, &MarginTop_Key, [NSNumber numberWithFloat:marginTop], OBJC_ASSOCIATION_RETAIN);
}
- (CGFloat)marginTop {
    return [objc_getAssociatedObject(self, &MarginTop_Key) floatValue];
}

/**icon下拉范围**/
- (void)setThreshold:(CGFloat)threshold {
    //不需要任何操作
}
- (CGFloat)threshold {
    return -MARGINTOP;
}

/**offsetcollection**/
- (void)setOffsetCollect:(CGFloat)offsetCollect {
    //不需要任何操作
}
- (CGFloat)offsetCollect {
    return 10;
}

/**刷新状态**/
- (void)setRefreshStatus:(StatusOfRefresh)refreshStatus {
    objc_setAssociatedObject(self, &RefreshStatus_Key, [NSNumber numberWithInteger:refreshStatus], OBJC_ASSOCIATION_RETAIN);
}
- (StatusOfRefresh)refreshStatus {
    return [objc_getAssociatedObject(self, &RefreshStatus_Key) integerValue];
}


- (void)XD_refreshWithObject:(UIScrollView *)scrollView atPoint:(CGPoint)position downRefresh:(void (^)(void))block {
    if (![scrollView isKindOfClass:[UIScrollView class]]) {
        return;
    }
    self.refreshBlock = block;
    self.extenScrollView = scrollView;
    [self addObserverForView:self.extenScrollView];
    
    if (!self.refreshView) {
        CGRect positionFrame;
        
        if (position.x || position.y) {
            positionFrame = CGRectMake(position.x, self.frame.origin.y + position.y, ICONSIZE, ICONSIZE);
            
        } else {
            positionFrame = CGRectMake(10, self.frame.origin.y + 64 - ICONSIZE, ICONSIZE, ICONSIZE);
        }
            self.refreshView = [[RefreshView alloc]initWithFrame:positionFrame];
    }
        [self addSubview:self.refreshView];
    
}

/**
 添加观察者

 @param view 观察对象
 */
- (void)addObserverForView:(UIView *)view {
    [view addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld|NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    __weak typeof(self) weakSelf = self;
    //屏蔽掉全非状态时的操作
    if (self.refreshStatus == XDREFRESH_None) {
        return;
    }
    
    //屏蔽掉开始进入界面时的系统下拉动作
    if (self.refreshStatus == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            weakSelf.refreshStatus = XDREFRESH_Default;
        });
        return;
    }
    
    // 实时监测scrollView.contentInset.top， 系统优化以及手动设置contentInset都会影响contentInset.top。
    if (self.marginTop != self.extenScrollView.contentInset.top) {
        self.marginTop = self.extenScrollView.contentInset.top;
    }
    
    CGFloat offsetY = self.extenScrollView.contentOffset.y;
    
    /**异步调用主线程**/
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(weakSelf) strongSelf = weakSelf;
            /**非刷新状态**/
            if (strongSelf.refreshStatus == XDREFRESH_Default) {
                [strongSelf defaultHandleWithOffSet:offsetY change:change];
                
                /**刷新状态**/
            } else if (strongSelf.refreshStatus == XDREFRESH_BeginRefresh) {
                [strongSelf refreshingHandleWithOffSet:offsetY];
            }
        });
    });
}

/**
 非刷新状态时的处理

 @param offsetY tableview滚动偏移量
 */
- (void)defaultHandleWithOffSet:(CGFloat)offsetY change:(NSDictionary<NSKeyValueChangeKey,id> *)change {
    __weak typeof(self) weakSelf = self;
    // 向下滑动时<0，向上滑动时>0；
    CGFloat defaultoffsetY = offsetY + self.marginTop;
    
    /**刷新动作区间**/
    if (defaultoffsetY > self.threshold && defaultoffsetY < 0) {
        [self.refreshView setContentOffset:CGPointMake(0, defaultoffsetY)];
        
                        /*
                         注意：将default动作处理只放到 动作区间 和 超过/等于 临界点 的逻辑块里
                         目的：实现只有在下拉动作时才会有动作处理，否则没有
                         
                         */
                        [self anmiationHandelwithChange:change
                                              andStatus:XDREFRESH_Default
                                          needAnimation:YES];
    }
    
    /**(@"刷新临界点，把刷新icon置为最大区间")**/
    if (defaultoffsetY <= self.threshold && self.refreshView.contentOffset.y != self.threshold) {
        //添加动作，避免越级过大造成直接跳到最大位置影响体验
        [UIView animateWithDuration:0.05 animations:^{
            [weakSelf.refreshView setContentOffset:CGPointMake(0, weakSelf.threshold)];
        }];
    }
    
    /**超过/等于 临界点后松手开始刷新，不松手则不刷新**/
    if (defaultoffsetY <= self.threshold && self.refreshView.contentOffset.y == self.threshold) {
        if (self.extenScrollView.isDragging) {
                            //NSLog(@"不刷新");
                            //default动作处理
                            [self anmiationHandelwithChange:change
                                                  andStatus:XDREFRESH_Default
                                              needAnimation:YES];
            
        } else {
                            //NSLog(@"开始刷新");
                            //刷新状态动作处理
                            [self anmiationHandelwithChange:change
                                                  andStatus:XDREFRESH_BeginRefresh
                                              needAnimation:YES];
                            // 由非刷新状态 进入 刷新状态
                            [self beginRefresh];
        }
    }
    
    /**当tableview回滚到顶端的时候把刷新的iconPosition置零**/
    if (defaultoffsetY >= 0 && self.refreshView.contentOffset.y != 0) {
        [self.refreshView setContentOffset:CGPointMake(0, 0)];
        //当回到原始位置后，转角也回到原始位置
        [self trangleToBeOriginal];
    }
}

/**
 刷新状态时的处理

 @param offsetY tableview滚动偏移量
 */
- (void)refreshingHandleWithOffSet:(CGFloat)offsetY {
    __weak typeof(self) weakSelf = self;
    //转换坐标（相对费刷新状态）
    CGFloat refreshoffsetY = offsetY + self.marginTop + self.threshold;
    /**刷新状态时动作区间**/
    if (refreshoffsetY > self.threshold && refreshoffsetY < 0) {
        [self.refreshView setContentOffset:CGPointMake(0, refreshoffsetY)];
    }
    
    /**刷新状态临界点，把刷新icon置为最大区间**/
    if (refreshoffsetY <= self.threshold && self.refreshView.contentOffset.y != self.threshold) {
        //添加动作，避免越级过大造成直接跳到最大位置影响体验
        [UIView animateWithDuration:0.05 animations:^{
            [weakSelf.refreshView setContentOffset:CGPointMake(0, weakSelf.threshold)];
        }];
    }
    
    /**当tableview相对坐标回滚到顶端的时候把刷新的iconPosition置零**/
    if (refreshoffsetY >= 0 && self.refreshView.contentOffset.y != 0) {
        [self.refreshView setContentOffset:CGPointMake(0, 0)];
    }
}

/**
 开始刷新
 */
- (void)beginRefresh {
    //状态取反 保证一次刷新只执行一次回调
    if (self.refreshStatus != XDREFRESH_BeginRefresh) {
        self.refreshStatus = XDREFRESH_BeginRefresh;
        if (self.refreshBlock) {
            self.refreshBlock();
        }
    }
}


/**
 动作处理

 @param change 监听到的offset变化
 */
- (void)anmiationHandelwithChange:(NSDictionary<NSKeyValueChangeKey,id> *)change andStatus:(StatusOfRefresh)status needAnimation:(BOOL)need {
    if (!need) {
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    /**
     非刷新状态下的动作处理
     */
    if (status == XDREFRESH_Default) {
        /**把nsPoint结构体转换为cgPoint**/
        CGPoint oldPoint;
                id oldValue = [change valueForKey:NSKeyValueChangeOldKey];
                [(NSValue*)oldValue getValue:&oldPoint];
        
        
        CGPoint newPoint;
                id newValue = [ change valueForKey:NSKeyValueChangeNewKey ];
                [(NSValue*)newValue getValue:&newPoint];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (oldPoint.y < newPoint.y) {
                weakSelf.refreshView.refreshIcon.transform = CGAffineTransformRotate(weakSelf.refreshView.refreshIcon.transform,
                                                                               -weakSelf.offsetCollect/50);
                
                NSLog(@"向上拉动");
            } else if (oldPoint.y > newPoint.y) {
                weakSelf.refreshView.refreshIcon.transform = CGAffineTransformRotate(weakSelf.refreshView.refreshIcon.transform,
                                                                               weakSelf.offsetCollect/50);
                
                NSLog(@"向下拉动");
                
            } else {
                NSLog(@"没有拉动");
            }
        });
        
        /**
         刷新状态下的动作处理
         */
    } else if (status == XDREFRESH_BeginRefresh) {
        if (!self.animation) {
            self.animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
        }
        
                            dispatch_async(dispatch_get_main_queue(), ^{
                                //逆时针效果
                                weakSelf.animation.fromValue = [NSNumber numberWithFloat:0.f];
                                weakSelf.animation.toValue =  [NSNumber numberWithFloat: -M_PI *2];
                                weakSelf.animation.duration  = CircleTime;
                                weakSelf.animation.autoreverses = NO;
                                weakSelf.animation.fillMode =kCAFillModeForwards;
                                weakSelf.animation.repeatCount = MAXFLOAT; //一直自旋转
                                [weakSelf.refreshView.refreshIcon.layer addAnimation:weakSelf.animation forKey:@"refreshing"];
                            });
    }
}

/**
 角度还原:用于非刷新时回到顶部 和 刷新状态endRefresh 中
 */
- (void)trangleToBeOriginal {
    self.refreshView.refreshIcon.transform = self.refreshView.transform;
}

/**
 结束刷新 对外接口
 */
- (void)XD_endRefresh {
    if (!self.extenScrollView) {
        return;
    }
    //延迟刷新0.3秒，避免立即返回tableview时offset不稳定造成反弹等不理想的效果
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf endRefresh];
    });
}

/**
 结束刷新执行函数
 */
- (void)endRefresh {
    /**
     仿微信当下拉一直拖住时，icon不会返回
     虽然在repeat的计时器里，但是该方法只会回调一次
     原理：nstimer默认是放在defaultrunloop中的，当下拉拖住时runloop改成了tracking模式，同一时间下线程只能处理一种runloop模式，所以滚动时timer只注册不执行，当松开手时拖拽动作执行完毕，runloop回到default模式下，这个时候nstimer被执，block开始回调，在第一次回调后又调用了invalidate方法将计时器释放了
     注意** 最后用invalidate把计时器释放掉
     */
    __weak typeof(self) weakSelf = self;
    if (self.extenScrollView.isDragging) {
        //iOS10 以上
        if (@available(iOS 10, *)) {
            [NSTimer scheduledTimerWithTimeInterval:0.2 repeats:YES block:^(NSTimer * _Nonnull timer) {
                [weakSelf endRefresh];
                [timer invalidate];
            }];
            
            //iOS10 以下
        } else {
            [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(timerCall:) userInfo:nil repeats:YES];
        }
        
        return;
    }
    
    //当结束刷新时，把状态置为全非状态，避免在[UIView animateWithDuration:0.2]icon返回动作中的人为干预，造成icon闪顿现象
    if (self.refreshStatus != XDREFRESH_None) {
        self.refreshStatus = XDREFRESH_None;
        
        [UIView animateWithDuration:IconBackTime animations:^{
            [weakSelf.refreshView setContentOffset:CGPointMake(0, 0)];
            
        } completion:^(BOOL finished) {
            //结束动画
            [weakSelf.refreshView.refreshIcon.layer removeAnimationForKey:@"refreshing"];
            
            //当回到原始位置后，转角也回到原始位置
            [weakSelf trangleToBeOriginal];
            
            //结束后将状态重置为非刷新状态 以备下次刷新
            weakSelf.refreshStatus = XDREFRESH_Default;
        }];
    }
}

/**
 计时器调用方法

 @param timer nstimer
 */
- (void)timerCall:(NSTimer *)timer {
    [self endRefresh];
    [timer invalidate];
}

/**
 释放观察
 */
- (void)XD_freeReFresh {
    [self.extenScrollView removeObserver:self forKeyPath:@"contentOffset"];
}

@end

#pragma mark -- 刷新icon
@implementation RefreshView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.clipsToBounds = NO;
        self.bounces = NO;
        self.contentSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
        self.backgroundColor = [UIColor whiteColor];
        [self creatMainUI];
    }
    return self;
}

- (void)creatMainUI {
    if (!_refreshIcon) {
        _refreshIcon = [[UIImageView alloc]initWithFrame:CGRectMake(0,
                                                                    0,
                                                                    self.frame.size.width,
                                                                    self.frame.size.height)];
    }
        _refreshIcon.backgroundColor = [UIColor redColor];
        _refreshIcon.image = [[UIImage imageWithContentsOfFile:[[NSBundle bundleWithPath:[[NSBundle bundleForClass:[RefreshView class]] pathForResource:@"XDRefreshResource" ofType:@"bundle"]] pathForResource:@"refresh" ofType:@"png"]] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        _refreshIcon.contentMode = UIViewContentModeScaleAspectFit;
        _refreshIcon.clipsToBounds = YES;
        _refreshIcon.layer.cornerRadius = self.frame.size.width/2.0;
        [self addSubview:_refreshIcon];
}

@end
