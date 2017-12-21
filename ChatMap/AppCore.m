//
//  AuthCore.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 27.06.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "AppCore.h"

#import <AVFoundation/AVFoundation.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import <Photos/Photos.h>
#import <GoogleMaps/GoogleMaps.h>

#import <FirebaseCore/FirebaseCore.h>
#import <FirebaseAuth/FirebaseAuth.h>
#import <FirebaseDatabase/FirebaseDatabase.h>
#import <FirebaseStorage/FirebaseStorage.h>
#import <FirebaseMessaging/FirebaseMessaging.h>

#import "AuthViewController.h"
#import "ChatViewController.h"
#import "CreatePointViewController.h"


#define MAIN_POINT [NSString stringWithFormat:@"clicks/%@", _channelName]
#define MAIN_POINT_NAME(name) [NSString stringWithFormat:@"clicks/%@", name]
#define MAIN_CHAT [NSString stringWithFormat:@"chat/%@", _channelName]
#define MAIN_CHAT_NAME(name) [NSString stringWithFormat:@"chat/%@", name]

#define UNIQUE_ID_KEY @"UniqueID"
#define DISPLAY_NAME_KEY @"DisplayName"
#define CHANNEL_NAME_KEY @"ChannelName"
#define AVATAR_NAME_KEY @"AvatarName"
#define ON_NOTIFICATION_POINT_KEY @"OnNotificationPoint"
#define ON_NOTIFICATION_ROOM_KEY @"OnNotificationRoom"
#define POINTS_KEY @"Points"

#define CURRENT_MAP_INDEX_KEY @"CurrentMapIndex"
#define CURRENT_POSITION_LAT_KEY @"CurrentPosLat"
#define CURRENT_POSITION_LNG_KEY @"CurrentPosLng"
#define CURRENT_LOCATION_LAT_KEY @"CurrentLocLat"
#define CURRENT_LOCATION_LNG_KEY @"CurrentLocLng"
#define CURRENT_ZOOM_KEY @"CurrentZoom"

#define MY_LOCATION_KEY @"myLocation"

#define MessageRef [NSString stringWithFormat:@"%@/room-messages",MAIN_CHAT]
#define RoomRef [NSString stringWithFormat:@"%@/room-metadata",MAIN_CHAT]
#define RoomRefName(name) [NSString stringWithFormat:@"%@/room-metadata",MAIN_CHAT_NAME(name)]

#define PrivateRoomRef [NSString stringWithFormat:@"%@/room-private-metadata",MAIN_CHAT]
#define ModeratorsRef [NSString stringWithFormat:@"%@/moderators",MAIN_CHAT]
#define SuspensionsRef [NSString stringWithFormat:@"%@/suspensions",MAIN_CHAT]
#define UsersOnlineRef [NSString stringWithFormat:@"%@/user-names-online",MAIN_CHAT]
#define ConnectedRef @".info/connected"
#define UserRef(userId)  [NSString stringWithFormat:@"%@/users/%@",MAIN_CHAT,userId]
#define UserRoomRef(userId,roomId) [NSString stringWithFormat:@"%@/rooms/%@",UserRef(userId),roomId]
#define SessionRef(userId) [NSString stringWithFormat:@"%@/sessions",UserRef(userId)]
#define UserPresenceRef(roomId,userId,sessionId) [NSString stringWithFormat:@"%@/room-users/%@/%@/%@",MAIN_CHAT,roomId,userId,sessionId]


#define READ_SETTINGS() { NSUserDefaults *defs = [NSUserDefaults standardUserDefaults]; _uniqueID = [defs objectForKey:UNIQUE_ID_KEY]; if (!_uniqueID || !_uniqueID.length) { _uniqueID =  [NSData simpleUUID]; [defs setObject:_uniqueID forKey:UNIQUE_ID_KEY]; } _displayName = [defs objectForKey:DISPLAY_NAME_KEY]; _channelName = [defs objectForKey:CHANNEL_NAME_KEY]; _avatarName = [defs objectForKey:AVATAR_NAME_KEY]; _onNotificationPoint = [[defs objectForKey:ON_NOTIFICATION_POINT_KEY] boolValue]; _onNotificationRoom = [[defs objectForKey:ON_NOTIFICATION_ROOM_KEY] boolValue]; _points = [NSMutableDictionary dictionaryWithDictionary:[defs objectForKey:POINTS_KEY]?:@{}]; _apiKey = [defs objectForKey:DEFAULT_GOOGLE_API_KEY]; if (!_apiKey || !_apiKey.length) { _apiKey =  DEFAULT_GOOGLE_API_KEY; [defs setObject:_apiKey forKey:GOOGLE_API_KEY]; } _mapIndex = [[defs objectForKey:CURRENT_MAP_INDEX_KEY] integerValue]?:1; _position = [[CLLocation alloc] initWithLatitude:[[defs objectForKey:CURRENT_POSITION_LAT_KEY] doubleValue] longitude:[[defs objectForKey:CURRENT_POSITION_LNG_KEY] doubleValue]]; _location = [[CLLocation alloc] initWithLatitude:[[defs objectForKey:CURRENT_LOCATION_LAT_KEY] doubleValue] longitude:[[defs objectForKey:CURRENT_LOCATION_LNG_KEY] doubleValue]]; _zoom = [[defs objectForKey:CURRENT_ZOOM_KEY] integerValue]?:0; \
}

#define UPDATE_SETTINGS() { NSUserDefaults *defs = [NSUserDefaults standardUserDefaults]; [defs setObject:_displayName forKey:DISPLAY_NAME_KEY]; [defs setObject:_channelName forKey:CHANNEL_NAME_KEY]; [defs setObject:_avatarName forKey:AVATAR_NAME_KEY]; [defs setObject:BOOL_VALUE(_onNotificationPoint) forKey:ON_NOTIFICATION_POINT_KEY]; [defs setObject:BOOL_VALUE(_onNotificationRoom) forKey:ON_NOTIFICATION_ROOM_KEY]; [defs setObject:_points forKey:POINTS_KEY]; [defs setObject:_apiKey forKey:GOOGLE_API_KEY]; [defs setObject:INTEGER_VALUE(_mapIndex) forKey:CURRENT_MAP_INDEX_KEY]; if (_isActive) { [defs setObject:DOUBLE_VALUE(_position.coordinate.latitude) forKey:CURRENT_POSITION_LAT_KEY]; [defs setObject:DOUBLE_VALUE(_position.coordinate.longitude) forKey:CURRENT_POSITION_LNG_KEY]; [defs setObject:DOUBLE_VALUE(_location.coordinate.latitude) forKey:CURRENT_LOCATION_LAT_KEY]; [defs setObject:DOUBLE_VALUE(_location.coordinate.longitude) forKey:CURRENT_LOCATION_LNG_KEY]; [defs setObject:INTEGER_VALUE(_zoom) forKey:CURRENT_ZOOM_KEY]; } \
[defs synchronize]; }

#define UPDATE_POINTS() { NSUserDefaults *defs = [NSUserDefaults standardUserDefaults]; [defs setObject:_points forKey:POINTS_KEY]; [defs synchronize]; }

#define CURRENT_USER [FIRAuth auth].currentUser
#define PUSH(a) [a childByAutoId].key
#define REF(a) [[[FIRDatabase database] reference] child:a]
#define POINT_PATH(a) [[MAIN_POINT stringByAppendingString:@"/"] stringByAppendingString:a]

@interface AppCore() <UITextFieldDelegate,GMSMapViewDelegate>
{
    FIRAuth *_auth;
    
    NSString *_uniqueID;
    NSString *_displayName;
    NSString *_channelName;
    NSString *_avatarName;
    NSString *_newChannelName;
    BOOL _onNotificationPoint;
    BOOL _onNotificationRoom;
    
    BOOL _authStatus;
    
    // Map
    BOOL _isActive;
    NSString *_apiKey;
    GMSMapView *_mapView;
    CLLocation *_position;
    CLLocation *_location;
    NSInteger _zoom;
    NSInteger _mapIndex;
    
    BOOL _followLocation;
    BOOL _followPosition;
    int _stateLocation;
    
    
    CLLocationCoordinate2D _coordinate;
    BOOL _onCreatePoint;
    CenterPoint *_centerPoint;
    
    NSMutableDictionary *_point_marker;
    NSMutableDictionary *_points;
    
    // Chat
    
    NSString *_sessionID;
    
    NSMutableDictionary *_presence_bits;
    NSMutableDictionary *_room_timestamp;
    NSMutableDictionary *_room_unreaded;
    
    // Controllers
    
    NSDictionary *_mapInfo;
    
    ChatViewController *_chatViewController;
    
    BOOL _onDisplayCreatePoint;
    BOOL _onDisplayChatPoint;
}

@end

@implementation AppCore

+ (AppCore*)sharedInstance
{
    DEFINE_SHARED_INSTANCE_USING_BLOCK(^{
        return [[self alloc] init];
    });
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        READ_SETTINGS();
        
        // Init
        _point_marker = [NSMutableDictionary new];
        _presence_bits = [NSMutableDictionary new];
        _room_timestamp = [NSMutableDictionary new];
        _room_unreaded = [NSMutableDictionary new];
        _mapInfo = [NSDictionary new];
        
        _stateLocation = 0;
        
        // Controllers
        _chatViewController = [[ChatViewController alloc] init];
        
        // Enable FireBase
        [FIRApp configure];
        [FIRDatabase database].persistenceEnabled = YES;
        
        // Prepare Google Maps API
        [GMSServices provideAPIKey:_apiKey];
        [GMSServices sharedServices];
        
        // Prepare MapView
        GMSCameraPosition *camera = [GMSCameraPosition cameraWithLatitude:_location.coordinate.latitude longitude:_location.coordinate.longitude zoom:_zoom];
        _mapView = [GMSMapView mapWithFrame:CGRectZero camera:camera];
        _mapView.delegate = self;
        [self setMapIndex:_mapIndex];
        
        // Subscribe GPS Location
        [_mapView addObserver:self forKeyPath:MY_LOCATION_KEY
                      options:NSKeyValueObservingOptionNew context:NULL];
        
        // Core Subscribe notifications
        SUBSCRIBE_NOTIFICATION(kUpdateSettings,@selector(saveState:));
        
        if (_displayName && _displayName.length) {
            [self authWithDisplayName:NO];
        }
    }
    return self;
}

- (BOOL)authStatus
{
    return _authStatus;
}

- (NSString*)uniqueID
{
    return _uniqueID;
}

- (NSString*)displayName
{
    return _displayName;
}
- (void)setDisplayName:(NSString*)displayName
{
    _displayName = displayName;
}

- (NSString*)channelName
{
    return _channelName?:@"public";
}
- (void)setChannelName:(NSString*)channelName
{
    _newChannelName = [[channelName stripName] stringByTrimmingCharactersInSet:
                                               [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (!_newChannelName.length) {
        _newChannelName = @"public";
    }
}

- (NSString*)avatarName
{
    return _avatarName;
}
- (void)setAvatarName:(NSString*)avatarName
{
    _avatarName = avatarName;
}

- (BOOL)onNotificationPoint
{
    return _onNotificationPoint;
}
- (void)setOnNotificationPoint:(BOOL)onNotificationPoint
{
    _onNotificationPoint = onNotificationPoint;
}

- (BOOL)onNotificationRoom
{
    return _onNotificationRoom;
}
- (void)setOnNotificationRoom:(BOOL)onNotificationRoom
{
    _onNotificationRoom = onNotificationRoom;
}

#pragma mark - Auth

- (void)authWithDisplayName:(BOOL)reauth
{
    if (reauth) {
        [[UIViewController currentViewController] performSegueWithIdentifier:@"authShow" sender:self];
        return;
    }
    
    if (!_auth) { _auth = [FIRAuth auth]; }
    if (CURRENT_USER) {
        [self updateProfile:_displayName];
    } else {
        [_auth signInAnonymouslyWithCompletion:^(FIRUser *_Nullable user,
                                                 NSError *_Nullable error) {
            if (error) {
                [self showError:@"Sign-in anonymously failed"];
                [self updateAuthStatus:NO];
            } else {
                [self updateProfile:_displayName];
            }
        }];
    }
}

- (void)updateProfile:(NSString*)displayName
{
    if (!CURRENT_USER) {
        [self showError:@"Current user error"];
        return;
    }
    FIRUserProfileChangeRequest *request = [CURRENT_USER profileChangeRequest];
    [request setDisplayName:displayName];
    [request commitChangesWithCompletion:^(NSError * _Nullable error) {
        if (!error) {
            _displayName = CURRENT_USER.displayName;
        }
        [self updateAuthStatus:YES];
        UPDATE_SETTINGS();
    }];
}

- (void)updateAuthStatus:(BOOL)status
{
    _authStatus = status;
    [self updateSession];
    
    if (_authStatus) {
        if (_onDisplayCreatePoint) {
            
            [self displayCreatePoint];
            return;
        }
        if (_onDisplayChatPoint) {
            
            [self displayChatPoint];
            return;
        }
    } else {
        if (_onDisplayCreatePoint) {
            _onDisplayCreatePoint = NO;
            
            _onCreatePoint = NO;
            [self refreshCenterPoint];
            return;
        }
        if (_onDisplayChatPoint) {
            _onDisplayChatPoint = NO;
            
            return;
        }
    }
    
}

#pragma mark - Map -------------------------------------------------

- (UIView*)mapView
{
    return _mapView;
}

- (BOOL)isLocationManagerEnable
{
    return _mapView.isMyLocationEnabled;
}

- (void)setMapIndex:(NSInteger)mapIndex
{
    if (mapIndex < [self mapMinIndex] || mapIndex > [self mapMaxIndex]) {
        mapIndex = [self mapMinIndex];
    }
    _mapIndex = mapIndex;
    [_mapView setMapType:_mapIndex];
    if (_isActive) {
        [_mapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:_position.coordinate zoom:_zoom]];
    } else {
        [_mapView setCamera:[GMSCameraPosition cameraWithTarget:_position.coordinate zoom:_zoom]];
    }
}

- (NSInteger)mapIndex
{
    return _mapIndex;
}

- (NSInteger)mapMinIndex
{
    return 1;
}

- (NSInteger)mapMaxIndex
{
    return 4;
}

- (BOOL)isDarkMode
{
    return !(_mapIndex%2);
}

- (void)onCreatePoint:(BOOL)on
{
    _onCreatePoint = on;
    [self refreshCenterPoint];
}

#pragma mark - Map

- (void)mapViewDidStartTileRendering:(GMSMapView *)mapView
{
    //
}

- (void)mapViewDidFinishTileRendering:(GMSMapView *)mapView
{
    //
}

- (void)mapView:(GMSMapView *)mapView willMove:(BOOL)gesture
{
    //
}

- (void)mapViewSnapshotReady:(GMSMapView *)mapView
{
    //
}

- (void)mapView:(GMSMapView *)mapView idleAtCameraPosition:(GMSCameraPosition *)position
{
    [self updatePosition:position];
    [self refreshCenterPoint];
}

- (void)mapView:(GMSMapView *)mapView didLongPressAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    _coordinate = coordinate;
    [self onCreatePoint:YES];
    [self displayCreatePoint];
}

- (void)mapView:(GMSMapView *)mapView didTapAtCoordinate:(CLLocationCoordinate2D)coordinate
{
    [self onCreatePoint:NO];
    _mapInfo = @{@"lat":DOUBLE_VALUE(coordinate.latitude),
                               @"lng":DOUBLE_VALUE(coordinate.longitude)};
}

- (void)mapView:(GMSMapView *)mapView didTapInfoWindowOfMarker:(GMSMarker *)marker
{
    [self displayChatPoint];
}

- (void)mapView:(GMSMapView *)mapView didLongPressInfoWindowOfMarker:(GMSMarker *)marker
{
    
    NSString *pointId = marker.snippet;
    NSDictionary *point_marker = _point_marker[pointId];
    if (point_marker) {
        NSDictionary *point = point_marker[@"point"];
        
        // make dictionary for nonvisible point
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:TRANSLATE(@"Info") message:@"" preferredStyle:UIAlertControllerStyleAlert];
        
        // Copy field
        [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            textField.placeholder = TRANSLATE(@"Type name of channel");
            textField.secureTextEntry = NO;
        }];
        
        // Copy action
        UIAlertAction *copyAction = [UIAlertAction actionWithTitle:TRANSLATE(@"Copy marker") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSString *channelName = [[alertController.textFields.firstObject.text stripName] stringByTrimmingCharactersInSet:
                                        [NSCharacterSet whitespaceAndNewlineCharacterSet]];
            [self transferPoint:channelName description:marker.title latitude:marker.position.latitude longitude:marker.position.longitude];
        }];
        [alertController addAction:copyAction];
        
        // Send
        UIAlertAction *goExternalAction = [UIAlertAction actionWithTitle:TRANSLATE(@"Send location") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            //http://maps.apple.com/?address=Mexican+Restaurant&sll=50.894967,4.341626&z=10&t=s
            NSString *address = [NSString stringWithFormat:
                @"http://maps.apple.com/?q=%@&ll=%f,%f",
                                 [marker.title stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLUserAllowedCharacterSet],
                                 marker.position.latitude,
                                 marker.position.longitude];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:address]];
            //[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://maps.google.com/maps?q=London"]]
        }];
        [alertController addAction:goExternalAction];
        
        // Remove
        NSString *sender = point ? point[@"sender"] : nil;
        if (sender && [UID isEqualToString:sender]) {
            UIAlertAction *removeMarkerAction = [UIAlertAction actionWithTitle:TRANSLATE(@"Remove marker") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                [self removePoint:pointId];
            }];
            [alertController addAction:removeMarkerAction];
        }
        
        // Cancel
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:TRANSLATE(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:cancelAction];
        
        [[UIViewController currentViewController] presentViewController:alertController animated:YES completion:nil];
    }
    
    
}

- (BOOL)mapView:(GMSMapView *)mapView didTapMarker:(GMSMarker *)marker
{
    id point_marker = marker.snippet && marker.snippet.length ?
            [_point_marker objectForKey:marker.snippet] : nil;
    id point = point_marker ? point_marker[@"point"] : @{};
    _mapInfo = @{@"displayName":DISPLAY_NAME,
                               @"senderId":UID,
                               @"key":marker.snippet?:@"",
                               @"point":point,
                               @"lat":DOUBLE_VALUE(marker.position.latitude),
                               @"lng":DOUBLE_VALUE(marker.position.longitude)};
    return NO;
}

- (nullable UIView *)mapView:(GMSMapView *)mapView markerInfoContents:(GMSMarker *)marker
{
    return [self contentInfoView:marker];
}

- (void)mapView:(GMSMapView *)mapView didCloseInfoWindowOfMarker:(GMSMarker *)marker
{
    //
}

#pragma mark - Location

- (void)centerLocation
{
    if (_mapView.myLocation && _mapView.myLocation.class != NSNull.class) {
        _location = _mapView.myLocation;
    }
    if (_location && _location.class != NSNull.class) {
        [_mapView animateToLocation:_location.coordinate];
    }
    
    _stateLocation++;
    if (_stateLocation > 2) {
        _stateLocation = 0;
    }
    
    switch (_stateLocation) {
        case 0:
        {
            _followLocation = NO;
            [self setLocationManager:NO];
            break;
        }
        case 1:
        {
            _followLocation = YES;
            [self setLocationManager:YES];
            break;
        }
        case 2:
        {
            _followLocation = NO;
            [self setLocationManager:YES];
            break;
        }
        default:
            break;
    }
    
}

- (void)zoomPlus
{
    float zoom = _mapView.camera.zoom;
    if (zoom < _mapView.maxZoom) {
        [_mapView animateToZoom:zoom+1];
    }
}

- (void)zoomMinus
{
    float zoom = _mapView.camera.zoom;
    if (zoom > _mapView.minZoom) {
        [_mapView animateToZoom:zoom-1];
    }
}

- (void)setLocationManager:(BOOL)enable
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self isLocationManagerEnable] != enable) {
            _mapView.myLocationEnabled = enable;
        }
        NSDictionary *userInfo = @{@"source":[self.class description],
                                   @"followLocation":@(_followLocation),
                                   @"enableLocation":@(self.isLocationManagerEnable)};
        POST_NOTIFICATION(kRefreshView, userInfo);
        
    });
}

#pragma mark - Location delegates

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    [self updateLocation:[change objectForKey:NSKeyValueChangeNewKey]];
}

- (void)updatePosition:(GMSCameraPosition*)position
{
    _position = [[CLLocation alloc]
                 initWithLatitude:position.target.latitude longitude:position.target.longitude];
    _zoom = _mapView.camera.zoom;
    
    if (_followPosition) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [_mapView setCamera:[GMSCameraPosition cameraWithTarget:_location.coordinate zoom:_zoom]];
            //[_mapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:_location.coordinate zoom:_zoom]];
        });
    }
}

- (void)updateLocation:(CLLocation*)location
{
    if (location && location.class != NSNull.class &&
        !(_location.coordinate.latitude == location.coordinate.latitude &&
          _location.coordinate.longitude == location.coordinate.longitude)) {
        
        _location = location;
        _zoom = _mapView.camera.zoom;
        
        if (_followLocation) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [_mapView animateWithCameraUpdate:[GMSCameraUpdate setTarget:_location.coordinate]];
                
            });
        }
    }
}

#pragma mark - Points

- (void)appendPoint:(FIRDataSnapshot*)snapshot
{
    NSString *key = snapshot.key;
    NSDictionary *point = snapshot.value;
    [self appendMarker:point key:key];

}

- (void)updatePoint:(FIRDataSnapshot*)snapshot
{
    NSString *pointId = snapshot.key;
    NSDictionary *point = snapshot.value;
    if (pointId && point) {
        NSString *newRoomId = point[@"roomId"];
        if (newRoomId) {
            [self updatePointMarker:@{@"key":pointId,@"roomId":newRoomId}];
        }
    }
}

- (void)updatePointMarker:(NSDictionary*)userInfo
{
    if (userInfo && userInfo[@"key"] && userInfo[@"roomId"]) {
        NSString *key = userInfo[@"key"];
        NSString *roomId = userInfo[@"roomId"];
        NSMutableDictionary *pm = key && key.length ? MUTABLE(_point_marker[key]) : nil;
        if (!pm || !roomId || !roomId.length) {
            return;
        }
        NSMutableDictionary *point = MUTABLE(pm[@"point"]);
        point[@"roomId"] = roomId;
        pm[@"point"] = point;
        _point_marker[key] = pm;
    }
}

- (void)removePoint:(NSString*)key
{
    if (key) {
        [[REF(MAIN_POINT) child:key] removeValue];
    }
}

- (void)createPoint:(NSString*)description
{
    if (description.length) {
        [self createPoint:_coordinate description:description];
    } else {
        [ToastView showToast:@"Error - empty description" duration:2.0];
    }
    [self onCreatePoint:NO];
}

- (void)createPoint:(CLLocationCoordinate2D)coordinate
        description:(NSString*)description
{
    
    NSString *roomId = [self createRoom:description private:NO];
    if (!roomId) {
        [ToastView showToast:@"Error create point: not room id" duration:1];
        return;
    }
    if (_onNotificationPoint) {
        PLAY_SEND_POINT;
    }
    NSString *key = PUSH(REF(MAIN_POINT));
    if (key.length) {
        [REF(MAIN_POINT)
         updateChildValues:
         @{key: @{@"lat" : FLOAT_VALUE(coordinate.latitude),
                  @"lng" : FLOAT_VALUE(coordinate.longitude),
                  @"sender" : UID,
                  @"state" : description,
                  @"timestamp" : [FIRServerValue timestamp], //TS_LONG,
                  @"roomId": roomId}
           }];
    }
}

- (void)transferPoint:(NSString*)channelName description:(NSString*)description latitude:(CLLocationDegrees)latitude longitude:(CLLocationDegrees)longitude
{
    
    if (!channelName || !channelName.length) {
        [ToastView showToast:TRANSLATE(@"Type name of channel") duration:1];
        return;
    } else {
        if ([channelName isEqualToString:CHANNEL_NAME]) {
            [ToastView showToast:TRANSLATE(@"Type another name of channel") duration:1];
            return;
        }
        
    }
    
    NSString *roomId = [self createRoom:description private:NO channelName:channelName];
    if (!description.length || !roomId) {
        [ToastView showToast:TRANSLATE(@"Error created marker") duration:1];
        return;
    }
    
    NSString *key = PUSH(REF(MAIN_POINT_NAME(channelName)));
    if (key.length) {
        [REF(MAIN_POINT_NAME(channelName))
         updateChildValues:
         @{key: @{@"lat" : FLOAT_VALUE(latitude),
                  @"lng" : FLOAT_VALUE(longitude),
                  @"sender" : UID,
                  @"state" : description,
                  @"timestamp" : [FIRServerValue timestamp], //TS_LONG,
                  @"roomId": roomId}
           }];
        [ToastView showToast:TRANSLATE(@"Done") duration:1];
    }
}

#pragma mark - Markers

- (void)appendMarker:(NSDictionary*)point key:(NSString*)key
{
    if (key && key.length && point) {
        NSString *title = point[@"state"];
        GMSMarker *marker = [GMSMarker markerWithPosition:CLLocationCoordinate2DMake([point[@"lat"] doubleValue], [point[@"lng"] doubleValue])];
        marker.title = title;
        marker.snippet = key;
        UIImage *icon = [self imageWithCustomType:title];
        if (icon) {
            marker.icon = icon;
        }
        marker.map = _mapView;
        
        [_point_marker setObject:@{@"marker":marker,@"point":point} forKey:key];
        
        NSString *sender = point[@"sender"];
        if (_onNotificationPoint && !_points[key] &&
            sender && ![UID isEqualToString:sender]) {
            if (ON_BACKGROUND) {
                [self showNotification:key title:TRANSLATE(@"New marker") text:title?:@""];
            } else {
                PLAY_RECEIVE_POINT;
            }
            
        }
        
        NSString *roomId = _points[key];
        if (roomId && roomId.length) {
            [self pointRoom:key roomId:roomId roomName:title completion:nil];
        } else {
            _points[key] = @"";
            UPDATE_POINTS();
        }
    }
}

- (void)deletePoint:(NSString*)key
{
    if (key && key.length) {
        [_points removeObjectForKey:key];
        UPDATE_POINTS();
    }
    
    NSDictionary *obj = key && key.length ? _point_marker[key] : nil;
    if (!obj) {
        return;
    }
    
    NSDictionary *point = obj[@"point"];
    NSString *roomId = point ? point[@"roomId"] : @"";
    NSDictionary *userInfo = roomId ? @{@"key":key,@"roomId":roomId} : @{@"key":key};
    POST_NOTIFICATION(kRemoveMarker, userInfo);
    
    GMSMarker *marker = (GMSMarker*)obj[@"marker"];
    if (marker) {
        marker.map = nil;
    }
    [_point_marker removeObjectForKey:key];
    
    [self leaveRoom:roomId onRemove:YES];
    
    if (_onNotificationPoint) {
        PLAY_DELETE_POINT;
        [self removeNotification:key];
    }
    
}

#pragma mark - Dialogs

- (void)displayCreatePoint
{
    if (!_authStatus) {
        _onDisplayCreatePoint = YES;
        [self authWithDisplayName:YES];
        return;
    }
    _onDisplayCreatePoint = NO;
    
    [[UIViewController currentViewController] performSegueWithIdentifier:@"createShow" sender:self];
}

- (void)refreshCenterPoint
{
    [self refreshCenterPoint:NO];
    if (_onCreatePoint) {
        [self refreshCenterPoint:YES];
    }
}

- (void)refreshCenterPoint:(BOOL)visible
{
    if (!visible && _centerPoint) {
        [_centerPoint removeFromSuperview];
        _centerPoint = nil;
    }
    if (visible && !_centerPoint) {
        _centerPoint = [[CenterPoint alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _centerPoint.center = [_mapView.projection pointForCoordinate:_coordinate];
        
        _centerPoint.cornerRadius = 5.0;
        _centerPoint.pulseRadius = 25.0;
        _centerPoint.pulseDuration = 1.6;
        _centerPoint.mainColor = ![self isDarkMode] ? [UIColor whiteColor] : [UIColor redColor];
        _centerPoint.pulseColor = ![self isDarkMode] ? [UIColor redColor] : [UIColor whiteColor];
        
        [_centerPoint setup];
        [_mapView addSubview:_centerPoint];
    }
}

- (void)displayChatPoint
{
    if (!_authStatus) {
        _onDisplayChatPoint = NO;
        [self authWithDisplayName:YES];
        return;
    }
    _onDisplayChatPoint = NO;
    
    if (_mapInfo && _mapInfo[@"key"]) {
        NSDictionary *point = _mapInfo[@"point"];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self pointRoom:_mapInfo[@"key"] roomId:point[@"roomId"] roomName:point[@"state"] completion:^(NSDictionary *chatInfo) {
                if (chatInfo && chatInfo[@"roomId"]) {
                    [_chatViewController configureDataSource:_mapInfo chatInfo:chatInfo];
                    [[UIViewController currentViewController] presentViewController:_chatViewController animated:YES completion:^{
                        [_chatViewController.tableView reloadData];
                    }];
                } else {
                    [ToastView showToast:@"Error enter chat" duration:2.0];
                }
            }];
        });
    }
}


#pragma mark - Chat -----------------------------------------------------------------

- (void)updateSession
{
    
    if (!_authStatus) {
        return;
    }
    if (_channelName && _newChannelName &&
        ![_channelName isEqualToString:_newChannelName]) {
        
        // Map
        FIRDatabaseQuery *pointRef = REF(MAIN_POINT);
        [[pointRef queryOrderedByChild:@"timestamp"] removeAllObservers];
        [pointRef removeAllObservers];
        
        // NSLog(@"clearPoints");
        
        if (_point_marker && _point_marker.allKeys.count) {
            [_point_marker enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                NSDictionary *point = obj[@"point"];
                if (point && point[@"roomId"]) {
                    [self leaveRoom:point[@"roomId"]];
                }
                GMSMarker *marker = obj[@"marker"];
                if (marker) {
                    marker.map = nil;
                }
                [_points removeObjectForKey:key];
            }];
            UPDATE_POINTS();
        }
        [_point_marker removeAllObjects];
        [_mapView clear];
        
        
        // Chat
        // NSLog(@"clearSession");
        
        [REF(ConnectedRef) removeAllObservers];
        
        if (_sessionID) {
            FIRDatabaseReference *sessionRef = [REF(SessionRef(UID)) child:_sessionID];
            [self removePresenceOperation:sessionRef value:nil];
            
            FIRDatabaseReference *usernameRef = [[REF(UsersOnlineRef)
                                                  child:DISPLAY_NAME.lowercaseString]
                                                 child:_sessionID];
            [self removePresenceOperation:usernameRef value:nil];
        }
        
        FIRDatabaseReference *userRef = REF(UserRef(UID));
        [userRef removeAllObservers];
        [[userRef child:@"invites"] removeAllObservers];
        [[userRef child:@"notifications"] removeAllObservers];
        
        // Reload
        POST_NOTIFICATION(kRefreshView, @{@"reload":@(YES)});
        
    }
    
    // Commit
    _channelName = _newChannelName?:_channelName;
    _newChannelName = nil;
    
    // Map
    // NSLog(@"loadPoints");
    
    FIRDatabaseQuery *pointRef = REF(MAIN_POINT);
    [[pointRef queryOrderedByChild:@"timestamp"] observeEventType:FIRDataEventTypeChildAdded withBlock:^
     (FIRDataSnapshot * _Nonnull snapshot) {
         [self appendPoint:snapshot];
     }];
    [pointRef observeEventType:FIRDataEventTypeChildChanged withBlock:^
     (FIRDataSnapshot * _Nonnull snapshot) {
         [self updatePoint:snapshot];
     }];
    [pointRef observeEventType:FIRDataEventTypeChildRemoved withBlock:^
     (FIRDataSnapshot * _Nonnull snapshot) {
         [self deletePoint:snapshot.key];
     }];
    
    // Chat
    // NSLog(@"loadSession");
    
    // Monitor connection state so we can requeue disconnect operations if need be.
    [REF(ConnectedRef) observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [_presence_bits enumerateKeysAndObjectsUsingBlock:^(id key, NSDictionary* obj, BOOL *stop) {
            FIRDatabaseReference *ref = obj[@"ref"];
            id onlineValue = obj[@"onlineValue"];
            id offlineValue = obj[@"offlineValue"];
            [ref onDisconnectSetValue:offlineValue?:@""];
            [ref setValue:onlineValue?:@""];
        }];
    } withCancelBlock:nil];
    
    
    FIRDatabaseReference *sessionRef = REF(SessionRef(UID));
    _sessionID = PUSH(sessionRef);
    if (_sessionID) {
        // Queue up a presence operation to remove the session when presence is lost
        [self queuePresenceOperation:sessionRef onlineValue:BOOL_VALUE(YES) offlineValue:nil];
        
        
        // Register our username in the public user listing.
        FIRDatabaseReference *usernameRef = [[REF(UsersOnlineRef)
                                              child:DISPLAY_NAME.lowercaseString]
                                             child:_sessionID];
        [self queuePresenceOperation:usernameRef onlineValue:
         @{@"id":UID,@"name":DISPLAY_NAME} offlineValue:nil];
    }
    
    // Listen for state changes for the given user.
    FIRDatabaseReference *userRef = REF(UserRef(UID));
    [userRef observeEventType:FIRDataEventTypeValue withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self onUpdateUser:snapshot];
    }];
    
    // Listen for chat invitations from other users.
    [[userRef child:@"invites"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self onChatInvite:snapshot];
    }];
    
    // Listen for messages from moderators and adminstrators.
    [[userRef child:@"notifications"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
        [self onNotifications:snapshot];
    }];
    
    [ToastView showToast:[NSString stringWithFormat:
                          TRANSLATE(@"You logged as %@"), DISPLAY_NAME] duration:3.0];
    
    UPDATE_SETTINGS();
}

- (void)onUpdateUser:(FIRDataSnapshot*)snapshot
{
    //NSLog(@"onUpdateUser:%@", snapshot);
}

- (void)onChatInvite:(FIRDataSnapshot*)snapshot
{
    //NSLog(@"onChatInvite");
}

- (void)onNotifications:(FIRDataSnapshot*)snapshot
{
    //NSLog(@"onNotifications");
}

- (void)queuePresenceOperation:(FIRDatabaseReference*)ref onlineValue:(id)onlineValue offlineValue:(id)offlineValue
{
    if (ref) {
        if (_presence_bits[ref]) {
            [self removePresenceOperation:ref value:offlineValue];
        }
        [ref onDisconnectSetValue:offlineValue?:@""];
        [ref setValue:onlineValue?:@""];
        [_presence_bits setObject:
         @{@"ref":ref,@"onlineValue":onlineValue?:@"",@"offlineValue":offlineValue?:@""}
                           forKey:[ref description]];
    }
}

- (void)removePresenceOperation:(FIRDatabaseReference*)ref value:(id)value
{
    if (ref) {
        [ref cancelDisconnectOperations];
        [ref setValue:value?:@""];
        [_presence_bits removeObjectForKey:[ref description]];
    }
}

- (void)uploadPhoto:(UIImage*)image completion:(void (^)(NSURL*))completion
{
    // Save data
    NSData *photoData = UIImageJPEGRepresentation(image, 1);
    if (!photoData.length) {
        if (completion) {
            completion(nil);
        }
        return;
    }
    
    // Create a root reference
    FIRStorage *storage = [FIRStorage storage];
    FIRStorageReference *storageRef = [storage reference];
    
    // Create a reference to 'images/photo.jpg'
    FIRStorageReference *photoImagesRef = [[storageRef child:@"images"] child:[NSData simpleUUID]];
    
    // Create the file metadata
    FIRStorageMetadata *metadata = [[FIRStorageMetadata alloc] init];
    metadata.contentType = @"image/jpeg";
    
    // Upload file and metadata to the object 'images/photo.jpg'
    FIRStorageUploadTask *uploadTask = [photoImagesRef putData:photoData metadata:metadata];
    
    // Listen for state changes, errors, and completion of the upload.
    [uploadTask observeStatus:FIRStorageTaskStatusResume handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload resumed, also fires when the upload starts
       
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusPause handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload paused
        // Remove all observers
        [uploadTask removeAllObservers];
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusProgress handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload reported progress
        double percentComplete = 100.0 *
            (snapshot.progress.completedUnitCount) / (snapshot.progress.totalUnitCount);
        [ToastView showToast:[NSString stringWithFormat:TRANSLATE(@"Uploading - %.0f%%"), percentComplete]];
    }];
    
    [uploadTask observeStatus:FIRStorageTaskStatusSuccess handler:^(FIRStorageTaskSnapshot *snapshot) {
        // Upload completed successfully
        NSURL *downloadURL = snapshot.metadata.downloadURL;
        if (completion) {
            completion(downloadURL);
        }
        // Remove all observers
        [uploadTask removeAllObservers];
    }];
    
    // Errors only occur in the "Failure" case
    [uploadTask observeStatus:FIRStorageTaskStatusFailure handler:^(FIRStorageTaskSnapshot *snapshot) {
        if (snapshot.error != nil) {
            switch (snapshot.error.code) {
                case FIRStorageErrorCodeObjectNotFound:
                    [ToastView showToast:TRANSLATE(@"File doesn't exist") duration:3];
                    break;
                    
                case FIRStorageErrorCodeUnauthorized:
                    [ToastView showToast:TRANSLATE(@"User doesn't have permission to access file") duration:3];
                    break;
                    
                case FIRStorageErrorCodeCancelled:
                    [ToastView showToast:TRANSLATE(@"User canceled the upload") duration:3];
                    break;
                    
                case FIRStorageErrorCodeUnknown:
                    [ToastView showToast:TRANSLATE(@"Unknown error occurred, inspect the server response") duration:3];
                    break;
            }
            
        }
        // Remove all observers
        [uploadTask removeAllObservers];
    }];
    
    
    
}

#pragma mark - Room

- (void)pointRoom:(NSString*)pointId roomId:(NSString*)roomId roomName:(NSString*)roomName completion:(void (^)(NSDictionary*))completion
{
    if (pointId && roomName) {
        if (roomId) {
            [self enterRoom:pointId roomId:roomId roomName:roomName private:NO];
            if (completion) {
                completion(@{@"roomId":roomId});
            }
        } else {
            NSString *newRoomId = [self createRoom:roomName private:NO];
            if (newRoomId) {
                [self updatePointMarker:@{@"key":pointId,@"roomId":newRoomId}];
                [[REF(MAIN_POINT) child:pointId] updateChildValues:@{@"roomId":newRoomId}];
                [self enterRoom:pointId roomId:roomId roomName:roomName private:NO];
                if (completion) {
                    completion(@{@"roomId":roomId});
                }
            }
        }
    }
}

- (NSString*)createRoom:(NSString*)roomName private:(BOOL)private
{
    NSString *key = PUSH(REF(RoomRef));
    if (key && key.length) {
        [REF(RoomRef)
         updateChildValues:
         @{key: @{@"id" : key,
                  @"name" : roomName,
                  @"type" : private ? @"private" : @"public",
                  @"createdByUserId" : UID,
                  @"createdAt" : FIRServerValue.timestamp}}];
        if (private) {
            [REF(RoomRef) updateChildValues:@{key:@{@"authorizedUsers":@{UID:@YES}}}];
        }
    }
    return key;
}

- (NSString*)createRoom:(NSString*)roomName private:(BOOL)private channelName:(NSString*)channelName
{
    NSString *key = PUSH(REF(RoomRefName(channelName)));
    if (key && key.length) {
        [REF(RoomRefName(channelName))
         updateChildValues:
         @{key: @{@"id" : key,
                  @"name" : roomName,
                  @"type" : private ? @"private" : @"public",
                  @"createdByUserId" : UID,
                  @"createdAt" : FIRServerValue.timestamp}}];
        if (private) {
            [REF(RoomRefName(channelName)) updateChildValues:@{key:@{@"authorizedUsers":@{UID:@YES}}}];
        }
    }
    return key;
}

- (void)createMessage:(NSString*)roomId message:(NSDictionary*)message callback:(void (^)(NSString*))callback
{
    if (roomId && IS_DICTIONARY(message)) {
        FIRDatabaseReference *messageRef = [REF(MessageRef) child:roomId];
        NSString *key = PUSH(messageRef);
        if (key && key.length) {
            if (callback) {
                callback(key);
            }
            [[messageRef child:key] updateChildValues:message];
        }
        else {
            if (callback) callback(@"");
        }
    }
    else {
        if (callback) callback(@"");
    }
}

- (void)enterRoom:(NSString*)pointId roomId:(NSString*)roomId roomName:(NSString*)roomName private:(BOOL)private
{
    if (pointId && pointId.length && roomId && roomId.length) {
#warning on start reload unreaded
        // Reload messages
        if (_room_timestamp[roomId]) {
            [self leaveRoom:roomId];
        }
        
        // Set flag on enter
        if (_points[pointId]) {
            _points[pointId] = roomId;
            UPDATE_POINTS();
        }
        
        // Save entering this room to resume the session again later.
        FIRDatabaseReference *userRoomRef = REF(UserRoomRef(UID,roomId));
        [userRoomRef updateChildValues:
         @{userRoomRef.key: @{@"id" : userRoomRef.key,
                              @"name" : roomName,
                              @"active" : @YES}}];
        
        // Set presence bit for the room and queue it for removal on disconnect.
        if (_sessionID) {
            FIRDatabaseReference *presenceRef = REF(UserPresenceRef(roomId,UID,_sessionID));
            NSDictionary *onlineValue = @{@"id":UID, @"name":DISPLAY_NAME};
            [self queuePresenceOperation:presenceRef onlineValue:onlineValue offlineValue:nil];
        }
        
        
        _room_timestamp[roomId] = TS_LONG;
        [self updateUnreaded:pointId roomId:roomId];
        
        // Listen new
        [[[REF(MessageRef) child:roomId] queryOrderedByChild:@"timestamp"] observeEventType:FIRDataEventTypeChildAdded withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            
            if (IS_DICTIONARY(snapshot.value)) {
                NSMutableDictionary *message =
                    [NSMutableDictionary dictionaryWithDictionary:snapshot.value];
                
                message[@"key"] = snapshot.key;
                NSNumber *last_timestamp = LONG_VALUE([message[@"timestamp"] longValue]);
                if (_onNotificationRoom &&
                    (last_timestamp > _room_timestamp[roomId])) {
                    if (![UID isEqualToString:message[@"userId"]]) {
                        [self updateUnreaded:pointId roomId:roomId];
                        if (ON_BACKGROUND) {
                            NSMutableString *text = [NSMutableString stringWithString:message[@"message"]?:@"..."];
                            if ([text containsString:@"<http"]) {
                                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<([^>]*)>" options:0 error:nil];
                                [regex replaceMatchesInString:text options:0 range:NSMakeRange(0, text.length) withTemplate:TRANSLATE(@"<photo>")];
                            }
                            [self showNotification:pointId
                                             title:message[@"name"]?:@"=>"
                                              text:[NSString stringWithFormat:@" %@", text]];
                        } else {
                            PLAY_RECEIVE_MESSAGE;
                        }
                    }
                }
                NSDictionary *userInfo = @{@"roomId":roomId,@"message":message};
                POST_NOTIFICATION(kReceiveMessage, userInfo);
            }
        }];
        
        // Listen remove
        [[REF(MessageRef) child:roomId] observeEventType:FIRDataEventTypeChildRemoved withBlock:^(FIRDataSnapshot * _Nonnull snapshot) {
            POST_NOTIFICATION(kRemoveMessage, @{@"key":snapshot.key?:@""});
        }];
        
        POST_NOTIFICATION(kEnterRoom, @{@"roomId":roomId});
        
    }
}

- (void)clearUnreaded:(NSString*)pointId roomId:(NSString*)roomId
{
    if (pointId && roomId && _room_unreaded[roomId]) {
        [_room_unreaded removeObjectForKey:roomId];
        [self updateUnreaded:pointId roomId:roomId];
    }
}

- (void)updateUnreaded:(NSString*)pointId roomId:(NSString*)roomId
{
    if (roomId) {
        NSInteger unreaded = _room_unreaded[roomId] ? [_room_unreaded[roomId] integerValue] : -1;
        unreaded++;
        _room_unreaded[roomId] = INTEGER_VALUE(unreaded);
        
        if (pointId) {
            NSDictionary *pm = _point_marker[pointId];
            if (pm) {
                NSDictionary *point = pm[@"point"];
                GMSMarker *marker = pm[@"marker"];
                if (point && marker) {
                    NSString *title = point[@"state"];
                    UIImage *icon =
                        [self imageWithCustomType:title unreaded:unreaded];
                    if (icon) { marker.icon = icon; }
                }
            }
        }
    }
}

- (void)leaveRoom:(NSString*)pointId roomId:(NSString*)roomId
{
    if (pointId && roomId) {
        _room_unreaded[roomId] = @(-2);
        [self updateUnreaded:pointId roomId:roomId];
        [self leaveRoom:roomId];
    }
}

- (void)leaveRoom:(NSString*)roomId
{
    [self leaveRoom:roomId onRemove:NO];
}
- (void)leaveRoom:(NSString*)roomId onRemove:(BOOL)onRemove
{
    if (roomId && roomId.length) {
        // Remove message listeners
        [[REF(MessageRef) child:roomId] removeAllObservers];
        
        // Remove presence bit for the room and cancel on-disconnect removal.
        if (_sessionID) {
            FIRDatabaseReference *presenceRef = REF(UserPresenceRef(roomId,UID,_sessionID));
            [self removePresenceOperation:presenceRef value:nil];
        }
        
        // Remove session bit for the room.
        [REF(UserRoomRef(UID, roomId)) removeValue];
        
        // Remove chat and remove messages.
        if (onRemove) {
            [[REF(RoomRef) child:roomId] removeValue];
            [[REF(MessageRef) child:roomId] removeValue];
        }
        
        POST_NOTIFICATION(kLeaveRoom, @{@"roomId":roomId});
        [_room_timestamp removeObjectForKey:roomId];
        [_room_unreaded removeObjectForKey:roomId];
        
    }
}

#pragma mark - Notifications ----------------------------------------

- (void)saveState:(NSNotification*)notification
{
    UPDATE_SETTINGS();
}

- (void)dealloc {
    
    [self setLocationManager:NO];
    
    // Unsubscribe own notification
    [_mapView removeObserver:self forKeyPath:MY_LOCATION_KEY context:NULL];
    
    UNSUBSCRIBE_NOTIFICATIONS;
}

#pragma mark - Core Utils

- (void)showNotification:(NSString*)pointId title:(NSString*)title text:(NSString*)text
{
    if (pointId && pointId.length && text && text.length) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
            if (settings.authorizationStatus == UNAuthorizationStatusAuthorized) {
                UNMutableNotificationContent *content = [UNMutableNotificationContent new];
                content.title = title;
                content.body = text;
                content.sound = [UNNotificationSound defaultSound];
                UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1 repeats:NO];
                //UNLocationNotificationTrigger *locTrigger = [UNLocationNotificationTrigger triggerWithRegion:region repeats:NO];
                
                UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:pointId content:content trigger:trigger];
                
                [center addNotificationRequest:request withCompletionHandler:nil];
                
                [[UIApplication sharedApplication] setApplicationIconBadgeNumber:
                    [[UIApplication sharedApplication] applicationIconBadgeNumber] + 1];
            } else {
                //
            }
        }];
    }
}

- (void)removeNotification:(NSString*)pointId
{
    if (pointId && pointId.length) {
        UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
        [center removeDeliveredNotificationsWithIdentifiers:@[pointId]];
    }
}

- (void)showError:(NSString*)string
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [ToastView showToast:TRANSLATE(string) duration:3.0f completion:nil];
    });
}

- (void)showSuccess:(NSString*)string
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [ToastView showToast:TRANSLATE(string) duration:3.0f completion:nil];
    });
}

#pragma mark - Map Utils

- (UIImage*)imageWithCustomType:(NSString*)title
{
    return [self imageWithCustomType:title unreaded:-1];
}

- (UIImage*)imageWithCustomType:(NSString*)title unreaded:(NSInteger)unreaded
{
    UIImage *image = nil;
    NSString *string = @"💬";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\X+?)" options:NSRegularExpressionCaseInsensitive error:nil];
    NSArray* matches = [regex matchesInString:title options:0 range:NSMakeRange(0, title.length)];
    for (NSTextCheckingResult* match in matches) {
        NSString *_string = [title substringWithRange:match.range];
        if (_string.isEmoji) {
            string = _string;
            break;
        }
    }
    if (string.length) {
        
        NSMutableParagraphStyle *style = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        style.alignment = NSTextAlignmentCenter;
        NSDictionary *attributes =
        @{NSFontAttributeName            : [UIFont systemFontOfSize:24],
          NSParagraphStyleAttributeName  : style,
          NSForegroundColorAttributeName : [UIColor blueColor],
          NSBackgroundColorAttributeName : [UIColor clearColor]};
        
        NSDictionary *attributes_unreaded =
        @{NSFontAttributeName            : [UIFont boldSystemFontOfSize:8],
          NSParagraphStyleAttributeName  : style,
          NSForegroundColorAttributeName : [UIColor redColor],
          NSBackgroundColorAttributeName : [UIColor clearColor]};
        
        CGSize size = CGSizeMake(38, 38);
        CGRect rect = CGRectMake(0, 0, size.width, size.height);
        
        
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
        
        //begin
        CGContextRef ctx = UIGraphicsGetCurrentContext();
        
        // white stroke
        CGContextSaveGState(ctx);
        [[UIColor whiteColor] setStroke];
        [[UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, 2.5, 2.5)] stroke];
        CGContextRestoreGState(ctx);
        
        if (unreaded >= 0) {
            // in room stroke
            CGContextSaveGState(ctx);
            [[UIColor greenColor] setStroke];
            [[UIBezierPath bezierPathWithOvalInRect:CGRectInset(rect, 4., 4.)] stroke];
            CGContextRestoreGState(ctx);
        }
        
        //white fill
        CGContextSaveGState(ctx);
        [[UIColor whiteColor] setFill];
        CGContextFillEllipseInRect(ctx, CGRectInset(rect, 4.5, 4.5));
        CGContextRestoreGState(ctx);
        
        //emojii text
        [string drawInRect:CGRectInset(rect, 5.5, 5.5) withAttributes:attributes];
        
        if (unreaded > 0) {
            CGRect rect = CGRectMake(size.width-15, 0, 15, 15);
            // white fill
            CGContextSaveGState(ctx);
            [[UIColor whiteColor] setFill];
            CGContextFillEllipseInRect(ctx, CGRectInset(rect, .5, .5));
            CGContextRestoreGState(ctx);
            //unreaded text
            NSString *unreadedString = TO_STRING(INTEGER_VALUE(unreaded<99?unreaded:99));
            [unreadedString drawInRect:CGRectInset(rect, 1.5, 1.5) withAttributes:attributes_unreaded];
        }
        
        //end
        image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
    
    return image;
}

- (UIView*)contentInfoView:(GMSMarker *)marker
{
    CGSize size = CGSizeMake(150, 36);
    CGRect frame = CGRectMake(0, 0, size.width, size.height);
    UIView *contentView = [[UIView alloc] initWithFrame:frame];
    
    // title
    UITextView *textView = [[UITextView alloc] initWithFrame:frame];
    textView.font = [UIFont systemFontOfSize:16];
    textView.text = marker.title;
    [contentView addSubview:textView];
    //frame.size.width = textView.contentSize.width?:contentView.frame.size.width;
    frame.size.height = textView.contentSize.height?:frame.size.height;
    textView.frame = frame;
    
    // Extend frame
    frame.size.height += 8;
    contentView.frame = frame;
    
    return contentView;
}

- (NSString*)slf:(double)n append:(NSString*)append
{
    NSString *s = [NSString stringWithFormat:@"%li", [[NSNumber numberWithDouble:floor(n)] longValue]];
    return [s isEqualToString:@"0"] ? @"" : [s stringByAppendingString:append];
}

- (NSString*)timeSpan:(NSInteger)timeInMs
{
    double t = [INTEGER_VALUE(timeInMs) doubleValue];
    if(t < 1000)
        return [self slf:t append:TRANSLATE(@" ms")];
    if(t < 60000)
        return [self slf:t/1000 append:TRANSLATE(@" sec")];
    if(t < 3600000)
        return [self slf:t/60000 append:TRANSLATE(@" min")];
    if(t < 86400000)
        return [self slf:t/3600000 append:TRANSLATE(@" h")];
    return [self slf:t/86400000 append:TRANSLATE(@" d")];
    
    /*
     NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
     formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
     formatter.allowedUnits = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
     NSString *elapsed = [formatter stringFromDate:[NSDate date] toDate:[NSDate dateWithTimeIntervalSinceNow:[point[@"timestamp"] integerValue]]];
     */
    
}

#pragma mark - Another Utils

/*
+ (void)addPictureToAlbum:(UIImage *)image albumName:(NSString*)albumName
{
    PHFetchOptions *albumFetchOptions = [PHFetchOptions new];
    albumFetchOptions.predicate = [NSPredicate predicateWithFormat:@"%K like %@", @"title", albumName];
    PHFetchResult *album = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:albumFetchOptions];
    PHAssetCollection *assetCollection = album.firstObject;
    
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        
        PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:assetCollection];
        [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            NSLog(@"Error creating asset: %@", error);
        } else {
            //Add PHAsset to datasource
            //Update view
        }
    }];
}
*/

- (NSString *)displayDate:(NSNumber*)ts
{
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:[ts doubleValue] / 1000.];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    [dateFormatter setLocale:[NSLocale currentLocale]];
    
    return [dateFormatter stringFromDate:date];
}

- (NSString *)GetCurrentTimeStamp
{
    NSDateFormatter *objDateformat = [[NSDateFormatter alloc] init];
    [objDateformat setDateFormat:@"yyyy-MM-dd"];
    NSString *strTime = [objDateformat stringFromDate:[NSDate date]];
    NSString *strUTCTime = [self GetUTCDateTimeFromLocalTime:strTime];
    NSDate *objUTCDate  = [objDateformat dateFromString:strUTCTime];
    long long milliseconds = (long long)([objUTCDate timeIntervalSince1970] * 1000.0);
    
    return [NSString stringWithFormat:@"%lld",milliseconds];
    
}

- (NSString *)GetUTCDateTimeFromLocalTime:(NSString *)IN_strLocalTime
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *objDate    = [dateFormatter dateFromString:IN_strLocalTime];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithAbbreviation:@"UTC"]];
    NSString *strDateTime   = [dateFormatter stringFromDate:objDate];
    return strDateTime;
}

+ (NSTimeInterval)getUTCFormateDate{
    
    NSDateComponents *comps = [[NSCalendar currentCalendar]
                               components:NSCalendarUnitDay | NSCalendarUnitYear | NSCalendarUnitMonth
                               fromDate:[NSDate date]];
    [comps setHour:0];
    [comps setMinute:0];
    [comps setSecond:[[NSTimeZone systemTimeZone] secondsFromGMT]];
    
    return [[[NSCalendar currentCalendar] dateFromComponents:comps] timeIntervalSince1970];
}

- (UIImage*) circularImageWithImage:(UIImage*)inputImage borderColor:(UIColor*)borderColor borderWidth:(CGFloat)borderWidth
{
    
    CGRect rect = (CGRect){ .origin=CGPointZero, .size=inputImage.size };
    
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, inputImage.scale); {
        
        // Fill the entire circle with the border color.
        [borderColor setFill];
        [[UIBezierPath bezierPathWithOvalInRect:rect] fill];
        
        // Clip to the interior of the circle (inside the border).
        CGRect interiorBox = CGRectInset(rect, borderWidth, borderWidth);
        UIBezierPath *interior = [UIBezierPath bezierPathWithOvalInRect:interiorBox];
        [interior addClip];
        
        [inputImage drawInRect:rect];
        
    }
    
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return outputImage;
}


- (NSString*)pluralForm:(NSInteger)n form1:(NSString*)form1 form2:(NSString*)form2 form3:(NSString*)form3
{
    // pluralForm(100, "рубль", "рубля", "рублей")
    
    NSInteger _n = ABS(n) % 100;
    NSInteger _n1 = _n % 10;
    if (_n > 10 && _n < 20) {
        return form3;
    }
    if (_n1 > 1 && _n1 < 5) {
        return form2;
    }
    if (_n1 == 1) {
        return form1;
    }
    return form3;
}

+ (CGFloat)statusBarHeight
{
    CGSize statusBarSize = [[UIApplication sharedApplication] statusBarFrame].size;
    return MIN(statusBarSize.width, statusBarSize.height);
}

+ (NSString *)MIMEForFileURL:(NSURL *)url
{
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)url.pathExtension, NULL);
    CFStringRef mimeType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    return (NSString *)CFBridgingRelease(mimeType) ;
}

+ (void)imageFromURL:(NSURL*)attachmentURL withCompletion:(void (^)(UIImage*))completion
{
    if (![attachmentURL isFileURL]) {
        [[NSURLSession sharedSession] dataTaskWithRequest:[NSURLRequest requestWithURL:attachmentURL] completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            NSString *mime = [response MIMEType];
            if ([mime containsString:@"video"]) {
                AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:attachmentURL options:nil];
                AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
                generate1.appliesPreferredTrackTransform = YES;
                NSError *err = NULL;
                CMTime time = CMTimeMake(1, 2);
                CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:&err];
                if (completion) {
                    completion([[UIImage alloc] initWithCGImage:oneRef]);
                }
            }  else if ([mime containsString:@"image"]) {
                if (completion) {
                    completion([UIImage imageWithData:data]);
                }
            }
        }];
    } else {
        NSString *mime = [self MIMEForFileURL:attachmentURL];
        if ([mime containsString:@"video"]) {
            AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:attachmentURL options:nil];
            AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
            generate1.appliesPreferredTrackTransform = YES;
            NSError *err = NULL;
            CMTime time = CMTimeMake(1, 2);
            CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:&err];
            if (completion) {
                completion([[UIImage alloc] initWithCGImage:oneRef]);
            }
        }  else if ([mime containsString:@"image"]) {
            if (completion) {
                completion([UIImage imageWithData:[NSData dataWithContentsOfURL:attachmentURL]]);
            }
        }
    }
    
}

+ (void)showAnimated:(UIView*)view animated:(BOOL)animated withCompletion:(void (^)(void))completion
{
    CAKeyframeAnimation *transformAnimation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    transformAnimation.values = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(1.20, 1.20, 1.00)],
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.05, 1.05, 1.00)],
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.00, 1.00, 1.00)]];
    transformAnimation.keyTimes = @[@0.0, @0.5, @1.0];
    
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.fromValue = @0.5;
    opacityAnimation.toValue = @1.0;
    
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    animationGroup.animations = @[transformAnimation, opacityAnimation, opacityAnimation];
    animationGroup.duration = 0.2;
    animationGroup.fillMode = kCAFillModeForwards;
    animationGroup.removedOnCompletion = NO;
    
    [view.layer addAnimation:animationGroup forKey:@"showAlert"];
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(animationGroup.duration * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^{
        
        if (completion) {
            completion();
        }
    });
}


@end

@implementation CenterPoint

-(void)setup
{
    
    _mainLayer = [CAShapeLayer new];
    _mainLayer.backgroundColor = _mainColor.CGColor;
    _mainLayer.bounds = self.bounds;
    _mainLayer.cornerRadius = _cornerRadius;
    _mainLayer.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    _mainLayer.zPosition = -1;
    
    [self.layer addSublayer:_mainLayer];
    
    CAShapeLayer *pulse = [self createPulse];
    [self.layer insertSublayer:pulse below:_mainLayer];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void){
        //Background Thread
        [self createAnimationGroup];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [pulse addAnimation:_animationGroup forKey:@"pulse"];
        });
    });
}

-(CAShapeLayer *)createPulse
{
    CAShapeLayer *pulse = [CAShapeLayer new];
    pulse.backgroundColor = _pulseColor.CGColor;
    pulse.contentsScale = [UIScreen mainScreen].scale;
    pulse.bounds = self.bounds;
    pulse.cornerRadius = _cornerRadius;
    pulse.position = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
    pulse.zPosition = -2;
    pulse.opacity = 0;
    return pulse;
}

-(void)createAnimationGroup
{
    _animationGroup = [CAAnimationGroup new];
    _animationGroup.animations = @[[self createScaleAnimation], [self createOpacityAnimation]];
    _animationGroup.duration = (CFTimeInterval)_pulseDuration;
    _animationGroup.repeatCount = HUGE_VAL;
    //_animationGroup.repeatDuration = 0.7;
}

-(CABasicAnimation *)createScaleAnimation
{
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale.xy"];
    scaleAnimation.fromValue = [NSNumber numberWithInteger:1];
    scaleAnimation.toValue = [NSNumber numberWithDouble:(((double)_pulseRadius)/10) + 1.0];
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return scaleAnimation;
}

-(CAKeyframeAnimation *)createOpacityAnimation
{
    CAKeyframeAnimation *opacityAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    opacityAnimation.values = @[@0.8, @0.4, @0];//[[NSNumber numberWithFloat:0.8], [NSNumber numberWithFloat:0.4],[NSNumber numberWithFloat:0]];
    opacityAnimation.keyTimes = @[@0, @0.5, @1];
    opacityAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    return opacityAnimation;
}

@end

#define TOAST_VIEW_ANIMATION_DURATION  0.5f
#define TOAST_VIEW_OFFSET_BOTTOM  61.0f
#define TOAST_VIEW_OFFSET_LEFT_RIGHT  8.0f
#define TOAST_VIEW_OFFSET_TOP  76.0f
#define TOAST_VIEW_SHOW_DURATION  3.0f
#define TOAST_VIEW_SHOW_DELAY  0.0f
#define TOAST_VIEW_TAG 1024
#define TOAST_VIEW_TEXT_FONT_SIZE  17.0f

static UIColor *_backgroundColor = nil;
static UIColor *_textColor = nil;
static UIFont *_textFont = nil;
static CGFloat _cornerRadius = 0.0f;
static CGFloat _duration = TOAST_VIEW_SHOW_DURATION;
static CGFloat _maxWidth = 0.0f;
static CGFloat _maxHeight = 0.0f;
static NSInteger _maxLines = 0;
static CGFloat _offsetBottom = TOAST_VIEW_OFFSET_BOTTOM;
static CGFloat _offsetTop = TOAST_VIEW_OFFSET_TOP;
static UIEdgeInsets _textInsets;
static NSTextAlignment _textAligment = NSTextAlignmentCenter;

@implementation ToastView

#pragma mark - ToastView Config

+ (void)setAppearanceBackgroundColor:(UIColor *)backgroundColor {
    _backgroundColor = [backgroundColor copy];
}

+ (void)setAppearanceCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
}

+ (void)setAppearanceMaxWidth:(CGFloat)maxWidth {
    _maxWidth = maxWidth;
}

+ (void)setAppearanceMaxLines:(NSInteger)maxLines {
    _maxLines = maxLines;
}

+ (void)setAppearanceOffsetBottom:(CGFloat)offsetBottom {
    _offsetBottom = offsetBottom;
}

+ (void)setAppearanceTextAligment:(NSTextAlignment)textAlignment {
    _textAligment = textAlignment;
}

+ (void)setAppearanceTextColor:(UIColor *)textColor {
    _textColor = [textColor copy];
}

+ (void)setAppearanceTextFont:(UIFont *)textFont {
    _textFont = [textFont copy];
}

+ (void)setAppearanceTextInsets:(UIEdgeInsets)textInsets {
    _textInsets = textInsets;
}

+ (void)setToastViewShowDuration:(NSTimeInterval)duration {
    _duration = duration;
}

#pragma mark - ToastView Show

+ (void)showToast:(id)toast {
    return [self showToast:toast duration:_duration];
}

+ (void)showToast:(id)toast duration:(NSTimeInterval)duration {
    return [self showToast:toast duration:duration delay:TOAST_VIEW_SHOW_DELAY];
}

+ (void)showToast:(id)toast delay:(NSTimeInterval)delay {
    return [self showToast:toast duration:_duration delay:delay];
}

+ (void)showToast:(id)toast completion:(ToastBlock)completion {
    return [self showToast:toast duration:_duration completion:completion];
}

+ (void)showToast:(id)toast duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay {
    return [self showToast:toast duration:duration delay:delay completion:nil];
}

+ (void)showToast:(id)toast duration:(NSTimeInterval)duration completion:(ToastBlock)completion {
    return [self showToast:toast duration:duration delay:TOAST_VIEW_SHOW_DELAY completion:completion];
}

+ (void)showToast:(id)toast delay:(NSTimeInterval)delay completion:(ToastBlock)completion {
    return [self showToast:toast duration:_duration delay:delay completion:completion];
}

+ (void)showToast:(id)toast duration:(NSTimeInterval)duration delay:(NSTimeInterval)delay completion:(ToastBlock)completion {
    NSString *toastText = [NSString stringWithFormat:@"%@", toast];
    if (toastText.length < 1) {
        return;
    }
    toastText = TRANSLATE(toastText);
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIView *keyWindow = [self _keyWindow];
        if (!keyWindow) {
            return;
        }
        [[keyWindow viewWithTag:TOAST_VIEW_TAG] removeFromSuperview];
        [keyWindow endEditing:YES];
        
        UIView *toastView = [UIView new];
        toastView.translatesAutoresizingMaskIntoConstraints = NO;
        toastView.userInteractionEnabled = NO;
        toastView.backgroundColor = [self _backgroundColor];
        toastView.tag = TOAST_VIEW_TAG;
        toastView.clipsToBounds = YES;
        toastView.alpha = 0.0f;
        
        UILabel *toastLabel = [UILabel new];
        toastLabel.translatesAutoresizingMaskIntoConstraints = NO;
        toastLabel.font = [self _textFont];
        toastLabel.text = toastText;
        toastLabel.textColor = [self _textColor];
        toastLabel.textAlignment = _textAligment;
        toastLabel.numberOfLines = 0;
        
        [self _maxWidth];
        [self _maxHeight];
        
        // One line text's height
        CGFloat toastTextHeight = [@"HZ" sizeWithAttributes:@{ NSFontAttributeName:[self _textFont], }].height + 0.5f;
        
        // ToastView's textInsets
        if (UIEdgeInsetsEqualToEdgeInsets(_textInsets, UIEdgeInsetsZero)) {
            _textInsets = UIEdgeInsetsMake(toastTextHeight / 2.0f, toastTextHeight, toastTextHeight / 2.0f, toastTextHeight);
        }
        
        if (_cornerRadius <= 0.0f || _cornerRadius > toastTextHeight / 2.0f) {
            toastView.layer.cornerRadius = (toastTextHeight + _textInsets.top + _textInsets.bottom) / 2.0f;
        } else {
            toastView.layer.cornerRadius = _cornerRadius;
        }
        
        // ToastView's size
        CGSize toastLabelSize = [toastLabel sizeThatFits:CGSizeMake(_maxWidth - (_textInsets.left + _textInsets.right), _maxHeight - (_textInsets.top + _textInsets.bottom))];
        CGFloat toastViewWidth = (toastLabelSize.width + 0.5f) + (_textInsets.left + _textInsets.right);
        CGFloat toastViewHeight = (toastLabelSize.height + 0.5f) + (_textInsets.top + _textInsets.bottom);
        
        if (toastViewWidth > _maxWidth) {
            toastViewWidth = _maxWidth;
        }
        
        if (_maxLines > 0) {
            toastViewHeight = toastTextHeight * _maxLines + _textInsets.top + _textInsets.bottom;
        }
        
        if (toastViewHeight > _maxHeight) {
            toastViewHeight = _maxHeight;
        }
        
        NSDictionary *views = NSDictionaryOfVariableBindings(toastLabel, toastView);
        [toastView addSubview:toastLabel];
        [keyWindow addSubview:toastView];
        
        [toastView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:|-(%@)-[toastLabel]-(%@)-|", @(_textInsets.left), @(_textInsets.right)]
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [toastView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(%@)-[toastLabel]-(%@)-|", @(_textInsets.top), @(_textInsets.bottom)]
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        
        [keyWindow addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"H:[toastView(%@)]", @(toastViewWidth)]
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [keyWindow addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:[NSString stringWithFormat:@"V:|-(>=%@)-[toastView(<=%@)]-(%@)-|", @(_offsetTop), @(toastViewHeight), @(_offsetBottom)]
                                                                          options:0
                                                                          metrics:nil
                                                                            views:views]];
        [keyWindow addConstraint:[NSLayoutConstraint constraintWithItem:toastView
                                                              attribute:NSLayoutAttributeCenterX
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:keyWindow
                                                              attribute:NSLayoutAttributeCenterX
                                                             multiplier:1.0f
                                                               constant:0.0f]];
        [keyWindow layoutIfNeeded];
        
        [UIView animateWithDuration:TOAST_VIEW_ANIMATION_DURATION animations: ^{
            toastView.alpha = 1.0f;
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [UIView animateWithDuration:TOAST_VIEW_ANIMATION_DURATION animations: ^{
                toastView.alpha = 0.0f;
            } completion: ^(BOOL finished) {
                [toastView removeFromSuperview];
                
                ToastBlock block = [completion copy];
                if (block) {
                    block();
                }
            }];
        });
    });
}

#pragma mark - Private Methods

+ (UIFont *)_textFont {
    if (_textFont == nil) {
        _textFont = [UIFont systemFontOfSize:TOAST_VIEW_TEXT_FONT_SIZE];
    }
    return _textFont;
}

+ (UIColor *)_textColor {
    if (_textColor == nil) {
        _textColor = [UIColor whiteColor];
    }
    return _textColor;
}

+ (UIColor *)_backgroundColor {
    if (_backgroundColor == nil) {
        _backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.6f];
    }
    return _backgroundColor;
}

+ (CGFloat)_maxHeight {
    if (_maxHeight <= 0) {
        _maxHeight = [self _portraitScreenHeight] - (_offsetBottom + TOAST_VIEW_OFFSET_TOP);
    }
    
    return _maxHeight;
}

+ (CGFloat)_maxWidth {
    if (_maxWidth <= 0) {
        _maxWidth = [self _portraitScreenWidth] - (TOAST_VIEW_OFFSET_LEFT_RIGHT + TOAST_VIEW_OFFSET_LEFT_RIGHT);
    }
    return _maxWidth;
}

+ (CGFloat)_portraitScreenWidth {
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? CGRectGetWidth([UIScreen mainScreen].bounds) : CGRectGetHeight([UIScreen mainScreen].bounds);
}

+ (CGFloat)_portraitScreenHeight {
    return UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation) ? CGRectGetHeight([UIScreen mainScreen].bounds) : CGRectGetWidth([UIScreen mainScreen].bounds);
}

+ (UIView *)_keyWindow {
    return [UIApplication sharedApplication].delegate.window;
}

@end

