# XDRefresh

仿微信朋友圈下拉刷新

//使用方法

1. 导入头文件

#import "UIView+XDRefresh.h"

2. 把你的 tableview 添加到刷新

//point 为零时 位置默认为左上角

[self.view XD_refreshWithObject:_tableview atPoint:CGPointZero downRefresh:^{

//开始刷新

}];

3. 刷新结束后结束刷新

[self.view XD_endRefresh];

# 效果
![image](https://github.com/Xiexingda/XDRefresh/blob/master/show.png)

