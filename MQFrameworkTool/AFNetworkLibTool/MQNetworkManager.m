//
//  MQNetworkManager.m
//  MQFrameworkTool
//
//  Created by mengJing on 2018/7/11.
//  Copyright © 2018年 mengJing. All rights reserved.
//

#import "MQNetworkManager.h"
#import <AFNetworking/AFNetworking.h>

#import <AVFoundation/AVAsset.h>
#import <AVFoundation/AVAssetExportSession.h>

#import "UIImage+compressIMG.h"

#define kBaseUrl @""

@implementation MQNetworkManager

+ (NSString *)requestUrlWithApi:(NSString *)api {
    return [NSString stringWithFormat:@"%@%@", kBaseUrl, api];
}

+ (AFHTTPSessionManager *)httpSessionManager {
    static AFHTTPSessionManager *manager;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        manager = [[AFHTTPSessionManager alloc] init];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"text/json", @"text/javascript", @"text/html", @"text/plain", nil];
//        manager.responseSerializer.acceptableContentTypes = [manager.responseSerializer.acceptableContentTypes setByAddingObject:@"text/html"]; // @"text/html" && @"text/plain"
    
        // 请求/响应的序列化器 (传json, 传 http: AFHTTPResponseSerializer)
        manager.requestSerializer = [AFHTTPRequestSerializer serializer];
        AFJSONResponseSerializer * response = [AFJSONResponseSerializer serializer];
        response.removesKeysWithNullValues = YES; // 去除空值
        manager.responseSerializer = response; // 默认JSON
        //        manager.responseSerializer = [AFJSONResponseSerializer serializerWithReadingOptions:NSJSONReadingMutableContainers]; // 允许返回的结果可改(例:自己的错误码)。
        
        manager.requestSerializer.timeoutInterval = 30;
        manager.requestSerializer.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData; // 缓存策略
        manager.securityPolicy.allowInvalidCertificates = YES; // 是否信任带有一个无效或者过期的SSL证书的服务器，默认不信任。
        manager.securityPolicy.validatesDomainName = NO;// 是否验证域名的CN字段（不是必须的，但是如果写YES，则必须导入证书）
        
        [manager.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    });
    
    return manager;
}


//+ (instancetype)shareManager {
//    static MQNetworkManager * instance = nil;
//    static dispatch_once_t onceToken;
//    dispatch_once(&onceToken, ^{
//        // 设置BaseURL
//        instance = [[self alloc] initWithBaseURL:[NSURL URLWithString:kBaseUrl]];
//    });
//    
//    return instance;
//}

/** Get / Post 请求 */
+ (void)requestWithType:(MQHttpRequestType)requestType url:(NSString *)urlString parameters:(id)parameters success:(requestSuccess)successBlock failure:(requestFailure)failureBlock{

    
    [MQNetworkManager requestWithType:requestType url:urlString parameters:parameters progress:nil success:successBlock failure:failureBlock];
}

/** Get / Post 请求, progress */
+ (void)requestWithType:(MQHttpRequestType)requestType url:(NSString *)urlString parameters:(id)paraments progress:(httpProgress)progress success:(requestSuccess)successBlock failure:(requestFailure)failureBlock {
    
    // 防止URL字符串中含有中文或特殊字符发生崩溃
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    AFHTTPSessionManager *manager = [MQNetworkManager httpSessionManager];
    if (requestType == MQHttpRequestTypeGet) {
        [manager GET:[MQNetworkManager requestUrlWithApi:urlString] parameters:paraments progress:^(NSProgress * _Nonnull downloadProgress) {
            
            if (progress) {
                progress(downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
            }
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            NSLog(@"statusCode=%ld",response.statusCode);
            
            successBlock(responseObject);
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            //        NSError *underError = error.userInfo[@"NSUnderlyingError"];
            //
            //        NSData *data=underError.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            //
            //        NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            //        NSLog(@"%@",str);
            
            NSData *data = error.userInfo[AFNetworkingOperationFailingURLResponseDataErrorKey];
            if (data != nil) {
//            id body = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
                NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                NSLog(@"error--%@", str); //就可以获取到错误时返回的body信息。
            }

            
            if (failureBlock) {
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                //        response.statusCode
                //        response.allHeaderFields[@"Error_Code"];
                NSInteger errorCode = [response.allHeaderFields[@"Error_Code"] integerValue];
                NSLog(@"errorCode=%ld",errorCode);
                failureBlock(error);
            }
            
        }];
        
    }else if (requestType == MQHttpRequestTypePost) {
        [manager POST:[MQNetworkManager requestUrlWithApi:urlString] parameters:paraments progress:^(NSProgress * _Nonnull uploadProgress) {
            
            progress(uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
            
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            NSLog(@"statusCode=%ld",response.statusCode);
            
            successBlock(responseObject);
            
        } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            
            if (failureBlock) {
                NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                //        response.statusCode
                //        response.allHeaderFields[@"Error_Code"];
                NSInteger errorCode = [response.allHeaderFields[@"Error_Code"] integerValue];
                NSLog(@"errorCode=%ld",errorCode);
                failureBlock(error);
            }
            
        }];
    }
}

/**
 * 文件上传:多张图片上传
 *
 * @param urlString          上传的url
 * @param parameters         上传图片预留参数---(可移除,可为nil)
 * @param imageArray         上传的图片数组
 * @param width              图片要被压缩到的宽度
 * @param progress     上传进度
 *
 
 理解:文件上传（图片、视频） : 都使用formData来拼接数据
 注解：formData(请求体)来拼接数据 appendPartWithFile
 FileData: 二进制数据 要上传的文件参数
 name:     服务器规定的 @"file"
 fileName: 该文件上传到服务器保存名称
 mimeType: 文件的类型 image/png(MIMEType:大类型/小类型)
 
 // 第一种方式
 UIImage *image = [UIImage imageNamed:@"Codeidea.png"];
 NSData *imageData = UIImagePNGRepresentation(image);
 [formData appendPartWithFileData:imageData name:@"file" fileName:@"xxxx.png" mimeType:@"image/png"];
 
 // 第二种方式
 [formData appendPartWithFileURL:[NSURL fileURLWithPath:@" "] name:@"file" fileName:@"123.png" mimeType:@"image/png" error:nil];
 
 // 第三种方式
 [formData appendPartWithFileURL:[NSURL fileURLWithPath:@" "] name:@"file" error:nil];
 */
+ (void)uploadFileWithURL:(NSString *)urlString parameters:(id)parameters imageArray:(NSArray *)imageArray targetWidth:(CGFloat)width uploadProgress:(httpProgress)progress success:(requestSuccess)successBlock failure:(requestFailure)failureBlock {
    
    // 防止URL字符串中含有中文或特殊字符发生崩溃
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    AFHTTPSessionManager *manager = [MQNetworkManager httpSessionManager];
    
    [manager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
        
        int i = 0;
        for (UIImage *image in imageArray) {
            // image分类方法, 压缩图片
            UIImage * resizedImage = [UIImage IMGCompressed:image targetWidth:width];
            NSData * imageData = UIImagePNGRepresentation(resizedImage);
            
            // 拼接Data
            [formData appendPartWithFileData:imageData name:@"file" fileName:[NSString stringWithFormat:@"picture%d",i] mimeType:@"image/png"];
            
            //[formData appendPartWithFileURL:[NSURL fileURLWithPath:@" "] name:@"file" fileName:[NSString stringWithFormat:@"picture%d.png",i] mimeType:@"image/png" error:nil];
            
            //[formData appendPartWithFileURL:[NSURL fileURLWithPath:@" "] name:@"file" error:nil];
            
            i++;
        }
        
    } progress:^(NSProgress * _Nonnull uploadProgress) {
    
        if (progress) {
            progress(1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
        }
        
    } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        
        if (successBlock) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            NSLog(@"statusCode=%ld",response.statusCode);
            
            successBlock(responseObject);
        }
        
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        if (failureBlock) {
            NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
            //        response.statusCode
            //        response.allHeaderFields[@"Error_Code"];
            NSInteger errorCode = [response.allHeaderFields[@"Error_Code"] integerValue];
            NSLog(@"errorCode=%ld",errorCode);
            failureBlock(error);
        }
        
    }];
}

/**
 *  文件下载
 *
 *  @param urlString    请求的url
 *  @param parameters   文件下载预留参数---(可移除,可为nil)
 *  @param savePath     下载文件保存路径
 *  @param progress     下载文件的进度显示
 */
+ (void)downLoadFileWithURL:(NSString *)urlString parameters:(id)parameters savePath:(NSString *)savePath downLoadProgress:(httpProgress)progress completionHandler:(completionHandler)completionHandler {
    
    // 防止URL字符串中含有中文或特殊字符发生崩溃
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]];
    
    AFHTTPSessionManager *manager = [MQNetworkManager httpSessionManager];
    
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        
        if (progress) {
            progress(downloadProgress.completedUnitCount / downloadProgress.totalUnitCount);
        }
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        
        if (savePath) {
            return [NSURL URLWithString:savePath];
        }
        // 指定存储路径fullPath, targetPath临时路径
        NSString * fullPath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject stringByAppendingPathComponent:response.suggestedFilename];
        return [NSURL fileURLWithPath:fullPath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        
        if (completionHandler) {
            completionHandler(filePath, error);
        }
    }];
    [task resume];
}

/**
 *  视频上传
 *
 *  @param urlString     上传的url
 *  @param parameters   上传视频预留参数---(可移除,可为nil)
 *  @param videoPath    上传视频的本地沙河路径
 *  @param progress     上传的进度
 
 整体思路已经清楚，拿到视频资源，先转为mp4，写进沙盒，然后上传，上传成功后删除沙盒中的文件。
 本地拍摄的视频，上传到服务器：https://www.cnblogs.com/HJQ2016/p/5962813.html
 */
+ (void)uploadVideoWithURL:(NSString *)urlString parameters:(id)parameters videoPath:(NSString *)videoPath uploadProgress:(httpProgress)progress success:(requestSuccess)successBlock failure:(requestFailure)failureBlock {
    
    // 防止URL字符串中含有中文或特殊字符发生崩溃
    urlString = [urlString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    // 获得视频资源 (本地: NSURL.fileURLWithPath)
    AVURLAsset * avAsset = [AVURLAsset assetWithURL:[NSURL URLWithString:videoPath]];
    
    // 压缩: AVAssetExportPreset640x480 、960x540、1280x720、1920x1080、3840x2160
    AVAssetExportSession  *avAssetExport = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPreset640x480];
    
    // 创建日期格式化器
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd-HH:mm:ss"];
    
    // 转化后直接写入Library---caches
    //    NSString *videoWritePath = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingString:[NSString stringWithFormat:@"/output-%@.mp4",[formatter stringFromDate:[NSDate date]]]];
    //    avAssetExport.outputURL = [NSURL URLWithString:videoWritePath];
    
    avAssetExport.outputURL = [NSURL fileURLWithPath:videoPath];
    
    avAssetExport.outputFileType =  AVFileTypeMPEG4;
    [avAssetExport exportAsynchronouslyWithCompletionHandler:^{
        if ([avAssetExport status] == AVAssetExportSessionStatusCompleted) {
            
            AFHTTPSessionManager *manager = [MQNetworkManager httpSessionManager];
            
            [manager POST:urlString parameters:parameters constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                
                //获得沙盒中的视频内容
                [formData appendPartWithFileURL:[NSURL fileURLWithPath:videoPath] name:@"write you want to writre" fileName:videoPath mimeType:@"video/mpeg4" error:nil];
//                [formData appendPartWithFileURL:[NSURL fileURLWithPath:videoPath] name:@"file" fileName:@"testVideo" mimeType:@"video/mp4" error:nil];
//                [formData appendPartWithFileURL:[NSURL fileURLWithPath:videoWritePath] name:@"write you want to writre" fileName:videoWritePath mimeType:@"video/mpeg4" error:nil];
                
            } progress:^(NSProgress * _Nonnull uploadProgress) {
                
                if (progress) {
                    progress(1.0 * uploadProgress.completedUnitCount / uploadProgress.totalUnitCount);
                }
                
            } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                
                if (successBlock) {
                    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                    NSLog(@"statusCode=%ld",response.statusCode);
                    
                    successBlock(responseObject);
                }
                
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                
                if (failureBlock) {
                    NSHTTPURLResponse *response = (NSHTTPURLResponse *)task.response;
                    //        response.statusCode
                    //        response.allHeaderFields[@"Error_Code"];
                    NSInteger errorCode = [response.allHeaderFields[@"Error_Code"] integerValue];
                    NSLog(@"errorCode=%ld",errorCode);
                    failureBlock(error);
                }
            }];
            
        }
    }];
    
}

/**
 GitHubUser：CoderLN / Public：Codeidea
 // 一种：取消所有请求
 for (NSURLSessionTask *task in self.manager.tasks) {
     [task cancel];
 }
 
 // 二种：取消所有请求
 [self.manager.tasks makeObjectsPerformSelector:@selector(cancel)];
 
 // 三种：关闭NSURLSession + 取消所有请求
 // NSURLSession一旦被关闭了, 就不能再发请求
 [self.manager invalidateSessionCancelingTasks:YES];
 
 // 注意: 一个请求任务被取消了(cancel), 会自动调用AFN请求的failure这个block, block中传入error参数的code是NSURLErrorCancelled
 */

/** 取消所有的网络请求 */
+ (void)cancelAllRequest {
    [[MQNetworkManager httpSessionManager].operationQueue cancelAllOperations];
}

/**
 * 取消指定的网络请求
 *
 * @param requestMethod     请求方式(GET、POST)
 * @param urlString  请求URL
 */
+ (void)cancelWithRequestMethod:(NSString *)requestMethod url:(NSString *)urlString parameters:(id)parameters {
    
    AFHTTPSessionManager *manager = [MQNetworkManager httpSessionManager];
    
    // 根据请求的类型 以及 请求的url创建一个NSMutableURLRequest---通过该url去匹配请求队列中是否有该url,如果有的话 那么就取消该请求
    NSError * error;
    NSString * requestUrl = [[manager.requestSerializer requestWithMethod:requestMethod URLString:urlString parameters:parameters error:&error] URL].path;
    
    for (NSOperation *operation in manager.operationQueue.operations) {
        // 如果是请求队列
        if ([operation isKindOfClass:[NSURLSessionTask class]]) {
            // 请求的类型匹配
            BOOL hasMatchRequestType = [requestMethod isEqualToString:[[(NSURLSessionTask *)operation currentRequest] HTTPMethod]];
            // 请求的url匹配
            BOOL hasMatchRequestURLString = [requestUrl isEqualToString:[[[(NSURLSessionTask *)operation currentRequest] URL] path]];
            // 两项都匹配的话,取消该请求
            if (hasMatchRequestType && hasMatchRequestURLString) {
                [operation cancel];
            }
        }
    }
}

#pragma mark - AFN实时检测网络状态

+ (void)afnReachability
{
    // 1.创建检测网络状态管理者 2.检测网络状态改变
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        switch (status) {
                case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"WiFi");
                break;
                case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"蜂窝网络");
                break;
                case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"没有网络");
                break;
                case AFNetworkReachabilityStatusUnknown:
                NSLog(@"未知");
                break;
                
            default:
                break;
        }
    }];
    
    // 3.开始检测
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
}


@end
