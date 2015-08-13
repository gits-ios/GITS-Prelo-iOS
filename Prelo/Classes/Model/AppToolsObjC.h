//
//  AppToolsObjC.h
//  Prelo
//
//  Created by Rahadian Kumang on 8/4/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>

typedef void(^AssetFromAlbumComplete)(NSArray *array);
typedef void(^AssetFromAlbumFailed)(NSString *message);

@interface AppToolsObjC : NSObject

+ (NSString *) jsonStringFrom:(id)json;
+ (NSRange) rangeOf:(NSString *)text inside:(NSString *)parent;
+ (NSString *) stringByHideTextBetween:(NSString *)start and:(NSString *)end from:(NSString *)string;

+ (void) fetchAssetWithAlbumName:(NSString *)albumName onComplete:(AssetFromAlbumComplete)complete onFailed:(AssetFromAlbumFailed)failed;

@end

@interface UINavigationController (AppToolsObjC)

- (void) removeControllerFromStack:(UIViewController *)con;

@end

@interface UIImage (AppToolsObjC)

+ (UIImage *)imageFromAsset:(ALAsset *)asset;

@end