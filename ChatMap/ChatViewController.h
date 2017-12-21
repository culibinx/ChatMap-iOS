//
//  ChatViewController.h
//  ChatMap
//
//  Created by culibinx@gmail.com on 05.07.17.
//  Copyright © 2017 culibinx@gmail.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SLKTextViewController.h"

@interface ChatViewController : SLKTextViewController

- (void)configureDataSource:(NSDictionary *)mapInfo chatInfo:(NSDictionary *)chatInfo;
- (void)dismiss:(id)sender;

@end
