//
//  AuthCore.h
//  ChatMap
//
//  Created by culibinx@gmail.com on 27.06.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>



#import "UIViewController+Extensions.h"
#import "NSString+Extensions.h"
#import "AFBlurSegue.h"

#define APP [AppCore sharedInstance]

#define UID [APP uniqueID]
#define DISPLAY_NAME [APP displayName]
#define CHANNEL_NAME [APP channelName]
#define AVATAR_NAME [APP avatarName]
#define AUTH_STATUS [APP authStatus]
#define ON_NOTIFICATION_POINT [APP onNotificationPoint]
#define ON_NOTIFICATION_ROOM [APP onNotificationRoom]

#define GOOGLE_API_KEY @"GoogleApiKey"
#warning enter DEFAULT_GOOGLE_API_KEY
#define DEFAULT_GOOGLE_API_KEY @""

typedef void (^ToastBlock)(void);

@interface AppCore : NSObject

+ (AppCore*) sharedInstance;
- (BOOL)authStatus;
- (NSString*)uniqueID;

- (NSString*)displayName;
- (void)setDisplayName:(NSString*)displayName;
- (NSString*)channelName;
- (void)setChannelName:(NSString*)channelName;
- (NSString*)avatarName;
- (void)setAvatarName:(NSString*)avatarName;
- (BOOL)onNotificationPoint;
- (void)setOnNotificationPoint:(BOOL)onNotificationPoint;
- (BOOL)onNotificationRoom;
- (void)setOnNotificationRoom:(BOOL)onNotificationRoom;

// Auth

- (void)authWithDisplayName:(BOOL)reauth;

// Map

- (UIView*)mapView;

- (void)setMapIndex:(NSInteger)mapIndex;
- (NSInteger)mapIndex;

- (void)centerLocation;
- (void)zoomPlus;
- (void)zoomMinus;
- (BOOL)isDarkMode;

- (void)createPoint:(NSString*)description;
- (void)onCreatePoint:(BOOL)on;

// Chat

- (void)createMessage:(NSString*)roomId message:(NSDictionary*)message callback:(void (^)(NSString*))callback;
- (void)clearUnreaded:(NSString*)pointId roomId:(NSString*)roomId;
- (void)leaveRoom:(NSString*)pointId roomId:(NSString*)roomId;

// Utils
// + (void)addPictureToAlbum:(UIImage *)image albumName:(NSString*)albumName;
+ (CGFloat)statusBarHeight;
+ (void)imageFromURL:(NSURL*)attachmentURL withCompletion:(void (^)(UIImage*))completion;
+ (void)showAnimated:(UIView*)view animated:(BOOL)animated withCompletion:(void (^)(void))completion;
- (UIImage*) circularImageWithImage:(UIImage*)inputImage borderColor:(UIColor*)borderColor borderWidth:(CGFloat)borderWidth;

- (NSString*)timeSpan:(NSInteger)timeInMs;
- (NSString *)displayDate:(NSNumber*)ts;

- (void)uploadPhoto:(UIImage*)image completion:(void (^)(NSURL*))completion;

@end

@interface CenterPoint : UIView

@property (nonatomic, retain) CAShapeLayer *mainLayer;
@property (nonatomic, retain) CAAnimationGroup *animationGroup;
@property (nonatomic, retain) IBInspectable UIColor *pulseColor;
@property (nonatomic) IBInspectable CGFloat pulseRadius;
@property (nonatomic) IBInspectable CGFloat pulseDuration;
@property (nonatomic, retain) IBInspectable UIColor *mainColor;
@property (nonatomic) IBInspectable CGFloat cornerRadius;

-(void)setup;

@end

@interface ToastView : UIView

+ (void)setAppearanceBackgroundColor:(UIColor *)backgroundColor;
+ (void)setAppearanceCornerRadius:(CGFloat)cornerRadius;
+ (void)setAppearanceMaxWidth:(CGFloat)maxWidth;
+ (void)setAppearanceMaxLines:(NSInteger)maxLines;
+ (void)setAppearanceOffsetBottom:(CGFloat)offsetBottom;
+ (void)setAppearanceTextAligment:(NSTextAlignment)textAlignment;
+ (void)setAppearanceTextColor:(UIColor *)textColor;
+ (void)setAppearanceTextFont:(UIFont *)textFont;
+ (void)setAppearanceTextInsets:(UIEdgeInsets)textInsets;
+ (void)setToastViewShowDuration:(NSTimeInterval)duration;

+ (void)showToast:(id)toast;
+ (void)showToast:(id)toast duration:(NSTimeInterval)duration;
+ (void)showToast:(id)toast delay:(NSTimeInterval)delay;
+ (void)showToast:(id)toast completion:(ToastBlock)completion;
+ (void)showToast:(id)toast duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay;
+ (void)showToast:(id)toast duration:(NSTimeInterval)duration completion:(ToastBlock)completion;
+ (void)showToast:(id)toast delay:(NSTimeInterval)delay completion:(ToastBlock)completion;
+ (void)showToast:(id)toast duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay completion:(ToastBlock)completion;

@end

// TODO

// 1) delete point on long tap info window or export coordinate to external map
// 2) button reauth on chat window + may be timer elapsed
// 3) add dialog to select timestamp and type 
// 4) append logic to enter room or leave room
// 5) chat may be slack kit or jsq





