# PAWeView.     
An component WebView for ios 
## Introduction
PAWeView is an extensible WebView which is built on top of WKWebView, the modern WebKit framework debuted in iOS 8.0. It provides fast Web  for developing sophisticated iOS native or hybrid applications.
## Sample Project
For a complete example on how to use PAWeView, see the Sample Project.
## The Class Structure Chart of MJRefresh
![Image text](https://github.com/llyouss/PAWeView/blob/master/Image/PAWebview.png)
## Minimum Requirements
 - Deployment: iOS 8.0
## Usage
- #import "PAWebView.h"  
- Loading 
  ```
  //初始化单例  
   PAWebView *webView = [PAWebView shareInstance];  
  //打开缓存  
   webView.openCache = YES;    
  //加载网页  
   [webView loadRequestURL:[NSURL URLWithString: @"https://www.sina.cn"]];  
   [self.navigationController pushViewController:webView animated:YES];
  ```
- Refress
 ```
  //重新加载网页  
   [webView reload];   
  //无视缓存，重新加载服务器最新的网  
   [webView reloadFromOrigin]; 
 
 ```
 - JS->Native
 ```
 /* messageHander实现JS调用Native */  
- (void)addMessageHander  
{  
   //注入交互事件，实现 PAWKScriptMessageHandler 代理  
    [webView addScriptMessageHandlerWithName:@[@"AliPay",@"weixin"]];  
  
   //通过block的形式实现  
    [webView addScriptMessageHandlerWithName:@[@"AliPay",@"weixin"] observeValue:^(WKUserContentController *userContentController, WKScriptMessage *message) {  
      
       //JS调用OC处理  
       NSLog(@"name:%@;body:%@",message.name,message.body);  
    }];  
}  
  
/* 实现 PAWKScriptMessageHandler 代理 */  
- (void)PAUserContentController: (WKUserContentController *) userContentController  didReceiveScriptMessage:(WKScriptMessage *)message{  
  
       //JS调用OC处理   
        NSLog(@"name:%@;body:%@",message.name,message.body);  
} 
```
- Native -> JS
 ```
  //方式一、  
   [[PAWebView shareInstance] callJS:@"alert('调用JS成功')"];  
  //方式二、  
   [[PAWebView shareInstance] callJS:@"alert('调用JS成功')" handler:^(id response, NSError *error) {  
        NSLog(@"调用js回调事件");  
   }]; 
 ```
 - Cooikes Manager 
 ```
  //设置cookies  
  //webView setcookie:<#(NSHTTPCookie *)#>    
  //获取缓存中的cookies  
   [webView WKSharedHTTPCookieStorage];   
  // 删除缓存中所有的cookies  
   [webView deleteAllWKCookies];  
 
 ```
 
