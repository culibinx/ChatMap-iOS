//
//  ChatViewController.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 05.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "ChatViewController.h"
#import "AppCore.h"

#import "ChatViewCell.h"
#import "ChatTextView.h"
#import "Message.h"
#import "IDMPhoto.h"
#import "IDMPhotoBrowser.h"
#import "SDImageCache.h"
#import "RFGravatarImageView.h"

@interface ChatViewController () <UINavigationControllerDelegate,UIImagePickerControllerDelegate>
{
    UITextView *_stateView;
    
    NSDictionary *_point;
    NSString *_key;
    
    NSString *_roomId;
    
    BOOL _isKeyboardShow;
    
    NSIndexPath *_indexPath;

}

//#warning make chat icons on user name
#warning make visual diff own messages
#warning disable unused actions edit and xz


@property (nonatomic, strong) NSMutableArray *messages;

@property (nonatomic, strong) NSArray *users;
@property (nonatomic, strong) NSArray *channels;
@property (nonatomic, strong) NSArray *emojis;
@property (nonatomic, strong) NSArray *commands;

@property (nonatomic, strong) NSArray *searchResult;

@property (nonatomic, strong) UIWindow *pipWindow;

@property (nonatomic, weak) Message *editingMessage;

@end

@implementation ChatViewController

#pragma mark - Init

- (instancetype)init
{
    self = [super initWithTableViewStyle:UITableViewStylePlain];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

+ (UITableViewStyle)tableViewStyleForCoder:(NSCoder *)decoder
{
    return UITableViewStylePlain;
}

- (void)commonInit
{
    [[NSNotificationCenter defaultCenter] addObserver:self.tableView selector:@selector(reloadData) name:UIContentSizeCategoryDidChangeNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textInputbarDidMove:) name:SLKTextInputbarDidMoveNotification object:nil];
    
    // Register a SLKTextView subclass, if you need any special appearance and/or behavior customisation.
    [self registerClassForTextView:[ChatTextView class]];
    

}

#pragma mark - Main

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self prepareView];
    
    // Datasource
    [self configureDataSource];
    
    // SLKTVC's configuration
    self.bounces = YES;
    self.shakeToClearEnabled = YES;
    self.keyboardPanningEnabled = YES;
    self.shouldScrollToBottomAfterKeyboardShows = NO;
    self.inverted = YES;
    
    [self.leftButton setImage:[UIImage imageNamed:@"icon_upload"] forState:UIControlStateNormal];
    //[self.leftButton setTintColor:[UIColor grayColor]];
    
    [self.rightButton setTitle:TRANSLATE(@"Send") forState:UIControlStateNormal];
    
    self.textInputbar.autoHideRightButton = YES;
    self.textInputbar.maxCharCount = 1256;
    self.textInputbar.counterStyle = SLKCounterStyleSplit;
    self.textInputbar.counterPosition = SLKCounterPositionTop;
    
    [self.textInputbar.editorTitle setTextColor:[UIColor darkGrayColor]];
    [self.textInputbar.editorLeftButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    [self.textInputbar.editorRightButton setTintColor:[UIColor colorWithRed:0.0/255.0 green:122.0/255.0 blue:255.0/255.0 alpha:1.0]];
    
    self.typingIndicatorView.canResignByTouch = YES;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[ChatViewCell class] forCellReuseIdentifier:ChatCellIdentifier];
    
    [self.autoCompletionView registerClass:[ChatViewCell class] forCellReuseIdentifier:AutoCompletionCellIdentifier];
    [self registerPrefixesForAutoCompletion:@[@"@", @"#", @":", @"+:", @"/"]];
    
    [self.textView registerMarkdownFormattingSymbol:@"*" withTitle:@"Bold"];
    [self.textView registerMarkdownFormattingSymbol:@"_" withTitle:@"Italics"];
    [self.textView registerMarkdownFormattingSymbol:@"~" withTitle:@"Strike"];
    [self.textView registerMarkdownFormattingSymbol:@"`" withTitle:@"Code"];
    [self.textView registerMarkdownFormattingSymbol:@"```" withTitle:@"Preformatted"];
    [self.textView registerMarkdownFormattingSymbol:@">" withTitle:@"Quote"];
    
    // Subscribe notifications
    SUBSCRIBE_NOTIFICATION(kRemoveMarker,@selector(removeMarker:));
    SUBSCRIBE_NOTIFICATION(kReceiveMessage,@selector(receiveMessage:));
    SUBSCRIBE_NOTIFICATION(kRefreshView,@selector(refreshView:));
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    _indexPath = nil;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)prepareView
{
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectZero];
    headerView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    headerView.alpha = .7;
    
    CGFloat bH = 32;
    CGFloat bW = 32;
    CGFloat eI = 5;
    CGFloat panelHeight = eI + bH + eI;
    CGFloat statusBarHeight = [AppCore statusBarHeight];
    
    UIButton *settingsButton = BUTTON_FRAME(0, 0, bH, bW);
    BUTTON_IMAGE(settingsButton, @"icon_chat");
    BUTTON_ACTION(settingsButton, @selector(settings:));
    [headerView addSubview:settingsButton];
    PREPCONSTRAINTS(settingsButton);
    ALIGN_VIEW_TOP_CONSTANT(headerView, settingsButton, eI);
    ALIGN_VIEW_LEFT_CONSTANT(headerView, settingsButton, eI);
    CONSTRAIN_SIZE(headerView, settingsButton,
                   settingsButton.frame.size.width, settingsButton.frame.size.height);
    
    UIButton *dismissButton = BUTTON_FRAME(0, 0, bH, bW);
    BUTTON_IMAGE(dismissButton, @"icon_close");
    BUTTON_ACTION(dismissButton, @selector(dismiss:));
    [headerView addSubview:dismissButton];
    PREPCONSTRAINTS(dismissButton);
    ALIGN_VIEW_TOP_CONSTANT(headerView, dismissButton, eI);
    ALIGN_VIEW_RIGHT_CONSTANT(headerView, dismissButton, -eI);
    CONSTRAIN_SIZE(headerView, dismissButton,
                   dismissButton.frame.size.width, dismissButton.frame.size.height);
    
    _stateView = [[UITextView alloc] init];
    _stateView.backgroundColor = [UIColor groupTableViewBackgroundColor];
    if (_point) {
        _stateView.text = _point[@"state"];
    }
    _stateView.textAlignment = NSTextAlignmentCenter;
    [headerView addSubview:_stateView];
    PREPCONSTRAINTS(_stateView);
    ALIGN_VIEW_TOP_CONSTANT(headerView, _stateView, eI);
    ALIGN_VIEW_BOTTOM_CONSTANT(headerView, _stateView, -eI);
    ALIGN_VIEW_LEFT_CONSTANT(headerView, _stateView, bW+15);
    ALIGN_VIEW_RIGHT_CONSTANT(headerView, _stateView, -(bW+15));
    
    UIView *topLineView = [[UIView alloc] init];
    topLineView.backgroundColor = [UIColor lightGrayColor];
    [headerView addSubview:topLineView];
    PREPCONSTRAINTS(topLineView);
    CONSTRAIN_HEIGHT(headerView, topLineView, 1.0)
    STRETCH_VIEW_H(headerView, topLineView);
    ALIGN_VIEW_TOP_CONSTANT(headerView, topLineView, 0);
    
    UIView *bottomLineView = [[UIView alloc] init];
    bottomLineView.backgroundColor = [UIColor lightGrayColor];;
    [headerView addSubview:bottomLineView];
    PREPCONSTRAINTS(bottomLineView);
    CONSTRAIN_HEIGHT(headerView, bottomLineView, 1.0)
    //ALIGN_VIEW_LEFT_CONSTANT(headerView, bottomLineView, 2*eI+bW);
    //ALIGN_VIEW_RIGHT_CONSTANT(headerView, bottomLineView, -(2*eI+bW));
    STRETCH_VIEW_H(headerView, bottomLineView);
    ALIGN_VIEW_BOTTOM_CONSTANT(headerView, bottomLineView, 0);
    
    [self.view addSubview:headerView];
    PREPCONSTRAINTS(headerView);
    ALIGN_VIEW_TOP_CONSTANT(self.view, headerView, statusBarHeight);
    STRETCH_VIEW_H(self.view, headerView);
    CONSTRAIN_HEIGHT(self.view, headerView, panelHeight);
    
}

- (void)settings:(id)sender
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:TRANSLATE(@"Settings") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    /*
    UIAlertAction *reAuthAction = [UIAlertAction actionWithTitle:TRANSLATE(@"Authentication") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [APP authWithDisplayName:YES];
    }];
    [alertController addAction:reAuthAction];
    */
    UIAlertAction *leaveRoomAction = [UIAlertAction actionWithTitle:TRANSLATE(@"Leave chat") style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [APP leaveRoom:_key roomId:_roomId];
        [self dismiss:self];
    }];
    [alertController addAction:leaveRoomAction];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:TRANSLATE(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
    
}

- (void)dismiss:(id)sender
{
    if (_isKeyboardShow) {
        [self dismissKeyboard:NO];
    }
    [APP clearUnreaded:_key roomId:_roomId];
    [self dismissViewControllerAnimated:YES completion:^{
        POST_NOTIFICATION(kRefreshView, @{@"source":[self.class description]});
    }];
}

#pragma mark - Notifications

- (void)receiveMessage:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    NSString *roomId = userInfo[@"roomId"];
    if (_roomId && [_roomId isEqualToString:roomId]) {
        id obj = userInfo[@"message"];
        if (obj && IS_DICTIONARY(obj) && obj[@"key"]) {
            Message *message = [[Message alloc] init];
            message.key = obj[@"key"];
            message.userId = obj[@"userId"];
            message.name = obj[@"name"];
            message.message = obj[@"message"];
            message.timestamp = LONG_VALUE([obj[@"timestamp"] longValue]);
            message.type = obj[@"type"];
            message.avatar = obj[@"avatar"];
            
            [self appendMessage:message];
        }
    }
}

- (void)removeMarker:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    if (_key && [_key isEqualToString:userInfo[@"key"]]) {
        [self dismiss:self];
    }
}

- (void)refreshView:(NSNotification*)notification
{
    NSDictionary *userInfo = [notification userInfo];
    if (userInfo[@"reload"]) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    if (userInfo[@"updatePhoto"] && _indexPath) {
        
        [self.tableView reloadRowsAtIndexPaths:@[_indexPath]
                              withRowAnimation:UITableViewRowAnimationNone];
    }
}

#pragma mark - Utils

- (void)appendMessage:(Message*)message
{
    if (!message || !message.key) {
        return;
    }
    if ([self.messages containsObject:message]) {
        [self.messages removeObject:message];
        [self.tableView reloadData];
    }
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:0];
    UITableViewRowAnimation rowAnimation = self.inverted ? UITableViewRowAnimationBottom : UITableViewRowAnimationTop;
    UITableViewScrollPosition scrollPosition = self.inverted ? UITableViewScrollPositionBottom : UITableViewScrollPositionTop;
    
    [self.tableView beginUpdates];
    [self.messages insertObject:message atIndex:0];
    [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:rowAnimation];
    [self.tableView endUpdates];
    
    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:scrollPosition animated:YES];
    
    // Fixes the cell from blinking (because of the transform, when using translucent cells)
    // See https://github.com/slackhq/SlackTextViewController/issues/94#issuecomment-69929927
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    
}

#pragma mark - Lifeterm

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    UNSUBSCRIBE_NOTIFICATIONS;
}

#pragma mark - DataSource

- (void)configureDataSource
{
    //NSMutableArray *array = [[NSMutableArray alloc] init];
    //NSArray *reversed = [[array reverseObjectEnumerator] allObjects];
    
    self.messages = self.messages?:[NSMutableArray array];
    
    self.users = @[];
    self.channels = @[];
    self.emojis = @[];
    self.commands = @[];
    
}

- (void)configureDataSource:(NSDictionary *)mapInfo chatInfo:(NSDictionary *)chatInfo
{
    if (mapInfo) {
        _point = mapInfo[@"point"];
        _key = mapInfo[@"key"];
        if (_point) {
            _stateView.text = _point[@"state"];
            //[_stateView sizeToFit];
        }
    }
    
    if (chatInfo && chatInfo[@"roomId"] && ![chatInfo[@"roomId"] isEqualToString:_roomId]) {
        self.messages = [NSMutableArray array];
        [self.tableView reloadData];
        _roomId = chatInfo[@"roomId"];
    }
}

#pragma mark - Action Methods

- (void)hideOrShowTextInputbar:(id)sender
{
    BOOL hide = !self.textInputbarHidden;
    
    UIImage *image = hide ? [UIImage imageNamed:@"icn_arrow_up"] : [UIImage imageNamed:@"icn_arrow_down"];
    UIBarButtonItem *buttonItem = (UIBarButtonItem *)sender;
    
    [self setTextInputbarHidden:hide animated:YES];
    
    [buttonItem setImage:image];
}

- (void)fillWithText:(id)sender
{
    if (self.textView.text.length == 0)
    {
        int sentences = (arc4random() % 4);
        if (sentences <= 1) sentences = 1;
        self.textView.text = @"bla-bla";
    }
    else {
        [self.textView slk_insertTextAtCaretRange:[NSString stringWithFormat:@" %@", @"bla-bla"]];
    }
}

- (void)didLongPressCell:(UIGestureRecognizer *)gesture
{
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }
    
#ifdef __IPHONE_8_0
    if (SLK_IS_IOS8_AND_HIGHER && [UIAlertController class]) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        alertController.popoverPresentationController.sourceView = gesture.view.superview;
        alertController.popoverPresentationController.sourceRect = gesture.view.frame;
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Edit Message" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self editCellMessage:gesture];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:NULL]];
        
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    }
    else {
        [self editCellMessage:gesture];
    }
#else
    [self editCellMessage:gesture];
#endif
}

- (void)editCellMessage:(UIGestureRecognizer *)gesture
{
    ChatViewCell *cell = (ChatViewCell *)gesture.view;
    
    self.editingMessage = self.messages[cell.indexPath.row];
    
    [self editText:self.editingMessage.message];
    
    [self.tableView scrollToRowAtIndexPath:cell.indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)editRandomMessage:(id)sender
{
    int sentences = (arc4random() % 10);
    if (sentences <= 1) sentences = 1;
    
    [self editText:@"bla-bla"];
}

- (void)editLastMessage:(id)sender
{
    if (self.textView.text.length > 0) {
        return;
    }
    
    NSInteger lastSectionIndex = [self.tableView numberOfSections]-1;
    NSInteger lastRowIndex = [self.tableView numberOfRowsInSection:lastSectionIndex]-1;
    
    Message *lastMessage = [self.messages objectAtIndex:lastRowIndex];
    
    [self editText:lastMessage.message];
    
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:lastRowIndex inSection:lastSectionIndex] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)togglePIPWindow:(id)sender
{
    if (!_pipWindow) {
        [self showPIPWindow:sender];
    }
    else {
        [self hidePIPWindow:sender];
    }
}

- (void)showPIPWindow:(id)sender
{
    CGRect frame = CGRectMake(CGRectGetWidth(self.view.frame) - 60.0, 0.0, 50.0, 50.0);
    frame.origin.y = CGRectGetMinY(self.textInputbar.frame) - 60.0;
    
    _pipWindow = [[UIWindow alloc] initWithFrame:frame];
    _pipWindow.backgroundColor = [UIColor blackColor];
    _pipWindow.layer.cornerRadius = 10.0;
    _pipWindow.layer.masksToBounds = YES;
    _pipWindow.hidden = NO;
    _pipWindow.alpha = 0.0;
    
    [[UIApplication sharedApplication].keyWindow addSubview:_pipWindow];
    
    [UIView animateWithDuration:0.25
                     animations:^{
                         _pipWindow.alpha = 1.0;
                     }];
}

- (void)hidePIPWindow:(id)sender
{
    [UIView animateWithDuration:0.3
                     animations:^{
                         _pipWindow.alpha = 0.0;
                     }
                     completion:^(BOOL finished) {
                         _pipWindow.hidden = YES;
                         _pipWindow = nil;
                     }];
}

- (void)textInputbarDidMove:(NSNotification *)note
{
    if (!_pipWindow) {
        return;
    }
    
    CGRect frame = self.pipWindow.frame;
    frame.origin.y = [note.userInfo[@"origin"] CGPointValue].y - 60.0;
    
    self.pipWindow.frame = frame;
}


#pragma mark - Overriden Methods

- (BOOL)ignoreTextInputbarAdjustment
{
    return [super ignoreTextInputbarAdjustment];
}

- (BOOL)forceTextInputbarAdjustmentForResponder:(UIResponder *)responder
{
    if ([responder isKindOfClass:[UIAlertController class]]) {
        return YES;
    }
    
    // On iOS 9, returning YES helps keeping the input view visible when the keyboard if presented from another app when using multi-tasking on iPad.
    return SLK_IS_IPAD;
}

- (void)didChangeKeyboardStatus:(SLKKeyboardStatus)status
{
    // Notifies the view controller that the keyboard changed status.
    _isKeyboardShow = status == SLKKeyboardStatusDidShow;
    /*
    switch (status) {
        case SLKKeyboardStatusWillShow:
            return NSLog(@"Will Show");
        case SLKKeyboardStatusDidShow:
            return NSLog(@"Did Show");
        case SLKKeyboardStatusWillHide:
            return NSLog(@"Will Hide");
        case SLKKeyboardStatusDidHide:
            return NSLog(@"Did Hide");
    }
    */
}

- (void)textWillUpdate
{
    // Notifies the view controller that the text will update.
    
    [super textWillUpdate];
}

- (void)textDidUpdate:(BOOL)animated
{
    // Notifies the view controller that the text did update.
    
    [super textDidUpdate:animated];
}

- (void)didPressLeftButton:(id)sender
{
    // Notifies the view controller when the left button's action has been triggered, manually.
    
    [super didPressLeftButton:sender];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:TRANSLATE(@"Attachments") message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *takePhoto = [UIAlertAction actionWithTitle:TRANSLATE(@"Take Photo") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        [self presentViewController:picker animated:YES completion:NULL];
    }];
    [alertController addAction:takePhoto];
    
    UIAlertAction *selectPhoto = [UIAlertAction actionWithTitle:TRANSLATE(@"Select Photo") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.allowsEditing = YES;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        [self presentViewController:picker animated:YES completion:NULL];
    }];
    [alertController addAction:selectPhoto];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:TRANSLATE(@"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
    }];
    [alertController addAction:cancelAction];
    
    [self presentViewController:alertController animated:YES completion:nil];
   
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    [APP uploadPhoto:chosenImage completion:^(NSURL *downloadURL) {
        if (downloadURL) {
            [self.textView slk_insertTextAtCaretRange:[NSString stringWithFormat:@"<%@> ",
                                                       downloadURL.absoluteString]];
        }
    }];
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)didPressRightButton:(id)sender
{
    // Notifies the view controller when the right button's action has been triggered, manually or by using the keyboard return key.
    
    // This little trick validates any pending auto-correction or auto-spelling just after hitting the 'Send' button
    [self.textView refreshFirstResponder];
    
    Message *message = [Message new];
    message.userId = UID;
    message.timestamp = TS_LONG;
    message.type = @"default";
    message.name = DISPLAY_NAME;
    message.avatar = AVATAR_NAME;
    message.message = [self.textView.text copy];
    
    //NSLog(@"message.avatar:%@", message.avatar);
    
    [APP createMessage:_roomId message:[message dictionary] callback:^(NSString * key) {
        if (key && key.length) {
            message.key = key;
            [self appendMessage:message];
            if (ON_NOTIFICATION_ROOM) {
                PLAY_SEND_MESSAGE;
            }
        }
    }];
    
    [super didPressRightButton:sender];
}

- (void)didPressArrowKey:(UIKeyCommand *)keyCommand
{
    if ([keyCommand.input isEqualToString:UIKeyInputUpArrow] && self.textView.text.length == 0) {
        [self editLastMessage:nil];
    }
    else {
        [super didPressArrowKey:keyCommand];
    }
}

- (NSString *)keyForTextCaching
{
    return [[NSBundle mainBundle] bundleIdentifier];
}

- (void)didPasteMediaContent:(NSDictionary *)userInfo
{
    // Notifies the view controller when the user has pasted a media (image, video, etc) inside of the text view.
    [super didPasteMediaContent:userInfo];
    
    SLKPastableMediaType mediaType = [userInfo[SLKTextViewPastedItemMediaType] integerValue];
    NSString *contentType = userInfo[SLKTextViewPastedItemContentType];
    id data = userInfo[SLKTextViewPastedItemData];
    
    NSLog(@"%s : %@ (type = %ld) | data : %@",__FUNCTION__, contentType, (unsigned long)mediaType, data);
}

- (void)willRequestUndo
{
    // Notifies the view controller when a user did shake the device to undo the typed text
    
    [super willRequestUndo];
}

- (void)didCommitTextEditing:(id)sender
{
    // Notifies the view controller when tapped on the right "Accept" button for commiting the edited text
    self.editingMessage.message = [self.textView.text copy];
    
    [self.tableView reloadData];
    
    [super didCommitTextEditing:sender];
}

- (void)didCancelTextEditing:(id)sender
{
    // Notifies the view controller when tapped on the left "Cancel" button
    
    [super didCancelTextEditing:sender];
}

- (BOOL)canPressRightButton
{
    return [super canPressRightButton];
}

- (BOOL)canShowTypingIndicator
{
#if DEBUG_CUSTOM_TYPING_INDICATOR
    return YES;
#else
    return [super canShowTypingIndicator];
#endif
}

- (BOOL)shouldProcessTextForAutoCompletion:(NSString *)text
{
    return [super shouldProcessTextForAutoCompletion:text];
}

- (BOOL)shouldDisableTypingSuggestionForAutoCompletion
{
    return [super shouldDisableTypingSuggestionForAutoCompletion];
}

- (void)didChangeAutoCompletionPrefix:(NSString *)prefix andWord:(NSString *)word
{
    NSArray *array = nil;
    
    self.searchResult = nil;
    
    if ([prefix isEqualToString:@"@"]) {
        if (word.length > 0) {
            array = [self.users filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
        else {
            array = self.users;
        }
    }
    else if ([prefix isEqualToString:@"#"] && word.length > 0) {
        array = [self.channels filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
    }
    else if (([prefix isEqualToString:@":"] || [prefix isEqualToString:@"+:"]) && word.length > 1) {
        array = [self.emojis filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
    }
    else if ([prefix isEqualToString:@"/"] && self.foundPrefixRange.location == 0) {
        if (word.length > 0) {
            array = [self.commands filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"self BEGINSWITH[c] %@", word]];
        }
        else {
            array = self.commands;
        }
    }
    
    if (array.count > 0) {
        array = [array sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    self.searchResult = [[NSMutableArray alloc] initWithArray:array];
    
    BOOL show = (self.searchResult.count > 0);
    
    [self showAutoCompletionView:show];
}

- (CGFloat)heightForAutoCompletionView
{
    CGFloat cellHeight = [self.autoCompletionView.delegate tableView:self.autoCompletionView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    return cellHeight*self.searchResult.count;
}


#pragma mark - SLKTextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldOfferFormattingForSymbol:(NSString *)symbol
{
    if ([symbol isEqualToString:@">"]) {
        
        NSRange selection = textView.selectedRange;
        
        // The Quote formatting only applies new paragraphs
        if (selection.location == 0 && selection.length > 0) {
            return YES;
        }
        
        // or older paragraphs too
        NSString *prevString = [textView.text substringWithRange:NSMakeRange(selection.location-1, 1)];
        
        if ([[NSCharacterSet newlineCharacterSet] characterIsMember:[prevString characterAtIndex:0]]) {
            return YES;
        }
        
        return NO;
    }
    
    return [super textView:textView shouldOfferFormattingForSymbol:symbol];
}

- (BOOL)textView:(SLKTextView *)textView shouldInsertSuffixForFormattingWithSymbol:(NSString *)symbol prefixRange:(NSRange)prefixRange
{
    if ([symbol isEqualToString:@">"]) {
        return NO;
    }
    
    return [super textView:textView shouldInsertSuffixForFormattingWithSymbol:symbol prefixRange:prefixRange];
}

#pragma mark - UITextViewDelegate Methods

- (BOOL)textView:(SLKTextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return [super textView:textView shouldChangeTextInRange:range replacementText:text];
}


#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([tableView isEqual:self.tableView]) {
        return self.messages.count;
    }
    else {
        return self.searchResult.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        return [self messageCellForRowAtIndexPath:indexPath];
    }
    else {
        return [self autoCompletionCellForRowAtIndexPath:indexPath];
    }
}

- (ChatViewCell *)messageCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatViewCell *cell = (ChatViewCell *)[self.tableView dequeueReusableCellWithIdentifier:ChatCellIdentifier];
    
    if (cell.gestureRecognizers.count == 0) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressCell:)];
        [cell addGestureRecognizer:longPress];
    }
    
    Message *message = self.messages[indexPath.row];
    
    cell.titleLabel.text = message.name;
    if (message.avatar && message.avatar.length) {
        cell.thumbnailView.email = message.avatar;
        cell.thumbnailView.forceDefault = NO;
    } else {
        cell.thumbnailView.email = [message.name MD5];
        cell.thumbnailView.forceDefault = YES;
    }
    [cell.thumbnailView load];
    
    cell.bodyLabel.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        NSURL *destination = [NSURL URLWithString:string];
        if (![string hasPrefix:@"http"])
            destination = [NSURL URLWithString:[@"http://" stringByAppendingString:string]];
        BOOL safariCompatible = [destination.scheme isEqualToString:@"http"] ||
        [destination.scheme isEqualToString:@"https"];
        
        if (safariCompatible && [[UIApplication sharedApplication] canOpenURL:destination])
        {
            [[UIApplication sharedApplication] openURL:destination];
        }
        else
        {
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:TRANSLATE(@"Problem")
                                                            message:TRANSLATE(@"The selected link cannot be opened")
                                                           delegate:nil
                                                  cancelButtonTitle:TRANSLATE(@"Cancel")
                                                  otherButtonTitles:nil];
            [alert show];
        }
    };

    
    
    NSString *text = message.message;
    
    if ([text containsString:@"<http"]) {
        NSMutableAttributedString* attrString = [[NSMutableAttributedString alloc] initWithString:text];
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<([^>]*)>"
                                                                               options:0
                                                                                 error:nil];
        NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
        //dispatch_group_t demoGroup = dispatch_group_create();
        for ( NSTextCheckingResult* match in matches )
        {
            //NSRange range = match.range;
            NSString* matchAll = [text substringWithRange:[match rangeAtIndex:0]];
            NSString* matchURL = [text substringWithRange:[match rangeAtIndex:1]];
            if ([matchURL hasPrefix:@"http"]) {
                //dispatch_group_enter(demoGroup);
                [[SDImageCache sharedImageCache] queryDiskCacheForKey:[matchURL MD5] done:^(UIImage *image, SDImageCacheType cacheType) {
                    NSRange range = [attrString.mutableString rangeOfString:matchAll];
                    if (image) {
                        [attrString replaceCharactersInRange:range withAttributedString:
                         [self attachmentWithImage:image height:120]];
                    } else {
                        [attrString replaceCharactersInRange:range withAttributedString:
                         [self attachmentWithImage:[UIImage imageNamed:@"icon_camera"] height:64]];
                    }
                    //dispatch_group_leave(demoGroup);
                    cell.bodyLabel.attributedText = attrString;
                }];
            }
        }
        //dispatch_group_notify(demoGroup, dispatch_get_main_queue(), ^{
        //    cell.bodyLabel.attributedText = attrString;
        //});
        
    } else {
        cell.bodyLabel.text = message.message;
    }
    
    
    /*
    NSDataDetector* detector = [NSDataDetector dataDetectorWithTypes:NSTextCheckingTypeLink error:nil];
    NSArray* matches = [detector matchesInString:text options:0 range:NSMakeRange(0,text.length)];
    if (matches.count) {
        NSMutableAttributedString *attributes =
        [[NSMutableAttributedString alloc] initWithString:text];
        for (int index = 0 ; index < matches.count; index ++) {
            NSTextCheckingResult *textResult = [matches objectAtIndex:index];
            NSRange range = textResult.range;
            NSURL *url = textResult.URL;
            NSString *string = url.absoluteString;
            //NSTextCheckingType textResultType = textResult.resultType;
            [attributes.mutableString replaceOccurrencesOfString:[NSString stringWithFormat:@"<%@>", string] withString:string options:0 range:NSMakeRange(0,text.length)];
            if ([string containsString:@"firebasestorage"]) {
                [[SDImageCache sharedImageCache] queryDiskCacheForKey:[string MD5] done:^(UIImage *image, SDImageCacheType cacheType) {
                    NSRange rangeM = [attributes.mutableString rangeOfString:string];
                    if (image) {
                        [attributes replaceCharactersInRange:rangeM withAttributedString:
                         [self attachmentWithImage:image]];
                    } else {
                        [attributes replaceCharactersInRange:rangeM withAttributedString:
                         [self attachmentWithImage:[UIImage imageNamed:@"icon_camera"]]];
                    }
                    cell.bodyLabel.attributedText = attributes;
                }];
            } else {
                [attributes addAttribute:NSLinkAttributeName value:url range:range];
                [attributes addAttribute:NSFontAttributeName
                                   value:[UIFont boldSystemFontOfSize:12.0] range:range];
            }
        }
        cell.bodyLabel.attributedText = attributes;
    } else {
        cell.bodyLabel.text = message.message;
    }
    */
    
    cell.dateLabel.text = [APP displayDate:message.timestamp];
    cell.indexPath = indexPath;
    cell.usedForMessage = YES;
    
    // Cells must inherit the table view's transform
    // This is very important, since the main table view may be inverted
    cell.transform = self.tableView.transform;
    
    return cell;
}

- (NSAttributedString*)attachmentWithImage:(UIImage*)attachment height:(CGFloat)height
{
    NSTextAttachment* textAttachment = [[NSTextAttachment alloc] initWithData:nil ofType:nil];
    textAttachment.image = attachment;
    [textAttachment setImageHeight:height];
    
    NSAttributedString* string = [NSAttributedString attributedStringWithAttachment:textAttachment];
    
    return string;
}

- (ChatViewCell *)autoCompletionCellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatViewCell *cell = (ChatViewCell *)[self.autoCompletionView dequeueReusableCellWithIdentifier:AutoCompletionCellIdentifier];
    cell.indexPath = indexPath;
    
    NSString *text = self.searchResult[indexPath.row];
    
    if ([self.foundPrefix isEqualToString:@"#"]) {
        text = [NSString stringWithFormat:@"# %@", text];
    }
    else if (([self.foundPrefix isEqualToString:@":"] || [self.foundPrefix isEqualToString:@"+:"])) {
        text = [NSString stringWithFormat:@":%@:", text];
    }
    
    cell.titleLabel.text = text;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.tableView]) {
        Message *message = self.messages[indexPath.row];
        
        NSMutableParagraphStyle *paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
        paragraphStyle.alignment = NSTextAlignmentLeft;
        
        CGFloat pointSize = [ChatViewCell defaultFontSize];
        
        NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:pointSize],
                                     NSParagraphStyleAttributeName: paragraphStyle};
        
        CGFloat width = CGRectGetWidth(tableView.frame)-kChatCellAvatarHeight;
        width -= 25.0;
        
        CGRect titleBounds = [message.name boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        CGRect bodyBounds = [message.message boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:attributes context:NULL];
        
        if (message.message.length == 0) {
            return 0.0;
        }
        
        CGFloat height = CGRectGetHeight(titleBounds);
        height += CGRectGetHeight(bodyBounds);
        height += 40.0;
        
        if (height < kChatCellMinimumHeight) {
            height = kChatCellMinimumHeight;
        }
        
        return height;
    }
    else {
        return kChatCellMinimumHeight;
    }
}


#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([tableView isEqual:self.autoCompletionView]) {
        
        NSMutableString *item = [self.searchResult[indexPath.row] mutableCopy];
        
        if ([self.foundPrefix isEqualToString:@"@"] && self.foundPrefixRange.location == 0) {
            [item appendString:@":"];
        }
        else if (([self.foundPrefix isEqualToString:@":"] || [self.foundPrefix isEqualToString:@"+:"])) {
            [item appendString:@":"];
        }
        
        [item appendString:@" "];
        
        [self acceptAutoCompletionWithString:item keepPrefix:YES];
    } else {
        if ([tableView isEqual:self.tableView]) {
            Message *message = self.messages[indexPath.row];
            NSString *text = message.message;
            if ([text containsString:@"<http"]) {
                NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<([^>]*)>"
                                                                                       options:0
                                                                                         error:nil];
                NSArray *matches = [regex matchesInString:text options:0 range:NSMakeRange(0, text.length)];
                __block NSMutableArray *photos = [NSMutableArray new];
                for ( NSTextCheckingResult* match in matches )
                {
                    NSString* matchURL = [text substringWithRange:[match rangeAtIndex:1]];
                    if ([matchURL hasPrefix:@"http"]) {
                        NSURL *url = [NSURL URLWithString:matchURL];
                        IDMPhoto *photo = [IDMPhoto photoWithURL:url];
                        [photos addObject:photo];
                    }
                }
                if (photos.count) {
                    _indexPath = indexPath;
                    IDMPhotoBrowser *browser = [[IDMPhotoBrowser alloc] initWithPhotos:photos];
                    [self presentViewController:browser animated:YES completion:nil];
                }
            }
        }
    }
}



#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    // Since SLKTextViewController uses UIScrollViewDelegate to update a few things, it is important that if you override this method, to call super.
    if (_isKeyboardShow) {
        [self dismissKeyboard:YES];
    }
    
    
    [super scrollViewDidScroll:scrollView];
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
