//
//  MainPane.h
//  VMware Screen Resulution
//
//  Created by Martin Løbger on 11/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import <PreferencePanes/PreferencePanes.h>

@interface MainPane : NSPreferencePane<NSTabViewDelegate, NSTableViewDelegate>

@property (nonatomic, strong) IBOutlet NSString* version;

@property (nonatomic, assign) IBOutlet NSNumber* currentWidth;
@property (nonatomic, assign) IBOutlet NSNumber* currentHeight;

@end
