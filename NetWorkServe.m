//
//  NetWorkServe.m
//  GSYSClient
//
//  Created by 远方 on 2018/5/19.
//  Copyright © 2018年 远方. All rights reserved.
//

#import "NetWorkServe.h"
#import <AFNetworking.h>

@implementation NetWorkServe

static NSDictionary *_baseParameters;
static AFHTTPSessionManager *_sessionManager;
static NSString * _baseURL;

+ (instancetype)shareInstance {
    static NetWorkServe *netWorkServe = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        netWorkServe = [[NetWorkServe alloc] init];
        [netWorkServe initializePram];
    });
    return netWorkServe;
}

- (void)initializePram {
    _sessionManager = [AFHTTPSessionManager manager];
    _sessionManager.requestSerializer.timeoutInterval = 30.f;
    _sessionManager.responseSerializer = [AFJSONResponseSerializer serializer];
    _sessionManager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/html", @"text/json", @"text/plain", @"text/javascript", @"text/xml", @"image/*", nil];
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}

#pragma mark -- GET请求
- (void)GETWithURL:(NSString *)url
        parameters:(NSDictionary *)parameters
          callback:(HttpRequest)callback {
    [self HTTPWithMethod:RequestMethodGET url:url parameters:parameters callback:callback];
}

#pragma mark -- POST请求
- (void)POSTWithURL:(NSString *)url
         parameters:(NSDictionary *)parameters
           callback:(HttpRequest)callback {
    [self HTTPWithMethod:RequestMethodPOST url:url parameters:parameters callback:callback];
}

- (void)HTTPWithMethod:(RequestMethod)method
                   url:(NSString *)url
            parameters:(NSDictionary *)parameters
              callback:(HttpRequest)callback {
    
    url = [self transformationUrl:url];
    parameters = [self transformationPram:parameters];
    NSLog(@"\n请求参数 = %@\n请求URL = %@\n请求方式 = %ld",parameters ? parameters:@"空", url, method);
    
    [self dataTaskWithHTTPMethod:method url:url parameters:parameters callback:^(NSURLSessionDataTask * _Nonnull task, id _Nullable responseObject) {
        
        NSDictionary *dic;
        if ([responseObject isKindOfClass:[NSDictionary class]]) {
            dic = responseObject;
        } else if ([responseObject isKindOfClass:[NSData class]]) {
            dic = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableContainers error:nil];
        } else {
            dic = nil;
        }
        NSLog(@"请求结果 = %@",dic);

        callback ? callback(dic, nil) : nil;
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        NSLog(@"错误内容 = %@",error);
        callback ? callback(nil, error) : nil;
    }];
}

- (void)dataTaskWithHTTPMethod:(RequestMethod)method
                           url:(NSString *)url
                    parameters:(NSDictionary *)parameters
                      callback:(void (^)(NSURLSessionDataTask * _Nonnull, id _Nullable))callback
                       failure:(void (^)(NSURLSessionDataTask * _Nullable, NSError * _Nonnull))failure {
    
    NSURLSessionTask *sessionTask;
    if (method == RequestMethodGET) {
        sessionTask = [_sessionManager GET:url parameters:parameters progress:nil success:callback failure:failure];
    } else if (method == RequestMethodPOST) {
        sessionTask = [_sessionManager POST:url parameters:parameters progress:nil success:callback failure:failure];
    }
}

#pragma mark -- 上传图片文件
- (void)uploadImageURL:(NSString *)url
            parameters:(NSDictionary *)parameters
                 image:(UIImage *)image
                  name:(NSString *)name
              progress:(void(^)(NSProgress *progress))progress
              callback:(HttpRequest)callback {
    
    url = [self transformationUrl:url];
    parameters = [self transformationPram:parameters];
    
    [_sessionManager POST:url parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        NSData *imageData = UIImageJPEGRepresentation(image, 0.5);
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *str = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.png", str];
        [formData appendPartWithFileData:imageData
                                    name:name
                                fileName:fileName
                                mimeType:@"image/jpeg"];
    } progress:^(NSProgress * _Nonnull uploadProgress) {
        
        progress ? progress(uploadProgress) : nil;
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        callback ? callback(responseObject, nil) : nil;
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        callback ? callback(nil, error) : nil;
    }];
}

#pragma mark -- 下载文件
- (void)downloadWithURL:(NSString *)url
            parameters:(NSDictionary *)parameters
               fileDir:(NSString *)fileDir
              progress:(void(^)(NSProgress *progress))progress
              callback:(void(^)(NSString *responseObject, NSError *error))callback {
    
    url = [self transformationUrl:url];
    parameters = [self transformationPram:parameters];
    
    NSMutableURLRequest *request = [_sessionManager.requestSerializer requestWithMethod:@"POST" URLString:url parameters:parameters error:nil];
    NSURLSessionDownloadTask *downloadTask = [_sessionManager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        NSLog(@"下载进度:%.2f%%",100.0*downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        progress ? progress(downloadProgress) : nil;
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        NSString *downloadDir = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]stringByAppendingPathComponent:fileDir ? fileDir : @"Download"];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createDirectoryAtPath:downloadDir withIntermediateDirectories:YES attributes:nil error:nil];
        NSString *filePath = [downloadDir stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:filePath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {

        if (callback && error) {
            callback ? callback(nil, error) : nil;
        } else {
            callback ? callback(filePath.absoluteString, nil) : nil;
        }
    }];
    [downloadTask resume];
}

- (NSString *)transformationUrl:(NSString *)url {
    if (![url containsString:@"http"]) {
        if (_baseURL.length) {
            url = [NSString stringWithFormat:@"%@%@",_baseURL,url];
        }
    }
    return url;
}

- (NSDictionary *)transformationPram:(NSDictionary *)parameters {
    NSMutableDictionary * mutableBaseParameters = [NSMutableDictionary dictionaryWithDictionary:parameters];
    if (_baseParameters.count) {
        [mutableBaseParameters addEntriesFromDictionary:_baseParameters];
        parameters = [mutableBaseParameters copy];
    }
    return parameters;
}

/**设置接口根路径, 设置后所有的网络访问都使用相对路径*/
- (void)setBaseURL:(NSString *)baseURL {
    _baseURL = baseURL;
}

/**设置接口基本参数*/
- (void)setBaseParameters:(NSDictionary *)parameters {
    _baseParameters = parameters;
}


@end
