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
- loading webView
  ```
  //初始化单例  
 PAWebView *webView = [PAWebView shareInstance];  
 //打开缓存  
 webView.openCache = YES;    
 //加载网页  
 [webView loadRequestURL:[NSURL URLWithString: @"https://www.sina.cn"]];  
 [self.navigationController pushViewController:webView animated:YES];
  ```
