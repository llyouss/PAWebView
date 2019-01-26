//
//  PAWebView+UIDelegate.m
//  Pkit
//
//  Created by llyouss on 2017/12/25.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import "PAWebView+UIDelegate.h"

@implementation PAWebView (UIDelegate)


#pragma mark -
#pragma mark   WKUIDelegate

- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> * _Nullable URLs))completionHandler API_AVAILABLE(macosx(10.12));
{
    
}
- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController API_AVAILABLE(ios(10.0)){
  
    
}

- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions{
    
    return nil;
}
- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo{
    
    return YES;
}

/** 创建新的webview
 * 可以指定配置对象、导航动作对象、window特性
 */
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures
{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

/** 调用JS的alert()方法 */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(nonnull NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(void))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message ? message : @"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    
    [self PApresentViewController:alertController animated:YES];
}

/** 调用JS的confirm()方法 */
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(nonnull NSString *)message initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(BOOL))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message ? message : @"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    
    [self PApresentViewController:alertController animated:YES];
}

/** 调用JS的prompt()方法 */
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(nonnull NSString *)prompt defaultText:(nullable NSString *)defaultText initiatedByFrame:(nonnull WKFrameInfo *)frame completionHandler:(nonnull void (^)(NSString * _Nullable))completionHandler
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    [self PApresentViewController:alertController animated:YES];
}

/** webview关闭时回调 */
- (void)webViewDidClose:(WKWebView *)webView
{
    
}
- (void)PApresentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag{
    
    __weak typeof(self)weekSelf = self;
    [[UIApplication sharedApplication].keyWindow.rootViewController dismissViewControllerAnimated:YES completion:nil];
    dispatch_async(dispatch_get_main_queue(), ^{
        [weekSelf presentViewController:viewControllerToPresent animated:YES completion:nil];
    });
}

@end
