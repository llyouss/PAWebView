//
//  WKBaseWebView.m
//  Pkit
//
//  Created by llyouss on 2017/12/15.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import "WKBaseWebView.h"
#import "PAWKPanGestureRecognizer.h"
#import <UIKit/UIGestureRecognizerSubclass.h>

@interface WKBaseWebView ()<UIGestureRecognizerDelegate>

@property (nonatomic, retain) PAWKPanGestureRecognizer *pan;
@property (assign, nonatomic) BOOL animatedFlag;

@end

@implementation WKBaseWebView

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSDictionary * dict = [NSDictionary dictionaryWithObject:[UIColor whiteColor] forKey:NSForegroundColorAttributeName];
    self.navigationController.navigationBar.titleTextAttributes = dict;
    self.navigationController.navigationBar.translucent = YES;
    
    if ([[[UIDevice currentDevice] systemVersion] doubleValue] >= 7.0) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

#pragma mark -- navigation/NaviBarItem setting-------
/** 状态栏样式 */
- (UIStatusBarStyle)preferredStatusBarStyle
{
    //???:设置状态栏颜色（字体和背景）
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        self.view.backgroundColor = [UIColor colorWithRed:4/255.0 green:176/255.0 blue:250/255.0 alpha:1];
    });
    return UIStatusBarStyleLightContent;
}


#pragma NaviBarItem setting------
#pragma mark - 添加关闭按钮



#pragma mark - init
- (UIBarButtonItem *)backItem
{
    if (!_backItem)
    { _backItem = [[UIBarButtonItem alloc] init];
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        //这是一张“<”的图片，可以让美工给切一张
        UIImage *image = [UIImage imageNamed:@"PAWebBack.png"];
        [btn setImage:image forState:UIControlStateNormal];
        [btn setTitle:@"  返回" forState:UIControlStateNormal];
        [btn.titleLabel setFont:[UIFont boldSystemFontOfSize:17]];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        //字体的多少为btn的大小
        [btn sizeToFit];
        //左对齐
        btn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        //让返回按钮内容继续向左边偏移15，如果不设置的话，就会发现返回按钮离屏幕的左边的距离有点儿大，不美观
        btn.contentEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0);
        btn.frame = CGRectMake(0, 0, 58, 40);
        _backItem.customView = btn;
    }
    return _backItem;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.childViewControllers.count == 1) { //当只有一个自控制器时不可滑动
        return NO;
    }
    
    return YES;
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
