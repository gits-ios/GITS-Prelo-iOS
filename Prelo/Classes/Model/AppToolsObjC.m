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
        NSMutableArray *array = @[].mutableCopy;
        [l enumerateGroupsWithTypes:groupTypes usingBlock:^(ALAssetsGroup *g, BOOL *stop) {
            if (!g) {
                dispatch_async(dispatch_get_main_queue(), ^(void){
                    complete(array);
                    return;
                });
            } else {
                NSString *name = [g valueForProperty:ALAssetsGroupPropertyName];
                if ([name rangeOfString:@"amera"].location != NSNotFound || [name rangeOfString:@"oto"].location != NSNotFound)
                {
                    [g enumerateAssetsUsingBlock:^(ALAsset *a, NSUInteger index, BOOL *stop2) {
                        if (a) {
                            [array addObject:a.defaultRepresentation.url];
                            //                        [array addObject:a];
                        } else {
                            
                        }
                    }];
                }
            }
        } failureBlock:^(NSError *err) {
            dispatch_async(dispatch_get_main_queue(), ^(void){
                failed(err.description);
            });
        }];
    });
}

+ (CAGradientLayer *)gradientViewWithColor:(NSArray *)arrayColor withView:(UIView *)view
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    CGRect r = view.bounds;
    r.size.width = ([UIScreen mainScreen].bounds.size.width-96)/2;
    gradient.frame = r;
//    gradient.colors = [NSArray arrayWithObjects:(id)[[UIColor colorWithWhite:1 alpha:1] CGColor], (id)[[UIColor colorWithWhite:1 alpha:0] CGColor], nil];
    gradient.colors = arrayColor;
    gradient.startPoint = CGPointMake(0, 0.5f);
    gradient.endPoint = CGPointMake(1, 0.5f);
    [view.layer insertSublayer:gradient atIndex:0];
    
    return gradient;
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

@implementation NSObject(AppToolsObjC)

- (CGFloat)cgFloat
{
    if ([self isKindOfClass:[NSString class]]) {
        NSString *s = (NSString *)self;
        return s.floatValue;
    } else {
        return 0;
    }
}

@end