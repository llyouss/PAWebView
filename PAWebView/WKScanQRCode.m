//
//  WKScanQRCode.m
//  Pkit
//
//  Created by llyouss on 2017/12/20.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import "WKScanQRCode.h"
#import <Photos/Photos.h>
#import <WebKit/WKWebView.h>
#import "UIAlertController+WKWebAlert.h"

FOUNDATION_EXPORT NSString *const NotiName_LoadRequest;
FOUNDATION_EXPORT NSString *const Key_LoadQRCodeUrl;
FOUNDATION_EXPORT NSString *const JSSearchHrefFromHtml;  //抓取链接的JS方法
FOUNDATION_EXPORT NSString* const JSSearchImageFromHtml; //抓取图片

@implementation WKScanQRCode

+ (instancetype)shareInstance
{
    static WKScanQRCode *tapQRCode = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tapQRCode = [[WKScanQRCode alloc]init];
    });
    return tapQRCode;
}

/**
 添加长按手势
 @param webView 监听对象
 */
- (void)addGestureRecognizerObserverWebElementsWithWebView:(WKWebView *)webView
{
    self.observerView = webView;
    
    //长按识别图中的二维码，类似于微信里面的功能,前提是当前页面必须有二维码
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(startLongPress:)];
    longPress.delegate = self;
    longPress.minimumPressDuration = 0.5f;
    longPress.numberOfTouchesRequired = 1;
    longPress.cancelsTouchesInView = YES;
    [self.observerView addGestureRecognizer:longPress];
}

/** 手势精确识别，防止误操作 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }else{
        return NO;
    }
}

/** 长按识别代理 */
- (void)startLongPress:(UILongPressGestureRecognizer *)pressSender
{
    if(pressSender.state == UIGestureRecognizerStateBegan){
        
        [self detectQRCodeInWebView:pressSender];
        NSLog(@"1. 开始长按手势");
    }else if(pressSender.state == UIGestureRecognizerStateEnded){
        
        //可以添加你长按手势执行的方法,不过是在手指松开后执行
        NSLog(@"2. 结束长按手势");
    }else if(pressSender.state == UIGestureRecognizerStateChanged){
        
        //在手指点下去一直不松开的状态执行
        NSLog(@"3. 长按手势改变");
    }
}

/** 检测图片 */
- (void)detectQRCodeInWebView:(UILongPressGestureRecognizer *)pressSender
{
    CGPoint touchPoint = [pressSender locationInView:self.observerView];
    
    //获取长按位置对应的图片url的JS代码
    NSString *imgJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).src", touchPoint.x, touchPoint.y];
    NSString *titleJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).innerText", touchPoint.x, touchPoint.y];
    
    //判断是否是标题还是文章
    NSString * typeJS = [NSString stringWithFormat:@"document.elementFromPoint(%f, %f).tagName", touchPoint.x, touchPoint.y];
    
    // 执行对应的JS代码 获取url
    __block NSString *imgUrlString;
    __weak typeof(self)weekSelf = self;
    
    //抓取image
    [self.observerView evaluateJavaScript:imgJS completionHandler:^(id _Nullable imgUrl, NSError * _Nullable error)
     {
         __strong typeof(self)strongSelf = weekSelf;
         imgUrlString = imgUrl;
         
         //抓取title
         [strongSelf.observerView evaluateJavaScript:titleJS completionHandler:^(id _Nullable title, NSError * _Nullable error)
          {
              //抓取title的类型
              [strongSelf.observerView evaluateJavaScript:typeJS completionHandler:^(id _Nullable t, NSError * _Nullable error) {
                  
                  //抓取href
                  [self hrefFromJSPointX:touchPoint.x ppintY:touchPoint.y callBack:^(NSString *hre) {

                    [self showActionWithImage:imgUrlString href:hre title:title type:t];
              }];
          }];
     }];
}];
}

/** 抓取链接 */
- (void)hrefFromJSPointX:(float)x ppintY:(float)y callBack:(void(^)(NSString *hre))callback
{
    //注入JS方法
    NSString *hrefJS = JSSearchHrefFromHtml;
    [self.observerView evaluateJavaScript:hrefJS completionHandler:nil];
    
    //调用JS方法
    NSString *hrefFunc = [NSString stringWithFormat:@"JSSearchHref(%f,%f);",x,y];
    [self.observerView evaluateJavaScript:hrefFunc completionHandler:^(id _Nullable href, NSError * _Nullable error)
    {
        callback?callback(href):NULL;
    }];
}

/** 弹出检测出来的信息 */
- (void)showActionWithImage:(NSString *)imageUrl href:(NSString *)href title:(NSString *)title type:(NSString *)t
{
        NSString *type = t;
        NSString *innerTitle = title;
        NSString *imgUrlString = imageUrl;
        if ((!imageUrl || [imageUrl isEqualToString:@""] ||
             !([imgUrlString.lowercaseString containsString:@".jpg"] ||
               [imgUrlString.lowercaseString containsString:@".jpeg"]||
               [imgUrlString.lowercaseString containsString:@".png"] ||
               [imgUrlString.lowercaseString containsString:@".gif"]))
            && (innerTitle.length <= 0))
        {
            return;
        }
        
        //长按操作
        UIAlertController *showActionTip =
        [UIAlertController alertControllerWithTitle:nil
                                            message:nil
                                     preferredStyle:UIAlertControllerStyleActionSheet];
        
        //识别二维码
        NSURL *url = [self detectQRCode:self.observerView];
        UIAlertAction *ActionSacn = [UIAlertAction actionWithTitle:@"识别二维码"
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action)
                                     {
                                            [[NSNotificationCenter defaultCenter] postNotificationName:NotiName_LoadRequest object:nil userInfo:@{Key_LoadQRCodeUrl:url.absoluteString}];
                                     }];
        //下载图片
        UIAlertAction *ActionloadImage = [UIAlertAction actionWithTitle:@"保存图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self LoadImageFromURL:[NSURL URLWithString:imgUrlString]];
        }];
        //下载图片
        UIAlertAction *ActionCopyImageLink = [UIAlertAction actionWithTitle:@"复制图片链接" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [UIPasteboard generalPasteboard].string = imgUrlString;
        }];
        
        //分享图片
        UIAlertAction *ActionShareImage = [UIAlertAction actionWithTitle:@"分享图片" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"补充分享");
        }];
        
        //复制标题
        UIAlertAction *ActionCopyInnerTitle = [UIAlertAction actionWithTitle:@"复制链接文字" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [UIPasteboard generalPasteboard].string = innerTitle;
        }];
    
        //复制链接地址
        UIAlertAction *ActionCopyHref = [UIAlertAction actionWithTitle:@"复制链接地址" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [UIPasteboard generalPasteboard].string = href;
        }];
    
        
        //取消
        UIAlertAction *Canel = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }];
    
        //添加图片相关的操作
        if ([imgUrlString.lowercaseString containsString:@".jpg"] ||
            [imgUrlString.lowercaseString containsString:@".jpeg"]||
            [imgUrlString.lowercaseString containsString:@".png"] ||
            [imgUrlString.lowercaseString containsString:@".gif"])
        {
            [showActionTip addAction:ActionloadImage];
            [showActionTip addAction:ActionShareImage];
            if (url) {
                [showActionTip addAction:ActionSacn];
            }
            [showActionTip addAction:ActionCopyImageLink];
        }
    
        //添加链接复制操作
        if (href) {
            [showActionTip addAction:ActionCopyHref];
        }
        //添加标题相关的操作
        if (innerTitle.length > 0 && [type.lowercaseString containsString:@"h"]) {
            [showActionTip addAction:ActionCopyInnerTitle];
        }
    
        //添加取消操作
        [showActionTip addAction:Canel];
        if (showActionTip.actions.count == 1) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:showActionTip animated:YES completion:nil];
        });
    
}

/** 识别二维码 */
- (NSURL *)detectQRCode:(UIView *)fview
{
    //截图 再读取
    UIGraphicsBeginImageContextWithOptions(self.observerView.bounds.size, YES, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    [fview.layer renderInContext:context];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CIImage *ciImage = [[CIImage alloc] initWithCGImage:image.CGImage options:nil];
    
    //渲染
    CIContext *ciContext = [CIContext contextWithOptions:@{kCIContextUseSoftwareRenderer : @(YES)}];
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:ciContext options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];// 二维码识别
    NSArray *features = [detector featuresInImage:ciImage];
    
    for (CIQRCodeFeature *feature in features) {
        
        NSURL * url = [NSURL URLWithString: feature.messageString];
        if (url) return url;
    }
    return nil;
}

/** 下载图片 */
- (void)LoadImageFromURL:(NSURL *)URLString
{
    NSData *data = [NSData dataWithContentsOfURL:URLString];
    UIImage *image = [UIImage imageWithData:data];
    if (!image) {
        [UIAlertController PAlertWithTitle:@"提示" message:@"下载失败" completion:nil];
        return;
    }
    [self SaveImageFinished:image];
}

/** 保存图片到相册 */
- (void)SaveImageFinished:(UIImage *)image
{
    if (!image) {
        [UIAlertController PAlertWithTitle:@"提示" message:@"下载失败" completion:nil];
        return;
    }
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        
        //写入图片到相册
        [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
    } completionHandler:^(BOOL success, NSError * _Nullable error) {
        if (success)
        {
            [UIAlertController PAlertWithTitle:@"提示" message:@"已经保存到相册" completion:nil];
        }else
        {
            [UIAlertController PAlertWithTitle:@"提示" message:@"保存失败" completion:nil];
        }
    }];
}


@end
