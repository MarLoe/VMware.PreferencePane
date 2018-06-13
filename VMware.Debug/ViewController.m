//
//  ViewController.m
//  Test
//
//  Created by Martin Løbger on 12/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "ViewController.h"
#import <PreferencePanes/PreferencePanes.h>

#define RESET_SETTINGS FALSE

@implementation ViewController
{
    NSString* _title;
    NSPreferencePane* _prefPaneObject;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

#if RESET_SETTINGS
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
#endif

    NSURL* url = [NSURL fileURLWithPath:@"VMware.prefPane"];
    NSBundle *prefBundle = [NSBundle bundleWithURL:url];
    
    _title = [prefBundle objectForInfoDictionaryKey:@"NSPrefPaneIconLabel"];

    Class prefPaneClass = [prefBundle principalClass];
    _prefPaneObject = [[prefPaneClass alloc] initWithBundle:prefBundle];

    if ([_prefPaneObject loadMainView]) {
        [_prefPaneObject willSelect];
        self.view = [_prefPaneObject mainView];
        [_prefPaneObject didSelect];
    }
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    self.view.window.title = _title;
}

@end
