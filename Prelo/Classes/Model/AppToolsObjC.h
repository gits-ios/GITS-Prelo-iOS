//
//  AppToolsObjC.h
//  Prelo
//
//  Created by Rahadian Kumang on 8/4/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface AppToolsObjC : NSObject

+ (NSString *) jsonStringFrom:(id)json;
+ (NSRange) rangeOf:(NSString *)text inside:(NSString *)parent;
+ (NSString *) stringByHideTextBetween:(NSString *)start and:(NSString *)end from:(NSString *)string;

@end

@interface UINavigationController (AppToolsObjC)

- (void) removeControllerFromStack:(UIViewController *)con;

@end
