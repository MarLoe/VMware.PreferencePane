//
//  NSTabViewItemInfo.h
//  VMware
//
//  Created by Martin Løbger on 20/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSTabViewItemInfo : NSTabViewItem

@property (nonatomic, strong)   NSString* hostVersion;
@property (nonatomic, strong)   NSString* toolsVersion;
@property (nonatomic, assign)   NSTimeInterval uptime;

@end
