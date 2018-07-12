//
//  UIImage+compressIMG.h
//  MQFrameworkTool
//
//  Created by mengJing on 2018/7/12.
//  Copyright © 2018年 mengJing. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (compressIMG)

/**
 *  图片的压缩方法
 *
 *  @param sourceImg   要被压缩的图片
 *  @param defineWidth 要被压缩的尺寸(宽)
 *
 *  @return 被压缩的图片
 */
+(UIImage *)IMGCompressed:(UIImage *)sourceImg targetWidth:(CGFloat)defineWidth;

@end
