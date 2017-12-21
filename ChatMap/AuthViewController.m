//
//  AuthViewController.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 13.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "AuthViewController.h"
#import "AppCore.h"

@interface AuthViewController ()<UITextFieldDelegate>

@property (weak) IBOutlet UILabel *captionLabel;
@property (weak) IBOutlet UITextField *displayNameTextField;
@property (weak) IBOutlet UITextField *channelTextField;
@property (weak) IBOutlet UILabel *onNotificationPointLabel;
@property (weak) IBOutlet UISwitch *onNotificationPoint;
@property (weak) IBOutlet UILabel *onNotificationRoomLabel;
@property (weak) IBOutlet UISwitch *onNotificationRoom;
@property (weak) IBOutlet UITextField *avatarTextField;
@property (weak) IBOutlet UIButton *cancelButton;
@property (weak) IBOutlet UIButton *doneButton;

@end

@implementation AuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    _captionLabel.textAlignment = NSTextAlignmentCenter;
    _captionLabel.text = TRANSLATE(@"Authentication");
    
    _displayNameTextField.text = DISPLAY_NAME;
    _displayNameTextField.placeholder = TRANSLATE(@"Type your nickname...");
    
    _avatarTextField.text = AVATAR_NAME;
    _avatarTextField.placeholder = TRANSLATE(@"Type your avatar e-mail...");
    
    _onNotificationPoint.on = ON_NOTIFICATION_POINT;
    _onNotificationPointLabel.text = TRANSLATE(@"Notify about new markers");
    _onNotificationRoom.on = ON_NOTIFICATION_ROOM;
    _onNotificationRoomLabel.text = TRANSLATE(@"Notify about new messages");
    
    _channelTextField.text = CHANNEL_NAME;
    _channelTextField.placeholder = TRANSLATE(@"Type name of channel...");
    _channelTextField.delegate = self;
    
    
    BUTTON_TITLE(_cancelButton, TRANSLATE(@"Cancel"));
    BUTTON_TITLE(_doneButton, TRANSLATE(@"Done"));
    
    _cancelButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _cancelButton.layer.borderWidth = 1.0;
    _cancelButton.layer.cornerRadius = 10;
    _cancelButton.clipsToBounds = true;
    
    _doneButton.layer.borderColor = [UIColor whiteColor].CGColor;
    _doneButton.layer.borderWidth = 1.0;
    _doneButton.layer.cornerRadius = 10;
    _doneButton.clipsToBounds = true;
}

- (IBAction)dismiss:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{
        POST_NOTIFICATION(kRefreshView, @{@"source":[self.class description]});
    }];
}

-(IBAction)done:(id)sender
{
    if (!_displayNameTextField.text.length) {
        [ToastView showToast:@"Error connected on empty nickname"];
        return;
    }
    [APP setDisplayName:_displayNameTextField.text];
    [APP setAvatarName:_avatarTextField.text];
    [APP setOnNotificationPoint:_onNotificationPoint.isOn];
    [APP setOnNotificationRoom:_onNotificationRoom.isOn];
    [APP setChannelName:_channelTextField.text];
    [self dismissViewControllerAnimated:YES completion:^{
        POST_NOTIFICATION(kRefreshView, @{@"source":[self.class description]});
        [APP authWithDisplayName:NO];
    }];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    return YES;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
