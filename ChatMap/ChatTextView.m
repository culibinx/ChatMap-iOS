//
//  ChatTextView.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 06.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "ChatTextView.h"

@implementation ChatTextView

- (instancetype)init
{
    if (self = [super init]) {
        // Do something
    }
    return self;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    self.backgroundColor = [UIColor whiteColor];
    
    self.placeholder = TRANSLATE(@"Message");
    self.placeholderColor = [UIColor lightGrayColor];
    self.pastableMediaTypes = SLKPastableMediaTypeAll;
    
    self.layer.borderColor = [UIColor colorWithRed:217.0/255.0 green:217.0/255.0 blue:217.0/255.0 alpha:1.0].CGColor;
}

@end
