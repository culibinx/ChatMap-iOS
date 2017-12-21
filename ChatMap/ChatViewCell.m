//
//  ChatTableViewCell.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 06.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "ChatViewCell.h"
#import "SLKUIConstants.h"

@implementation ChatViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.backgroundColor = [UIColor whiteColor];
        
        [self configureSubviews];
    }
    return self;
}

- (void)configureSubviews
{
    [self.contentView addSubview:self.thumbnailView];
    [self.contentView addSubview:self.titleLabel];
    [self.contentView addSubview:self.bodyLabel];
    [self.contentView addSubview:self.dateLabel];
    
    NSDictionary *views = @{@"thumbnailView": self.thumbnailView,
                            @"titleLabel": self.titleLabel,
                            @"bodyLabel": self.bodyLabel,
                            @"dateLabel": self.dateLabel,
                            };
    
    NSDictionary *metrics = @{@"tumbSize": @(kChatCellAvatarHeight),
                              @"padding": @15,
                              @"right": @10,
                              @"left": @5
                              };
    
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[thumbnailView(tumbSize)]-right-[titleLabel(>=0)]-right-[dateLabel(>=0)]-right-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[thumbnailView(tumbSize)]-right-[bodyLabel(>=0)]-right-|" options:0 metrics:metrics views:views]];
    //[self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-left-[thumbnailView(tumbSize)]-right-[dateLabel(>=0)]-right-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[thumbnailView(tumbSize)]-(>=0)-|" options:0 metrics:metrics views:views]];
    [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-right-[dateLabel(20)]-(>=0)-|" options:0 metrics:metrics views:views]];
    
    if ([self.reuseIdentifier isEqualToString:ChatCellIdentifier]) {
        [self.contentView addConstraints:[NSLayoutConstraint
            constraintsWithVisualFormat:@"V:|-right-[titleLabel(20)]-left-[bodyLabel(>=0@999)]-left-|" options:0 metrics:metrics views:views]];
    }
    else {
        [self.contentView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[titleLabel]|" options:0 metrics:metrics views:views]];
    }
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    CGFloat pointSize = [ChatViewCell defaultFontSize];
    
    self.titleLabel.font = [UIFont boldSystemFontOfSize:pointSize];
    self.bodyLabel.font = [UIFont systemFontOfSize:pointSize];
    
    self.titleLabel.text = @"";
    self.bodyLabel.text = @"";
    self.dateLabel.text = @"";
    
}

#pragma mark - Getters

- (UILabel *)titleLabel
{
    if (!_titleLabel) {
        _titleLabel = [UILabel new];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.backgroundColor = [UIColor clearColor];
        _titleLabel.userInteractionEnabled = NO;
        _titleLabel.numberOfLines = 0;
        _titleLabel.textColor = [UIColor grayColor];
        _titleLabel.font = [UIFont boldSystemFontOfSize:[ChatViewCell defaultFontSize]];
    }
    return _titleLabel;
}

- (KILabel *)bodyLabel
{
    if (!_bodyLabel) {
        _bodyLabel = [KILabel new];
        _bodyLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _bodyLabel.backgroundColor = [UIColor clearColor];
        _bodyLabel.automaticLinkDetectionEnabled = YES;
        //_bodyLabel.userInteractionEnabled = YES;
        _bodyLabel.numberOfLines = 0;
        _bodyLabel.textColor = [UIColor darkGrayColor];
        _bodyLabel.font = [UIFont systemFontOfSize:[ChatViewCell defaultFontSize]];
        
        
    }
    return _bodyLabel;
}

- (UILabel *)dateLabel
{
    if (!_dateLabel) {
        _dateLabel = [UILabel new];
        _dateLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _dateLabel.backgroundColor = [UIColor clearColor];
        _dateLabel.userInteractionEnabled = NO;
        _dateLabel.numberOfLines = 0;
        _dateLabel.textAlignment = NSTextAlignmentRight;
        _dateLabel.textColor = [UIColor lightGrayColor];
        _dateLabel.font = [UIFont systemFontOfSize:[UIFont smallSystemFontSize]];
    }
    return _dateLabel;
}

- (UIImageView *)thumbnailView
{
    if (!_thumbnailView) {
        _thumbnailView = [RFGravatarImageView new];
        _thumbnailView.translatesAutoresizingMaskIntoConstraints = NO;
        _thumbnailView.userInteractionEnabled = NO;
        _thumbnailView.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1.0];
        
        _thumbnailView.layer.cornerRadius = kChatCellAvatarHeight/2.0;
        _thumbnailView.layer.masksToBounds = YES;
        
        _thumbnailView.forceDefault = YES;
        _thumbnailView.defaultGravatar = RFDefaultGravatarIdenticon;
        _thumbnailView.size = kChatCellAvatarHeight*2;
    }
    return _thumbnailView;
}

+ (CGFloat)defaultFontSize
{
    CGFloat pointSize = 16.0;
    
    NSString *contentSizeCategory = [[UIApplication sharedApplication] preferredContentSizeCategory];
    pointSize += SLKPointSizeDifferenceForCategory(contentSizeCategory);
    
    return pointSize;
}



@end
