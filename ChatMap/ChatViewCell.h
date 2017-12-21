//
//  ChatTableViewCell.h
//  ChatMap
//
//  Created by culibinx@gmail.com on 06.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "RFGravatarImageView.h"
#import "KILabel.h"

static CGFloat kChatCellMinimumHeight = 50.0;
static CGFloat kChatCellAvatarHeight = 30.0;

static NSString *ChatCellIdentifier = @"ChatCell";
static NSString *AutoCompletionCellIdentifier = @"AutoCompletionCell";

@interface ChatViewCell : UITableViewCell

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) KILabel *bodyLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) RFGravatarImageView *thumbnailView;

@property (nonatomic, strong) NSIndexPath *indexPath;

@property (nonatomic) BOOL usedForMessage;

+ (CGFloat)defaultFontSize;

@end
