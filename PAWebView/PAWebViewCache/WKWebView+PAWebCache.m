//
//  WKWebView+PAWebCache.m
//  Pkit
//
//  Created by llyouss on 2017/12/28.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import "WKWebView+PAWebCache.h"
#import "UIAlertController+WKWebAlert.h"

@implementation WKWebView (PAWebCache)

#pragma mark - private method
//拿到当前北京时间
- (NSDate *)beijingTime {
    NSDate *date = [NSDate date];
    NSTimeInterval inter = [[NSTimeZone systemTimeZone] secondsFromGMT];
    return  [date dateByAddingTimeInterval:inter];
}

#pragma mark - 清除webView缓存
- (void)deleteAllWebCache
{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 9.0) {
        NSSet *websiteDataTypes = [NSSet setWithArray:
                                   @[WKWebsiteDataTypeDiskCache,
                                     WKWebsiteDataTypeOfflineWebApplicationCache,
                                     WKWebsiteDataTypeMemoryCache,
                                     WKWebsiteDataTypeLocalStorage,
                                     //WKWebsiteDataTypeCookies,
                                     WKWebsiteDataTypeSessionStorage,
                                     WKWebsiteDataTypeIndexedDBDatabases,
                                     WKWebsiteDataTypeWebSQLDatabases
                                     ]];
        //// All kinds of data
        //NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        //// Date from
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        //// Execute
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            [UIAlertController PAlertWithTitle:@"提示" message:@"缓存清理完成" completion:nil];
        }];
    } else {
        NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *cookiesFolderPath = [libraryPath stringByAppendingString:@"/Cookies"];
        NSError *errors;
        [[NSFileManager defaultManager] removeItemAtPath:cookiesFolderPath error:&errors];
        if (!errors) {
            [UIAlertController PAlertWithTitle:@"提示" message:@"缓存清理完成" completion:nil];
        }else
        {
            [UIAlertController PAlertWithTitle:@"提示" message:@"缓存清理失败" completion:nil];
        }
    }
}


/** 清理缓存的方法，这个方法会清除缓存类型为HTML类型的文件*/
- (void)clearHTMLCache
{
    /* 取得Library文件夹的位置*/
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,NSUserDomainMask, YES)[0];
    /* 取得bundle id，用作文件拼接用*/
    NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary]objectForKey:@"CFBundleIdentifier"];
    /*
     * 拼接缓存地址，具体目录为App/Library/Caches/你的APPBundleID/fsCachedData
     */
    NSString *webKitFolderInCachesfs = [NSString stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
    
    NSError *error;
    /* 取得目录下所有的文件，取得文件数组*/
    NSFileManager *fileManager = [NSFileManager defaultManager];
    //    NSArray *fileList = [[NSArray alloc] init];
    //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
    NSArray *fileList = [fileManager contentsOfDirectoryAtPath:webKitFolderInCachesfs error:&error];
    /* 遍历文件组成的数组*/
    for(NSString * fileName in fileList){
        /* 定位每个文件的位置*/
        NSString * path = [[NSBundle bundleWithPath:webKitFolderInCachesfs] pathForResource:fileName ofType:@""];
        /* 将文件转换为NSData类型的数据*/
        NSData * fileData = [NSData dataWithContentsOfFile:path];
        /* 如果FileData的长度大于2，说明FileData不为空*/
        if(fileData.length >2){
            /* 创建两个用于显示文件类型的变量*/
            int char1 =0;
            int char2 =0;
            
            [fileData getBytes:&char1 range:NSMakeRange(0,1)];
            [fileData getBytes:&char2 range:NSMakeRange(1,1)];
            /* 拼接两个变量*/
            NSString *numStr = [NSString stringWithFormat:@"%i%i",char1,char2];
            /* 如果该文件前四个字符是6033，说明是Html文件，删除掉本地的缓存*/
            if([numStr isEqualToString:@"6033"]){
                [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@/%@",webKitFolderInCachesfs,fileName]error:&error];
                continue;
            }
        }
    }
}

@end
