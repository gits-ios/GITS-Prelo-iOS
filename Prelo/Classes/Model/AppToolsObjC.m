//
//  AppToolsObjC.m
//  Prelo
//
//  Created by Rahadian Kumang on 8/4/15.
//  Copyright (c) 2015 GITS Indonesia. All rights reserved.
//

#import "AppToolsObjC.h"

@implementation AppToolsObjC

+ (NSString *)jsonStringFrom:(id)json
{
    NSError *err;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:json options:0 error:&err];
    NSString *resultAsString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return resultAsString;
}

+ (NSRange)rangeOf:(NSString *)text inside:(NSString *)parent
{
    return [parent rangeOfString:text];
}

+ (NSString *)stringByHideTextBetween:(NSString *)start and:(NSString *)end from:(NSString *)string
{
    if ([string rangeOfString:start].location != NSNotFound && [string rangeOfString:end].location != NSNotFound) {
        NSRange rStart = [string rangeOfString:start];
        NSRange rEnd = [string rangeOfString:end];
        NSRange r = NSMakeRange(rStart.location + rStart.length, rEnd.location-rStart.location-rStart.length);
        NSString *s = [string stringByReplacingCharactersInRange:r withString:@""];
        
        return s;
    }
    return string;
}

+ (void)fetchAssetWithAlbumName:(NSString *)albumName onComplete:(AssetFromAlbumComplete)complete onFailed:(AssetFromAlbumFailed)failed
{
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        ALAssetsLibrary *l = [[ALAssetsLibrary alloc] init];
        NSUInteger groupTypes = ALAssetsGroupAlbum | ALAssetsGroupEvent | ALAssetsGroupFaces | ALAssetsGroupSavedPhotos;
        [l enumerateGroupsWithTypes:groupTypes usingBlock:^(ALAssetsGroup *g, BOOL *stop) {
//            BOOL s = stop;
            
//            if (s && alreadyCalledStop == NO) {
//                dispatch_async(dispatch_get_main_queue(), ^(void){
//                    complete(array);
//                });
//            } else {
//                
//            }
            NSMutableArray *array = @[].mutableCopy;
            if ([[g valueForProperty:ALAssetsGroupPropertyName] isEqualToString:albumName]) {
                [g enumerateAssetsUsingBlock:^(ALAsset *a, NSUInteger index, BOOL *stop2) {
                    if (a) {
                        [array addObject:a.defaultRepresentation.url];
                    } else {
                        dispatch_async(dispatch_get_main_queue(), ^(void){
                            complete(array);
                            return;
                        });
                    }
                }];
            }
        } failureBlock:^(NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                failed(err.description);
            });
        }];
    });
}

@end

@implementation UINavigationController (AppToolsObjC)

- (void)removeControllerFromStack:(UIViewController *)con
{
    NSMutableArray *a = self.viewControllers.mutableCopy;
    [a removeObject:con];
    self.viewControllers = a;
}

@end

@implementation UIImage (AppToolsObjC)

+ (UIImage *)imageFromAsset:(ALAsset *)asset
{
    return [UIImage imageWithCGImage:asset.defaultRepresentation.fullScreenImage scale:asset.defaultRepresentation.scale orientation:UIImageOrientationUp];
}

@end