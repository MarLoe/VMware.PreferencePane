//
//  NSTabViewScreenResolution.h
//  VMware
//
//  Created by Martin Løbger on 26/10/2026.
//  Copyright © 2026 ML-Consulting. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <SecurityInterface/SFAuthorizationView.h>

extern NSString* const kVMWarePrefsAutoHDPI;

@interface NSTabViewScreenResolution : NSTabViewItem<NSTableViewDelegate, NSTextFieldDelegate>

@property (nonatomic, assign)   SFAuthorization*            authorization;

@property (nonatomic, weak)     NSString* bundleIdentifier;
@property (nonatomic, assign) IBOutlet NSNumber* currentWidth;
@property (nonatomic, assign) IBOutlet NSNumber* currentHeight;

- (void)refresh;

- (void)loadDefaultPresets:(bool)reset;

@end
