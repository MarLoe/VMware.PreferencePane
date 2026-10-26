//
//  NSTabViewScreenResolution.h
//  VMware
//
//  Created by Martin Løbger on 26/10/2026.
//  Copyright © 2026 ML-Consulting. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SecurityInterface/SFAuthorizationView.h>

@interface NSTabViewScreenResolution : NSTabViewItem

@property (nonatomic, assign)   SFAuthorization*    authorization;

- (void)refresh;

@end
