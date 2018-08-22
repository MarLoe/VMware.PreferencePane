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
        self.view = _prefPaneObject.mainView;
    }
}

- (void)viewWillAppear
{
    [super viewWillAppear];
    self.view.window.title = _title;
    [_prefPaneObject willSelect];
}

- (void)viewDidAppear
{
    [super viewDidAppear];
    [self.view.window makeFirstResponder:self.view];
    [_prefPaneObject didSelect];
}

- (void)viewWillDisappear
{
    [super viewWillDisappear];
    [_prefPaneObject willUnselect];
}

- (void)viewDidDisappear
{
    [super viewDidDisappear];
    [_prefPaneObject didUnselect];
}

@end
