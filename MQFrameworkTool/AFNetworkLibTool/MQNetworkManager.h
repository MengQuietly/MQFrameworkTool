//
//  MQNetworkManager.h
//  MQFrameworkTool
//
//  Created by mengJing on 2018/7/11.
//  Copyright © 2018年 mengJing. All rights reserved.
//

//#import "AFHTTPSessionManager.h"
#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

typedef NS_ENUM (NSUInteger, APIManagerErrorType){
    APIManagerErrorTypeDefault,       //没有产生过API请求，这个是manager的默认状态。
    APIManagerErrorTypeSuccess,       //API请求成功且返回数据正确，此时manager的数据是可以直接拿来使用的。
    APIManagerErrorTypeNoContent,     //API请求成功但返回数据不正确。如果回调数据验证函数返回值为NO，manager的状态就会是这个。
    APIManagerErrorTypeParamsError,   //参数错误，此时manager不会调用API，因为参数验证是在调用API之前做的。
    APIManagerErrorTypeTimeout,       //请求超时。ApiProxy设置的是20秒超时，具体超时时间的设置请自己去看ApiProxy的相关代码。
    APIManagerErrorTypeNoNetWork,     //网络不通。在调用API之前会判断一下当前网络是否通畅，这个也是在调用API之前验证的，和上面超时的状态是有区别的。
    APIManagerErrorLoginTimeout,       //登录超时
};

/** 请求类型 */
typedef NS_ENUM(NSUInteger, MQHttpRequestType) {
    MQHttpRequestTypeGet = 0,
    MQHttpRequestTypePost,
    MQHttpRequestTypePut,
//    MQHttpRequestTypeUpload,
    MQHttpRequestTypeDelete
};

typedef NS_ENUM(NSInteger,MQNetworkStatus) {
    MQNetworkStatusNoNet = 0,  //无网络
    MQNetworkStatusMobile,     //移动网络
    MQNetworkStatusWifi        //wifi网络
};

/** 请求成功，失败 block */
//typedef void(^SuccessBlock)(NSInteger statusCode,id responseObject);
//typedef void(^FailBlock)(NSInteger statusCode,NSError *error);

typedef void (^requestSuccess)(id  _Nullable responseObject);
typedef void (^requestFailure)(NSError * _Nonnull error);

/** 上传 / 下载 进度block */
typedef void (^httpProgress)(float progressNum);

/** 下载完成回调 进度block */
typedef void (^completionHandler)(NSURL *fullPath, NSError *error);


@interface MQNetworkManager : NSObject

///** 当前网络是否可用：YES可用，NO不可用 */
//@property (nonatomic, assign) BOOL currentNetworkStatus;
///** 当前网络环境 */
//@property (nonatomic, assign) MQNetworkStatus netStatus;
///** 添加参数,设置登录失效后重新登录只弹出一次 */
//@property (nonatomic,assign)NSInteger onceResponse;
///** 开启手机网络的监听 */
//+ (void)startNotificationNetworkStatus;
///** 返回当前网络是否可用 */
//+ (BOOL)getCurrentNetworkStatus;
///** 返回当前的网络状态 */
//+ (MQNetworkStatus)returnCurrentNetworkStatus;

#pragma mark - AFN实时检测网络状态

/**
 * AFN实时检测网络状态
 */
+ (void)afnReachability;


/** 网络请求: Get / Post 请求, 无 progress */
+ (void)requestWithType:(MQHttpRequestType)requestType url:(NSString *)urlString parameters:(id)parameters success:(requestSuccess)successBlock failure:(requestFailure)failureBlock;
/** 网络请求: Get / Post 请求, progress */
+ (void)requestWithType:(MQHttpRequestType)requestType url:(NSString *)urlString parameters:(id)paraments progress:(httpProgress)progress success:(requestSuccess)successBlock failure:(requestFailure)failureBlock;

/**
 * 文件上传:多张图片上传
 *
 * @param urlString          上传的url
 * @param parameters         上传图片预留参数---(可移除,可为nil)
 * @param imageArray         上传的图片数组
 * @param width              图片要被压缩到的宽度
 * @param progress     上传进度
 */
+ (void)uploadFileWithURL:(NSString *)urlString parameters:(id)parameters imageArray:(NSArray *)imageArray targetWidth:(CGFloat)width uploadProgress:(httpProgress)progress success:(requestSuccess)successBlock failure:(requestFailure)failureBlock;

/**
 *  文件下载
 *
 *  @param urlString    请求的url
 *  @param parameters   文件下载预留参数---(可移除,可为nil)
 *  @param savePath     下载文件保存路径(为空: 默认路径)
 *  @param progress     下载文件的进度显示
 */
+ (void)downLoadFileWithURL:(NSString *)urlString parameters:(id)parameters savePath:(NSString *)savePath downLoadProgress:(httpProgress)progress completionHandler:(completionHandler)completionHandler;

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
+ (void)uploadVideoWithURL:(NSString *)urlString parameters:(id)parameters videoPath:(NSString *)videoPath uploadProgress:(httpProgress)progress success:(requestSuccess)successBlock failure:(requestFailure)failureBlock;

/** 取消所有的网络请求 */
+ (void)cancelAllRequest;

/**
 * 取消指定的网络请求
 *
 * @param requestMethod     请求方式(GET、POST)
 * @param urlString  请求URL
 */
+ (void)cancelWithRequestMethod:(NSString *)requestMethod url:(NSString *)urlString parameters:(id)parameters;



//+ (void)getWithApi:(NSString *)api parameters:(id)parameters success:(SuccessBlock)successBlock fail:(FailBlock)failBlock;
//+ (void)postWithApi:(NSString *)api parameters:(id)parameters success:(SuccessBlock)successBlock fail:(FailBlock)failBlock;



@end
