//
//  Message.h
//  ChatMap
//
//  Created by culibinx@gmail.com on 07.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

@property (nonatomic, strong) NSString *key;
@property (nonatomic, strong) NSString *userId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *message;

@property (nonatomic, strong) NSNumber *timestamp;
@property (nonatomic, strong) NSString *type;
@property (nonatomic, strong) NSString *avatar;

- (NSDictionary*)dictionary;

@end
