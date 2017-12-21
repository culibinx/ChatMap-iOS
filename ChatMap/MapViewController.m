//
//  MapViewController.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 27.06.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "MapViewController.h"
#import "AppCore.h"

@interface MapViewController ()
{
    UIView *_mapView;
    BOOL _followLocation;
    BOOL _enableLocation;
}

@property (nonatomic, weak) IBOutlet UIButton *settingsButton;
@property (nonatomic, weak) IBOutlet UIButton *authButton;
@property (nonatomic, weak) IBOutlet UIButton *plusButton;
@property (nonatomic, weak) IBOutlet UIButton *minusButton;
@property (nonatomic, weak) IBOutlet UIButton *centerButton;

@end

@implementation MapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Subscribe notifications
    SUBSCRIBE_NOTIFICATION(kRefreshView,@selector(refreshView:));
    
    [self refreshMap];
    [APP setMapIndex:APP.mapIndex];
}

#pragma mark Actions

- (IBAction)showSettings:(id)sender
{
    [APP setMapIndex:APP.mapIndex+1];
    [self refreshMap];
}

- (IBAction)showAuth:(id)sender
{
    [APP authWithDisplayName:YES];
}

- (IBAction)centerLocation:(id)sender
{
    _centerButton.enabled = NO;
    [APP centerLocation];
}

- (IBAction)zoomPlus:(id)sender
{
    [APP zoomPlus];
    
}

- (IBAction)zoomMinus:(id)sender
{
    [APP zoomMinus];
}

- (void)refreshMap
{
    if (_mapView) {
        [_mapView removeFromSuperview];
        _mapView = nil;
    }
    
    _mapView = APP.mapView;
    [self.view insertSubview:_mapView atIndex:0];
    PREPCONSTRAINTS(_mapView);
    STRETCH_VIEW(self.view, _mapView);
    [self refreshButtons];
}

- (void)refreshButtons
{
    if (APP.isDarkMode) {
        BUTTON_IMAGE(_settingsButton,@"icon_select_map_white");
        BUTTON_IMAGE(_authButton,@"icon_chat_white");
        BUTTON_IMAGE(_plusButton,@"icon_plus_white");
        BUTTON_IMAGE(_minusButton,@"icon_minus_white");
        if (_enableLocation) {
            if (_followLocation) {
                BUTTON_IMAGE(_centerButton,@"icon_follow_map_enable");
            } else {
                BUTTON_IMAGE(_centerButton,@"icon_follow_map_disable_white");
            }
        } else {
            BUTTON_IMAGE(_centerButton,@"icon_center_white");
        }
    } else {
        BUTTON_IMAGE(_settingsButton,@"icon_select_map");
        BUTTON_IMAGE(_authButton,@"icon_chat");
        BUTTON_IMAGE(_plusButton,@"icon_plus");
        BUTTON_IMAGE(_minusButton,@"icon_minus");
        if (_enableLocation) {
            if (_followLocation) {
                BUTTON_IMAGE(_centerButton,@"icon_follow_map_enable");
            } else {
                BUTTON_IMAGE(_centerButton,@"icon_follow_map_disable");
            }
        } else {
            BUTTON_IMAGE(_centerButton,@"icon_center");
        }
    }
}

#pragma mark - Notifications
          
- (void)refreshView:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    if ([[[AppCore class] description] isEqualToString:userInfo[@"source"]]) {
        _followLocation = [userInfo[@"followLocation"] boolValue];
        _enableLocation = [userInfo[@"enableLocation"] boolValue];
        _centerButton.enabled = YES;
        [self refreshButtons];
    }
}

#pragma mark Utils

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    
    UNSUBSCRIBE_NOTIFICATIONS;
}

#pragma mark Seque

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:@"authShow"] ||
        [segue.identifier isEqualToString:@"createShow"]) {
        UIViewController *destination = segue.destinationViewController;
        destination.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        //AFBlurSegue *blurSegue = (AFBlurSegue *)segue;
        //blurSegue.blurRadius = 20;
        //blurSegue.tintColor = [UIColor colorWithRed:0 green:1 blue:0 alpha:0.1];
        //blurSegue.saturationDeltaFactor = 0.5;
        
    }
}


@end
