//
//  ViewController.m
//  MQFrameworkTool
//
//  Created by mengJing on 2018/7/11.
//  Copyright © 2018年 mengJing. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString * str = @"http://www.baidu%网/址/.con";
    NSString * str1 = [str stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"---%@", str1);
    
    NSString * str2 =[str1 stringByRemovingPercentEncoding];
    NSLog(@"---===%@", str2);
    
    NSString *ss = @"https://www.google.co.jp/search?q=%E4%B8%AD%E6%96%87%25%2F&oq=%E4%B8%AD%E6%96%87%25%2F&aqs=chrome..69i57j69i65j0l4.7522j0j7&sourceid=chrome&ie=UTF-8";
    NSString * str3 =[ss stringByRemovingPercentEncoding];
    NSLog(@"---===%@", str3);
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
