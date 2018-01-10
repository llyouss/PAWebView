//
//  WKJSFunction.m
//  Pkit
//
//  Created by llyouss on 2017/12/21.
//  Copyright © 2017年 llyouss. All rights reserved.
//


#import <Foundation/Foundation.h>

#pragma mark --- JS 方法

/** 获取链接的js方法 */
NSString* const JSSearchHrefFromHtml =
                   @"function JSSearchHref(x,y) {"
                    "var e = document.elementFromPoint(x, y);"
                    "while(e){"
                    "if(e.href){"
                    "return e.href;"
                    "}"
                    "e = e.parentElement;"
                    "}"
                    "return e.href;"
                    "}";

/** 获取图片链接的js方法 */
NSString* const JSSearchImageFromHtml =
                    @"function JSSearchImage(x,y) {"
                     "return document.elementFromPoint(x, y).src;"
                     "}";

/** 抓取文本标题 */
NSString* const JSSearchTextFromHtml =
                   @"function JSSearchText(x,y) {"
                    "return document.elementFromPoint(x, y).innerText;"
                    "}";

/** 获取链接的js方法 */
NSString* const JSSearchTextTypeFromHtml =
                   @"function JSSearchTextType(x,y) {"
                    "return document.elementFromPoint(x, y).tagName;"
                    "}";


/** 获取HTML所有的图片 */
NSString* const JSSearchAllImageFromHtml =
                   @"function JSSearchAllImage(){"
                        "var img = [];"
                        "for(var i=0;i<$(\"img\").length;i++){"
                            "if(parseInt($(\"img\").eq(i).css(\"width\"))>20){ "//获取所有符合放大要求的图片，将图片路径(src)获取
                               " img[i] = $(\"img\").eq(i).attr(\"src\");"
                           " }"
                        "}"
                        "var img_info = {};"
                        "img_info.list = img;" //保存所有图片的url
                        "return img;"
                    "}";












