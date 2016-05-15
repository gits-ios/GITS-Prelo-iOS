//
//  MoEngageSDK.h
//  MoEngageSDK
//
//  Created by Karthik Thirumalasetti on 06/07/14.
//  Copyright (c) 2014 alphadevs. All rights reserved.
//
// SDK Version 2.1


#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>
#import "MOPayloadBuilder.h"

typedef void(^NudgeCreationCompletionBlock)(UIView *nudgeView, NSString* campaignID);

typedef enum {
    NudgeTop,
    NudgeBottom
}NudgePosition;

typedef enum _AppStatus{
    INSTALL,
    UPDATE
}AppStatus;

typedef enum _LogLevel{
    LOG_NONE,
    LOG_ALL,
    LOG_EXCEPTIONS
}LogLevel;

typedef enum _InAppWidget{
    CLOSE_BUTTON,
    BUTTON,
    IMAGE,
    LABEL
}InAppWidget;


/** 
 Conform to this protocol if you want to handle the action of the in-app messages' button clicks.
 */
@protocol MOInAppDelegate <NSObject>
@optional

/**
 This method is called when the inApp is shown.
 @param campaignID - Campaign ID of InApp shown.
 */
-(void)inAppShownWithCampaignID:(NSString*)campaignID;

/**
 This method is called when the user clicks on a widget in the in-app message. Conform to MoInAppDelegate to use this callback method.
 @param screenName - Used in DeepLinking, gives the screen name to navigate.
 @param dataDict - The key value data dictionary associated with the widget tapped.
 */
-(void)inAppClickedForWidget:(InAppWidget)widget screenName:(NSString*)screenName andDataDict:(NSDictionary *)dataDict;

/**
 This method is called when an event triggers an in-app from the server, which is of type self handled. 
 @param data - The data mentioned on the dashboard while creating the in-app is passed onto you
 */
-(void)eventTriggeredInAppAvailableWithData:(id)data;

@end

@interface MoEngage : NSObject

#pragma mark - Properties 

@property(nonatomic, weak) id<MOInAppDelegate> delegate;

/**
 Set this property to change the default delay between two in-app messages.
 The delay is in minutes. Default value is 15 minutes.
 */
@property(nonatomic, assign) NSInteger delayBetweenInApps;

/**
 Set this property to YES if you don't wish to use the Inbox / Notification center feature
 */
@property(nonatomic, assign) BOOL      disableInbox;

/**
 Set this property to YES if you don't use in app messaging.
 */
@property(nonatomic, assign) BOOL      disableInApps;

/**
 Set the property to YES if you don't want MoEngage to reset bagde no. on app open
 */
@property(nonatomic, assign) BOOL      disableBadgeReset;

#pragma mark - Shared instance 

+(instancetype)sharedInstance;

#pragma mark - Methods

/**
 Call this method in the AppDelegate in didFinishLaunchingWithOptions to initialize the SDK
 @param apiKey The unique apiKey provided for your app
 @param application The application instance
 @param launchOptions The launch options dictionary
 */
-(void)initializeWithApiKey:(NSString *)apiKey inApplication:(UIApplication*)application withLaunchOptions:(NSDictionary*)launchOptions;

/**
 Call this method in AppDelegate in didRegisterForRemoteNotificationsWithDeviceToken to register your app with MoEngage for push notifications
 @param deviceToken The token of the device for push notifications
 */
-(void)registerForPush:(NSData *)deviceToken;

/**
 Call this method in AppDelegate in didRegisterUserNotificationSettings to register the app for notification setting changes by the user
 @param settings The push notification settings. 
 @since iOS8
 */
-(void)didRegisterForUserNotificationSettings:(UIUserNotificationSettings *)settings;

/**
 Call this method in AppDelegate in didFailToRegisterForRemoteNotificationsWithError
*/
-(void)didFailToRegisterForPush;

/**
 Call this method in AppDelegate in applicationDidEnterBackground
 @param application The application instance
 */
-(void)stop:(UIApplication *)application;

/**
 Call this method to track events.
 @param name The name of the event
 @param payload The dictionary you want to associate with the event (optional)
 @warning Please make sure that you are tracking event attributes without changing their data types. Our system detects the data type automatically unless you explicitly specify it as a string.
 */
-(void)trackEvent:(NSString *)name andPayload:(NSMutableDictionary *)payload;

/**
 Call this method if you want to track events with special types like timestamp/datetime or location.
 @param payload of type MOPayloadBuilder. See MOPaylodBuilder for more details.
 */
-(void)trackEvent:(NSString *)name builderPayload:(MOPayloadBuilder *)payload;

/**
 Use this method to set unique attributes to identify the app user. For eg. username, email, age, gender etc.
 @param value The value/attribute
 @warning value can of be type string, integer or bool
 @param key The key, which is the kind of attribute
 */
-(void)setUserAttribute:(id)value forKey:(NSString *)key;

/**
 Use this method to set a user attribute which is datetime or time.
 @param timestamp The timestamp in epoch format.
 */
-(void)setUserAttributeTimestamp:(double)timestamp forKey:(NSString *)key;

/**
 Use this method to set user attribute location.
 @param lat The latitude of the location
 @param lng The longitude of the location
 */
-(void)setUserAttributeLocationLatitude:(double)lat longitude:(double)lng forKey:(NSString *)key;

/**
 Call this method in AppDelegate in didReceiveRemoteNotification
 @param application The application instance
 @param userInfo The info dict with the push
 */
-(void)didReceieveNotificationinApplication:(UIApplication*)application withInfo:(NSDictionary*)userInfo;

/**
 Call this method in applicationDidBecomeActive
 @param application The application instance
 */
-(void)applicationBecameActiveinApplication:(UIApplication*)application;

/**
 Call this method in applicationWillEnterForeground
 @param application The application instance
 */
-(void)applicationWillEnterForeground:(UIApplication *)application;

/**
 Use this method to set the location associated with a location attribute
 @param lat The latitude of the location
 @param lng The longitude of the location
 @param locationAttrName The name of the location attribute
 @param dict The dict associated with this location event, if any
 */
+(void)setLocationwithLat:(double)lat lng:(double)lng withName:(NSString*)locationAttrName inDictionary:(NSMutableDictionary*) dict __deprecated_msg("use setUserAttributeLocationLatitude:longitude:forKey: instead");

/**
 Call this method in AppDelegate in applicationWillTerminate
 @param application The application instance
 */
-(void)applicationTerminated:(UIApplication*)application;

/**
 Call this method in viewDidAppear of the view controller where you want to show the in app message
 NOTE: Adhere to the delegate for InApp - MOInAppDelegate, if you want the callback for the button actions.
 @see MOInAppDelegate
 */
-(void)handleInAppMessage;

/**
 Call this method in viewDidLoad of the view controller where you don't want to show in app messages
 @param viewcontroller The viewcontroller instance where you don't want to show in app
 */
-(void)dontShowInAppInViewController:(UIViewController*)viewcontroller;

/**
 Call this method in viewDidAppear of the view controller where you want to get a self handled in app message
 */
-(NSDictionary*)getSelfHandledInApp;

/**
 Call this method to track if self handled in app was shown.
  @param campaignID The campaign ID of the self handled in app shown
 */
-(void)selfHandledInAppViewShownWithCampaignID:(NSString*)campaignID;

/**
 Call this method to clear the unique attributes of the current user, and add him as a new user. One of the use cases is when a user logs out
 */
-(void)resetUser;

/**
 Use this method to forcefully sync events to server right now. Useful for testing and to send data in realtime when you don't wish to wait for when the user goes to background or terminates the app.
 */
-(void)syncNow;

/**
 Call this method to get the nudge view created in the dashboard. There can be only 1 active nudge view at any given point of time
 @param completionBlock Completion Block with the nudge View and campaign ID.
 */
-(void)getNudgeViewWithCompletionBlock:(NudgeCreationCompletionBlock)completionBlock;

/**
 Call this method to track if nudge obtained from getNudgeViewWithCompletionBlock was shown.
 @param campaignID The campaign ID of the nudge shown
 */
-(void)nudgeViewShownWithCampaignID:(NSString*)campaignID;

/**
 Call this method to show the nudge view created in the dashboard at top/bottom of the viewcontroller. There can be only 1 active nudge view at any given point of time.
 @param position Defines where to add the nudge view Top/Bottom.
 */
-(void)showNudgeViewAtNudgePosition:(NudgePosition)position;

/**
 Use this method to set the app status.
 @param appStatus - Two possible enum values - APP_UDPATE (for app updates) and APP_INSTALL (for new installs)
 */
-(void)appStatus:(AppStatus)appStatus;

/**
 Use this method to start tracking geofences for the current location. 
 @param locManager Pass the location manager instance if you have create one. Else, a new one will be created. This param is optional.
 @param location Pass this param if you already have the location of the user or want to hard code a location. Else the location manager will take the current location of the user
 @see MOGeofenceHandler to get completion block
 */
-(void)startGeofencingWithLocationManager:(CLLocationManager *)locManager andCurrentLocation:(CLLocation *)location;

/**
 Use this method to enable logs for the MoEngage SDK. You can simply pass yes and no to disable the logs.
 Alternatively you can use Log Levels.
 @see LogLevel
 */
+(void)debug:(LogLevel) logLevel;

@end

