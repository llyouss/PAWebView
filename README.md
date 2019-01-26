# PAWeView.     
An component WebView for ios 
## Introduction
PAWeView is an extensible WebView which is built on top of WKWebView, the modern WebKit framework debuted in iOS 8.0. It provides fast Web  for developing sophisticated iOS native or hybrid applications.
## Sample Project
For a complete example on how to use PAWeView, see the Sample Project.
## The Class Structure Chart of PAWeView
![Image text](https://github.com/llyouss/PAWeView/blob/master/Image/PAWebview.png)
## Minimum Requirements
 - Deployment: iOS 8.0
## Usage
- #import "PAWebView.h"  
- plist
  ```
   <key>UIViewControllerBasedStatusBarAppearance</key>
    <false/>
   <key>UIStatusBarStyle</key>
   <string>UIStatusBarStyleDefault</string>
   <key>NSPhotoLibraryUsageDescription</key>
   <string>访问相册</string>
   <key>NSAppTransportSecurity</key>
   <dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
   </dict>
  ```
- Loading 
  ```
  //初始化单例  
   PAWebView *webView = [PAWebView shareInstance];  
   
  //加载网页  
  [webView loadRequestURL:[NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://www.sina.cn"] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:20.0f]];
   [self.navigationController pushViewController:webView animated:YES];
   
   //缓存沿用了 NSURLRequest 的缓存机制，用户可以自定义设置；
  typedef NS_ENUM(NSUInteger, NSURLRequestCachePolicy)
  {
      NSURLRequestUseProtocolCachePolicy = 0, //默认的缓存策略

      NSURLRequestReloadIgnoringLocalCacheData = 1, //忽略缓存，从服务端加载数据；
      NSURLRequestReloadIgnoringLocalAndRemoteCacheData = 4, // Unimplemented
      NSURLRequestReloadIgnoringCacheData = NSURLRequestReloadIgnoringLocalCacheData,

      NSURLRequestReturnCacheDataElseLoad = 2,
      NSURLRequestReturnCacheDataDontLoad = 3,

      NSURLRequestReloadRevalidatingCacheData = 5, // Unimplemented
  };
   
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
/**
  读取本地磁盘的cookies，包括WKWebview的cookies和sharedHTTPCookieStorage存储的cookies

 @return 返回包含所有的cookies的数组；
 当系统低于 iOS11 时，cookies 将同步NSHTTPCookieStorage的cookies，当系统大于iOS11时，cookies 将同步
 */
- (NSMutableArray *)WKSharedHTTPCookieStorage;

/**
  提供cookies插入，用于loadRequest 网页之前

 @param cookie NSHTTPCookie 类型
  cookie 需要设置 cookie 的name，value，domain，expiresDate（过期时间，当不设置过期时间，cookie将不会自动清除）；
  cookie 设置expiresDate时使用 [cookieProperties setObject:expiresDate forKey:NSHTTPCookieExpires];将不起作用，原因不明；使用 cookieProperties[expiresDate] = expiresDate; 设置cookies 设置时间。
 */
- (void)setCookie:(NSHTTPCookie *)cookie;

/** 删除单个cookie */
- (void)deleteWKCookie:(NSHTTPCookie *)cookie completionHandler:(nullable void (^)(void))completionHandler;
/** 删除域名下的所有的cookie */
- (void)deleteWKCookiesByHost:(NSURL *)host completionHandler:(nullable void (^)(void))completionHandler;

/** 清除所有的cookies */
- (void)clearWKCookies;
 
 ```
 
 - 清除缓存
 
 ```
 
 /** 清除所有缓存（cookie除外） */
- (void)clearWebCacheFinish:(void(^)(BOOL finish,NSError *error))block;
 
 ```
 
 - 清除 backForwardList 列表
 
 ```
 /*清除backForwardList 列表*/
- (void)clearBackForwardList;
 
 ```
 
 
