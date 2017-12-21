//
//  NSString+Extensions.h
//  ChatMap
//
//  Created by culibinx@gmail.com on 26.06.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (Extensions)
- (BOOL)isEmoji;
- (NSString *)stripName;
- (NSString *)MD5;
@end

@interface NSData (Extensions)
+ (NSString *)generateUUID;
+ (NSString *)simpleUUID;
@end

@interface NSTextAttachment (Extensions)
- (void)setImageHeight:(CGFloat)height;
@end


