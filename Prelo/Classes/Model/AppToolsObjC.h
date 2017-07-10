//
//  AppToolsObjC.h
//  Prelo
//
//  Created by Rahadian Kumang on 8/4/15.
//  Copyright (c) 2015 PT Kleo Appara Indonesia. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <UIKit/UIKit.h>
//#import <AdobeCreativeSDKCore/AdobeCreativeSDKCore.h>
//#import <AdobeCreativeSDKImage/AdobeCreativeSDKImage.h>
#import "AFHTTPRequestOperationManager.h"

#import <AssetsLibrary/ALAsset.h>
#import <AssetsLibrary/ALAssetRepresentation.h>
#import <ImageIO/CGImageSource.h>
#import <ImageIO/CGImageProperties.h>
#import <ImageIO/CGImageDestination.h>

typedef void(^AssetFromAlbumComplete)(NSArray *array);
typedef void(^AssetFromAlbumFailed)(NSString *message);

@interface AppToolsObjC : NSObject

+ (NSString *) jsonStringFrom:(id)json;
+ (NSRange) rangeOf:(NSString *)text inside:(NSString *)parent;
+ (NSString *) stringByHideTextBetween:(NSString *)start and:(NSString *)end from:(NSString *)string;

+ (void) fetchAssetWithAlbumName:(NSString *)albumName onComplete:(AssetFromAlbumComplete)complete onFailed:(AssetFromAlbumFailed)failed;

+ (CAGradientLayer *)gradientViewWithColor:(NSArray *)arrayColor withView:(UIView *)view;

+ (void) PATHPostPhoto:(UIImage *) image param:(NSDictionary *)param token:(NSString *)token success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
+ (void) sendMultipart:(NSDictionary *)param to:(NSString *)path images:(NSArray *)images withToken:(NSString *)token success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
+ (void) sendMultipart:(NSDictionary *)param images:(NSArray *)images withToken:(NSString *)token success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
+ (void) sendMultipart:(NSDictionary *)param images:(NSArray *)images withToken:(NSString *)token andUserAgent:(NSString *)userAgent to:(NSString *)url success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
+ (void) sendMultipart:(NSDictionary *)param imagesDict:(NSDictionary *)images withToken:(NSString *)token andUserAgent:(NSString *)userAgent to:(NSString *)url success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;
+ (AFHTTPRequestOperationManager *) sendMultipart2:(NSDictionary *)param images:(NSArray *)images withToken:(NSString *)token andUserAgent:(NSString *)userAgent to:(NSString *)url success:(void (^)(AFHTTPRequestOperation *operation, id responseObject))success
               failure:(void (^)(AFHTTPRequestOperation *operation, NSError *error))failure;

+ (NSString *) stringWithData:(NSData *)data;

+ (NSArray *) searchHistories;
+ (void) insertNewSearch:(NSString *)keyword;
+ (void) clearSearch;
+ (NSInteger) indexOfSearch:(NSString *)keyword;
+ (void) removeSearchAt:(NSInteger)index;

+ (void) shareToInstagram:(UIImage *)image from:(UIViewController *)parent;

+ (UIImage *)imageFromColor:(UIColor *)color;

+ (NSData *)dataByRemovingExif:(NSData *)data;

@end

@interface UINavigationController (AppToolsObjC)

- (void) removeControllerFromStack:(UIViewController *)con;

@end

@interface UIImage (AppToolsObjC)

+ (UIImage *)imageFromAsset:(ALAsset *)asset;
- (UIImage *) putPreloWatermarkWithUsername:(NSString *)username;

@end

@interface NSObject (AppToolsObjC)

- (CGFloat) cgFloat;

@end
