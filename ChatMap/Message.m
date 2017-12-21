//
//  Message.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 07.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "Message.h"
#import <FirebaseDatabase/FirebaseDatabase.h>
#import "NSString+Extensions.h"

@implementation Message

- (NSDictionary*)dictionary
{
    return  @{@"userId":_userId?:@"",
              @"name":_name?:@"",
              @"message":_message?:@"",
              @"timestamp":[FIRServerValue timestamp],
              //@"timestamp":_timestamp?:LONG_VALUE(0),
              @"avatar":_avatar?:@"",
              @"type":_type?:@""};
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"key:%@:%@", _key, [self dictionary]];
}

- (BOOL)isEqual:(id)object
{
    if ([object isKindOfClass:[self class]]) {
        return [_key isEqualToString:((Message*)object).key];
    }
    return [super isEqual:object];
}

@end
