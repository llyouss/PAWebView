//
//  ViewController.m
//  PAWebViewDemo
//
//  Created by llyouss on 2018/1/9.
//  Copyright © 2018年 llyouss. All rights reserved.
//

#import "ViewController.h"
#import "PAWebView.h"

#define PAColor(r, g, b, a) [UIColor colorWithRed:(r)/255.0f green:(g)/255.0f blue:(b)/255.0f alpha:a]

#define     DEFAULT_BACKGROUND_COLOR         PAColor(239.0, 239.0, 244.0, 1.0) //默认背景颜色
#define     DEFAULT_NAVBAR_COLOR             PAColor(22.0, 129.0, 254.0, 1.0)  //导航栏背景颜色

typedef void (^runCaseBlock)(id);

@interface ViewController ()<PAWKScriptMessageHandler>

@property (nonatomic,strong) NSDictionary * runBlockDict;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
 
    [self.navigationController.navigationBar setBarTintColor:DEFAULT_NAVBAR_COLOR];
    [self.navigationController.navigationBar setTintColor:[UIColor whiteColor]];
    
    //初始化，单例
    PAWebView *webView = [PAWebView shareInstance];
    webView.openCache = YES;  //打开缓存
    
//    webView setcookie:<#(NSHTTPCookie *)#>  //设置cookie
//    [webView WKSharedHTTPCookieStorage];  //获取所有缓存的cookies
//    [webView deleteAllWKCookies];  //删除所有缓存的cookies
    
    //添加与JS交互事件
    [self addMessageHandleName];
    
    //加载网页
    [webView loadRequestURL:[NSURL URLWithString:@"https://www.sina.cn"]];
    //webView loadLocalHTMLWithFileName:<#(NSString *)#> 加载本地网页
//    [webView reload]; //重新加载网页
//    [webView reloadFromOrigin]; //无视缓存，重新加载服务器最新的网页
    
    [self.navigationController pushViewController:webView animated:YES];
    
    //调用js
    [self performSelector:@selector(TESTCallJS) withObject:nil afterDelay:6];
    
//    [webView goback]; //返回上一级
//    [webView goForward]; //返回下一级
    
    //二维码识别后返回的二维码数据
    [webView notificationInfoFromQRCode:^(NSString *info) {
        
    }];
    
    // 清除缓存
//    [webView deleteAllWebCache];
    
}

- (void)PAUserContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message{
    NSLog(@"监听JS调用IC");
}

#pragma mark - JS 调用 OC
- (void)addMessageHandleName
{
    PAWebView *webView = [PAWebView shareInstance];
    [webView addScriptMessageHandlerWithName:@[@"AliPay",@"weixin"]];
    __weak typeof(self)weekSelf = self;
    [webView addScriptMessageHandlerWithName:@[@"AliPay",@"weixin"] observeValue:^(WKUserContentController *userContentController, WKScriptMessage *message) {
        
        //JS调用OC处理
        __strong typeof(self)strongSelf = weekSelf;
        ((runCaseBlock)strongSelf.runBlockDict[message.name])(message.body);
    }];
}

//JS调用OC处理事件
#pragma mark runBlockDict 运行的代码块
-(NSDictionary *)runBlockDict
{
    if (_runBlockDict == nil) {
        _runBlockDict =
        @{
          @"AliPay":
              ^(id body) {
                  NSLog(@"请求支付宝事件");
              },
          @"weixin":
              ^(id body) {
                  NSLog(@"请求微信事件");
              }
          };
    }
    return _runBlockDict;
}

#pragma mark - OC 调用 JS
- (void)TESTCallJS{
    [[PAWebView shareInstance] callJS:@"alert('调用JS成功')"];
}

- (void)TESTcallJS1
{
    [[PAWebView shareInstance] callJS:@"alert('调用JS成功1')" handler:^(id response, NSError *error) {
        NSLog(@"调用js回调事件");
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
