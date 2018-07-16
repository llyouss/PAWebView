//
//  WKJSFunction.m
//  Pkit
//
//  Created by llyouss on 2017/12/21.
//  Copyright © 2017年 llyouss. All rights reserved.
//


#import <Foundation/Foundation.h>


#pragma mark ---

#pragma mark --- JS 方法

/** 获取网页body里面的HTML*/
NSString* const JSGetHTMLFromBody =
                    @"document.body.innerHTML";

/** 获取网页body里面的HTML*/
NSString* const JSGetHTMLById =
                    @"function JSGetHTMLById(id) {\
                       return document.getElementById(id).innerHTML;\
                    }";

/** 获取链接的js方法 */
NSString* const JSSearchHrefFromHtml =
                    @"function JSSearchHref(x,y) {\
                        var e = document.elementFromPoint(x, y);\
                        while(e){\
                            if(e.href){\
                            return e.href;\
                        }\
                        e = e.parentElement;\
                        }\
                        return e.href;\
                    }";

/** 抓取文本标题 */
NSString* const JSSearchTextTitleFromHtml =
                   @"function JSSearchText(x,y) {"
                        "return document.elementFromPoint(x, y).innerText;"
                    "}";

/** 获取链接的js方法 */
NSString* const JSSearchTextTypeFromHtml =
                   @"function JSSearchTextType(x,y) {"
                        "return document.elementFromPoint(x, y).tagName;"
                    "}";

/** 获取图片链接的js方法 */
NSString* const JSSearchImageFromHtml =
                    @"function JSSearchImage(x,y) {"
                        "return document.elementFromPoint(x, y).src;"
                    "}";

/** 获取HTML所有的图片 */
NSString* const JSSearchAllImageFromHtml =
                   @"function JSSearchAllImage(){"
                        "var img = [];"
                        "for(var i=0;i<$(\"img\").length;i++){"
                            "if(parseInt($(\"img\").eq(i).css(\"width\"))> 60){ "//获取所有符合放大要求的图片，将图片路径(src)获取
                               " img[i] = $(\"img\").eq(i).attr(\"src\");"
                           " }"
                        "}"
                        "var img_info = {};"
                        "img_info.list = img;" //保存所有图片的url
                        "return img;"
                    "}";

/** 获取web page宽 */
NSString* const JSGetWebPageWidth =
                    @"document.getElementById('content').offsetWidth";

/** 获取web page高 */
NSString* const JSGetWebPageHeight =
                    @"document.getElementById('content').offsetHeight";


/** 设置web page尺寸 */
NSString* const JSSetWebPageWidth =
                    @"function JSSetWebPageWidth(wid) {\
                         document.querySelector('meta[name=viewport]').setAttribute('content',\
                        'width=wid;', false); \
                    }";

/** 设置web page字体大小 */
NSString* const JSSetFontSize =
                    @"function JSSetFontSize(size) {\
                        document.getElementsByTagName('body')[0].style.webkitTextSizeAdjust= size\
                    }";

/** 设置web page字体大小 */
NSString* const JSRemoveAllLink =
                    @"$(document).ready(function () {$('a').removeAttr('href');})";

/** 替换所有的href */
NSString* const JSReplaceAllHref =
                    @"function JSReplaceAllLinkWithUrlString(url) {\
                        $(document).ready(function () {$('a').setAttribute('href',url);})\
                    }";

/** 通过id替换元素的href */
NSString* const JSReplaceURLStringById =
                    @"function JSSetURLString(id,url) {\
                        document.getElementById(id).setAttribute('href',url);\
                    }";

/** 通过手势位置替换元素的href */
NSString* const JSReplaceURLStringByLongPress =
                    @"function JSSetURLStringByLongPress(x,y,url) {\
                        document.elementFromPoint(x, y).setAttribute('href',url);\
                    }";

/** 通过id替换元素的href */
NSString* const JSReplaceImageById =
                    @"function JSReplaceImageById(id,url) {\
                        document.getElementById(id).src = url;\
                    }";

/** 通过手势位置替换图片 */
NSString* const JSReplaceImageByLongPress =
                    @"function JSSetURLStringByLongPress(x,y,url) {\
                        document.elementFromPoint(x, y).setAttribute('src',url);\
                    }";


#pragma mark --

#pragma mark -- 点击事件相关操作


/** 提交表单事件 */
NSString* const JSSubmitForms =
                    @"document.forms[0].submit();";

/** 取消点击事件 */
NSString* const JSFunctionAddEventCanal =
                    @"function JSAddEventCanal(x,y) {\
                        var e = document.elementFromPoint(x, y);\
                        var num = 0;\
                        while(e){\
                            if(num>5)return;\
                            num++;\
                            e.addEventListener('click',function(e) {\
                                if ( e && e.preventDefault )\
                                e.preventDefault();\
                                else\
                                window.event.returnValue = false;\
                                return false;\
                            },false);\
                            e = e.parentElement;\
                        }\
                    }";

/* 移除忽略事件 */
NSString* const JSFunctionRemoveEventCanal =
                @"function JSRemoveEventCanal(x,y) {\
                    var e = document.elementFromPoint(x, y);\
                    var num = 0;\
                    while(e){\
                        if(num > 5)return;\
                        num++;\
                        e.addEventListener('click',PAEventIgnore,false);\
                        e = e.parentElement;\
                    }\
                }";

/* 忽略事件方法 */
NSString* const JSFunctionEventIgnore =
                @"function PAEventIgnore(e) {\
                    if ( e && e.preventDefault )\
                    e.preventDefault();\
                    else\
                    window.event.returnValue = false;\
                    return false;\
                    }\
                }";















