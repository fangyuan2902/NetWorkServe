//
//  NetWorkServe.h
//  GSYSClient
//
//  Created by 远方 on 2018/5/19.
//  Copyright © 2018年 远方. All rights reserved.
//

#import <Foundation/Foundation.h>

/**请求方式*/
typedef NS_ENUM(NSUInteger, RequestMethod){
    /**GET请求方式*/
    RequestMethodGET = 0,
    /**POST请求方式*/
    RequestMethodPOST
};


/**请求的Block*/
typedef void(^HttpRequest)(NSDictionary *responseObject, NSError *error);

@interface NetWorkServe : NSObject

+ (instancetype)shareInstance;

/**设置接口根路径, 设置后所有的网络访问都使用相对路径 尽量以"/"结束*/
- (void)setBaseURL:(NSString *)baseURL;

/**设置接口基本参数(如:用户ID, Token)*/
- (void)setBaseParameters:(NSDictionary *)parameters;

#pragma mark -- GET请求
- (void)GETWithURL:(NSString *)url
        parameters:(NSDictionary *)parameters
          callback:(HttpRequest)callback;

#pragma mark -- POST请求
- (void)POSTWithURL:(NSString *)url
         parameters:(NSDictionary *)parameters
           callback:(HttpRequest)callback;

#pragma mark -- 上传图片文件
- (void)uploadImageURL:(NSString *)url
            parameters:(NSDictionary *)parameters
                 image:(UIImage *)image
                  name:(NSString *)name
              progress:(void(^)(NSProgress *progress))progress
              callback:(HttpRequest)callback;

#pragma mark -- 下载文件
- (void)downloadWithURL:(NSString *)url
             parameters:(NSDictionary *)parameters
                fileDir:(NSString *)fileDir
               progress:(void(^)(NSProgress *progress))progress
               callback:(void(^)(NSString *responseObject, NSError *error))callback;

@end
