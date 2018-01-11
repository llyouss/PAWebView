//
//  registerURLSchemes.m
//  Pkit
//
//  Created by llyouss on 2017/12/25.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import "registerURLSchemes.h"
#import "urlschemeModel.h"

@implementation registerURLSchemes

+ (NSString *)urlSchemesPath
{
    NSString *path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return   path = [path stringByAppendingPathComponent:@"appURLSchemes"];
}

+ (void)registerURLSchemes:(NSDictionary *)URLSchemes
{
    NSString *path = [self urlSchemesPath];
    [URLSchemes writeToFile:path atomically:YES];
}

+ (void)registerURLSchemeModel:(NSArray <urlschemeModel *>*)URLScheme
{
    NSMutableDictionary *contantDic = [NSMutableDictionary dictionary];
    
    for (urlschemeModel *model in URLScheme) {
        
        NSMutableDictionary *subDic = [NSMutableDictionary dictionary];
        [subDic setValue:model.appstoreURL forKey:@"url"];
        [subDic setValue:model.appid forKey:@"id"];
        [subDic setValue:model.displayName forKey:@"name"];
        
        [contantDic setObject:subDic forKey:model.scheme];
    }
    
    [self registerURLSchemes:contantDic];
}

+ (NSDictionary *)urlschemes
{
    /** 把该信息注册到 info plist 列表 */
    NSDictionary * mainUrlschemes = @{
             @"weixin":@{
                    @"url":@"https://itunes.apple.com/cn/app/id414478124?mt=8",
                    @"id":@"414478124",
                    @"name":@"微信",
                        },
             @"wechat":@{
                     @"url":@"https://itunes.apple.com/cn/app/id414478124?mt=8",
                     @"id":@"414478124",
                     @"name":@"微信",
                     },
             @"alipay":@{
                     @"url":@"https://itunes.apple.com/cn/app/id333206289?mt=8",
                     @"id":@"333206289",
                     @"name":@"支付宝",
                     },
             @"alipayshare":@{
                     @"url":@"https://itunes.apple.com/cn/app/id333206289?mt=8",
                     @"id":@"333206289",
                     @"name":@"支付宝",
                     },
             @"taobao":@{
                     @"url":@"https://itunes.apple.com/cn/app/id387682726?mt=8",
                     @"id":@"387682726",
                     @"name":@"淘宝",
                     },
             @"mqq":@{
                     @"url":@"https://itunes.apple.com/cn/app/id444934666?mt=8",
                     @"id":@"444934666",
                     @"name":@"QQ",
                     },
             @"mqqapi":@{
                     @"url":@"https://itunes.apple.com/cn/app/id444934666?mt=8",
                     @"id":@"444934666",
                     @"name":@"QQ",
                     },
             @"mqzone":@{
                     @"url":@"https://itunes.apple.com/cn/app/id444934666?mt=8",
                     @"id":@"444934666",
                     @"name":@"QQ",
                     },
             @"mqqwpa":@{
                     @"url":@"https://itunes.apple.com/cn/app/id444934666?mt=8",
                     @"id":@"444934666",
                     @"name":@"QQ",
                     },
             @"mqqapi":@{
                     @"url":@"https://itunes.apple.com/cn/app/id444934666?mt=8",
                     @"id":@"444934666",
                     @"name":@"QQ",
                     },
             @"BaiduSSO":@{
                     @"url":@"https://itunes.apple.com/cn/app/id382201985?mt=8",
                     @"id":@"382201985",
                     @"name":@"百度",
                     },
             @"ucbrowser":@{
                     @"url":@"https://itunes.apple.com/cn/app/id527109739?mt=8",
                     @"id":@"527109739",
                     @"name":@"UC浏览器",
                     },
             @"bdmap":@{
                     @"url":@"https://itunes.apple.com/cn/app/id452186370?mt=8",
                     @"id":@"452186370",
                     @"name":@"百度地图",
                     },
             @"snssdk141":@{
                     @"url":@"https://itunes.apple.com/cn/app/id529092160?mt=8",
                     @"id":@"529092160",
                     @"name":@"今日头条",
                     },
             @"imeituan":@{
                     @"url":@"https://itunes.apple.com/cn/app/id423084029?mt=8",
                     @"id":@"414245413",
                     @"name":@"美团",
                     },
             @"openapp.jdmoble":@{
                     @"url":@"https://itunes.apple.com/cn/app/id414245413?mt=8",
                     @"id":@"414245413",
                     @"name":@"京东",
                     },
             @"VSSpecialSwitch":@{
                     @"url":@"https://itunes.apple.com/cn/app/id417200582?mt=8",
                     @"id":@"417200582",
                     @"name":@"唯品会",
                     },
             @"dianping":@{
                     @"url":@"https://itunes.apple.com/cn/app/id351091731?mt=8",
                     @"id":@"351091731",
                     @"name":@"大众点评",
                     },
             @"sinaweibo":@{
                     @"url":@"https://itunes.apple.com/cn/app/id350962117?mt=8",
                     @"id":@"350962117",
                     @"name":@"微博",
                     },
             @"weibosdk2.5":@{
                     @"url":@"https://itunes.apple.com/cn/app/id350962117?mt=8",
                     @"id":@"350962117",
                     @"name":@"微博",
                     },
             @"weibosdk":@{
                     @"url":@"https://itunes.apple.com/cn/app/id350962117?mt=8",
                     @"id":@"350962117",
                     @"name":@"微博",
                     },
             @"sinaweibosso":@{
                     @"url":@"https://itunes.apple.com/cn/app/id350962117?mt=8",
                     @"id":@"350962117",
                     @"name":@"微博",
                     },
             @"sinaweibohd":@{
                     @"url":@"https://itunes.apple.com/cn/app/id350962117?mt=8",
                     @"id":@"350962117",
                     @"name":@"微博",
                     },
             @"diditaxi":@{
                     @"url":@"https://itunes.apple.com/cn/app/id554499054?mt=8",
                     @"id":@"554499054",
                     @"name":@"滴滴打车",
                     },
             @"kugouURL":@{
                     @"url":@"https://itunes.apple.com/cn/app/id472208016?mt=8",
                     @"id":@"472208016",
                     @"name":@"酷狗音乐",
                     },
             @"qqmusic":@{
                     @"url":@"https://itunes.apple.com/cn/app/id472208016?mt=8",
                     @"id":@"472208016",
                     @"name":@"酷狗音乐",
                     },
             @"zhihu":@{
                     @"url":@"https://itunes.apple.com/cn/app/%E7%9F%A5%E4%B9%8E-%E5%8F%91%E7%8E%B0%E6%9B%B4%E5%A4%A7%E7%9A%84%E4%B8%96%E7%95%8C/id432274380?mt=8",
                     @"id":@"432274380",
                     @"name":@"知乎",
                     },
             };
    
     NSMutableDictionary *urlschemesDic = [NSMutableDictionary dictionaryWithDictionary:mainUrlschemes];
     NSString *path = [self urlSchemesPath];
     NSDictionary *registerURLSchemes = [NSDictionary dictionaryWithContentsOfFile:path];
     [urlschemesDic addEntriesFromDictionary:registerURLSchemes];
    
    return urlschemesDic;
}

/*

添加到plist列表

<key>LSApplicationQueriesSchemes</key>
<array>
<!-- 微信 URL Scheme 白名单-->
<string>wechat</string>
<string>weixin</string>

<!-- 新浪微博 URL Scheme 白名单-->
<string>sinaweibohd</string>
<string>sinaweibo</string>
<string>sinaweibosso</string>
<string>weibosdk</string>
<string>weibosdk2.5</string>

<!-- QQ、Qzone URL Scheme 白名单-->
<string>mqqapi</string>
<string>mqq</string>
<string>mqqOpensdkSSoLogin</string>
<string>mqqconnect</string>
<string>mqqopensdkdataline</string>
<string>mqqopensdkgrouptribeshare</string>
<string>mqqopensdkfriend</string>
<string>mqqopensdkapi</string>
<string>mqqopensdkapiV2</string>
<string>mqqopensdkapiV3</string>
<string>mqzoneopensdk</string>
<string>wtloginmqq</string>
<string>wtloginmqq2</string>
<string>mqqwpa</string>
<string>mqzone</string>
<string>mqzonev2</string>
<string>mqzoneshare</string>
<string>wtloginqzone</string>
<string>mqzonewx</string>
<string>mqzoneopensdkapiV2</string>
<string>mqzoneopensdkapi19</string>
<string>mqzoneopensdkapi</string>
<string>mqzoneopensdk</string>

<!-- 支付宝  URL Scheme 白名单-->
<string>alipay</string>
<string>alipayshare</string>
<string>taobao</string>
 
<!-- 美团  URL Scheme 白名单-->
<string>imeituan</string>

<!-- 百度 URL Scheme 白名单-->
<string>BaiduSSO</string>
<string>bdmap</string>
 
<!-- UC URL Scheme 白名单-->
<string>ucbrowser</string>
 
<!-- 今日头条 URL Scheme 白名单-->
<string>snssdk141</string>
 
<!-- 京东 URL Scheme 白名单-->
<string>openapp.jdmoble</string>

<!-- 滴滴 URL Scheme 白名单-->
<string>diditaxi</string>

<!-- 酷狗 URL Scheme 白名单-->
<string>kugouURL</string>

<!-- qq音乐 URL Scheme 白名单-->
<string>qqmusic</string>

<!-- 知乎 URL Scheme 白名单-->
<string>zhihu</string>

</array>
 
 */

@end
