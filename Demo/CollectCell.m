//
//  CollectCell.m
//  Demo
//
//  Created by 谢兴达 on 2018/9/26.
//  Copyright © 2018年 谢兴达. All rights reserved.
//

#import "CollectCell.h"

@implementation CollectCell
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor redColor];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

@end
