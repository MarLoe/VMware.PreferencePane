//
//  ViewController.m
//  Test
//
//  Created by Martin Løbger on 12/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "ViewController.h"
#import <PreferencePanes/PreferencePanes.h>


@implementation ViewController
{
    NSPreferencePane *prefPaneObject;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    NSURL* url = [NSURL fileURLWithPath:@"VMware.prefPane"];
    NSBundle *prefBundle = [NSBundle bundleWithURL:url];

    Class prefPaneClass = [prefBundle principalClass];
    prefPaneObject = [[prefPaneClass alloc] initWithBundle:prefBundle];

    if ([prefPaneObject loadMainView]) {
        [prefPaneObject willSelect];
        self.view = [prefPaneObject mainView];
        [prefPaneObject didSelect];
    }
}


- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


@end
