//
//  registerURLSchemes.h
//  Pkit
//
//  Created by llyouss on 2017/12/25.
//  Copyright © 2017年 llyouss. All rights reserved.
//

#import <Foundation/Foundation.h>

@class urlschemeModel;

@interface registerURLSchemes : NSObject

//目前当app跨域请求时，app提示打开的 urlschemes，该类用于映射 urlschemes 和应用信息。

/**
 存储URLSchemes主要用于识别urlschemes的来源名字

 @params URLSchemes 列表
 */

+ (void)registerURLSchemes:(NSDictionary *)URLSchemes;
+ (void)registerURLSchemeModel:(NSArray<urlschemeModel *>*)URLScheme;

/**
 需要注册的URLSchemes数据，需要时添加

 @return urlschemes 信息
 */
+ (NSDictionary *)urlschemes;

@end
