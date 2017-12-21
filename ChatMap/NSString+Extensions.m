//
//  NSString+Extensions.m
//  ChatMap
//
//  Created by culibinx@gmail.com on 26.06.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import "NSString+Extensions.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString (Extensions)

- (BOOL)isEmoji
{
    if (self && (self.length == 2))
    {
        const unichar high = [self characterAtIndex:0];
        
        if (0xd800 <= high && high <= 0xdbff)
        {
            const unichar low = [self characterAtIndex:1];
            const int codepoint = ((high - 0xd800) * 0x400) + (low - 0xdc00) + 0x10000;
            
            return (0x1d000 <= codepoint && codepoint <= 0x1f77f);
        }
        else return (0x2100 <= high && high <= 0x27bf);
    }
    return NO;
}

- (NSString *)stripName
{
    NSMutableString *result = [NSMutableString stringWithString:self?:@""];
    if (result.length) {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:
                                      @"([^a-zA-Z0-9_\\-])" options:0 error:nil];
        
        [regex replaceMatchesInString:result options:0 range:NSMakeRange(0, [result length]) withTemplate:@""];
    }
    return result;
}

- (NSString *)MD5
{
    
    const char * pointer = [self UTF8String];
    unsigned char md5Buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(pointer, (CC_LONG)strlen(pointer), md5Buffer);
    
    NSMutableString *string = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
        [string appendFormat:@"%02x",md5Buffer[i]];
    
    return string;
}

@end


@implementation NSData (Extensions)

+ (NSString *)generateUUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    NSString *nonceString = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);
    return nonceString;
}

+ (NSString *)simpleUUID
{
    return [[[NSData generateUUID] lowercaseString] stringByReplacingOccurrencesOfString:@"-" withString:@""];
}

@end

@implementation NSTextAttachment (Extensions)

- (void)setImageHeight:(CGFloat)height
{
    if (self.image) {
        double ratio = self.image.size.width / self.image.size.height;
        self.bounds = CGRectMake(self.bounds.origin.x, self.bounds.origin.y, ratio * height, height);
    }
}

@end

