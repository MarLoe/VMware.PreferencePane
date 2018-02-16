//
//  MainPane.m
//  VMware Screen Resulution
//
//  Created by Martin Løbger on 11/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MainPane.h"
#import <CoreFoundation/CoreFoundation.h>

@interface MainPane()

@property (nonatomic, weak) IBOutlet NSTableView* presetsTableView;
@property (nonatomic, weak) IBOutlet NSTextField* textFieldResX;
@property (nonatomic, weak) IBOutlet NSStepper* stepperResX;
@property (nonatomic, weak) IBOutlet NSTextField* textFieldResY;
@property (nonatomic, weak) IBOutlet NSStepper* stepperResY;
@property (nonatomic, weak) IBOutlet NSButton* buttonApply;

@property (strong) IBOutlet NSUserDefaultsController *userDefaultsController;
@property (strong) IBOutlet NSArrayController *presetsArrayController;

@end

@implementation MainPane
{
    NSString* _bundleIdentifier;
}

- (void)mainViewDidLoad
{
    // Fix for size according to :
    // https://blog.timschroeder.net/2016/07/16/the-strange-case-of-the-os-x-system-preferences-window-width
    NSSize size = self.mainView.frame.size;
    size.width = [self preferenceWindowWidth];
    [[self mainView] setFrameSize:size];
    
    NSBundle* prefPaneBundle = [NSBundle bundleForClass:self.class];
    _bundleIdentifier = [prefPaneBundle objectForInfoDictionaryKey:(NSString*)kCFBundleIdentifierKey];

    [self loadDefaultPresets:NO];

    NSString * versionString = [prefPaneBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    self.version = [NSString stringWithFormat:@"Version: %@", versionString];

    [self applicationDidChangeScreenParametersNotification:nil];
    
    _stepperResX.integerValue = _currentWidth.integerValue;
    _stepperResY.integerValue = _currentHeight.integerValue;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeScreenParametersNotification:)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];
}


- (float)preferenceWindowWidth
{
    float result = 668.0; // default in case something goes wrong
    NSMutableArray *windows = (NSMutableArray *)CFBridgingRelease(CGWindowListCopyWindowInfo
                                                                  (kCGWindowListOptionOnScreenOnly | kCGWindowListExcludeDesktopElements, kCGNullWindowID));
    int myProcessIdentifier = [[NSProcessInfo processInfo] processIdentifier];
    BOOL foundWidth = NO;
    for (NSDictionary *window in windows) {
        int windowProcessIdentifier = [[window objectForKey:@"kCGWindowOwnerPID"] intValue];
        if ((myProcessIdentifier == windowProcessIdentifier) && (!foundWidth)) {
            foundWidth = YES;
            NSDictionary *bounds = [window objectForKey:@"kCGWindowBounds"];
            result = [[bounds valueForKey:@"Width"] floatValue];
        }
    }
    return result;
}


- (void)loadDefaultPresets:(bool)reset
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* presetsKey = [_bundleIdentifier stringByAppendingString:@"@presets"];
    if (reset) {
        [_presetsArrayController removeObjects:_presetsArrayController.arrangedObjects];
        [userDefaults removeObjectForKey:presetsKey];
    }
    if ( [userDefaults arrayForKey:presetsKey].count == 0) {
        NSBundle* prefPaneBundle = [NSBundle bundleForClass:self.class];
        NSURL* presetsUrl = [prefPaneBundle URLForResource:@"Presets" withExtension:@"plist"];
        NSArray* presets = [NSArray arrayWithContentsOfURL:presetsUrl];
        [_presetsArrayController addObjects:presets];
        [_presetsArrayController setSelectionIndexes:[NSIndexSet new]];
    }
}


#pragma mark - Notification Handlers

- (void)applicationDidChangeScreenParametersNotification:(NSNotification*) notification
{
    NSScreen* screen = NSScreen.mainScreen;
    NSRect screenSize = screen.frame;
    self.currentWidth = [NSNumber numberWithInteger:screenSize.size.width];
    self.currentHeight = [NSNumber numberWithInteger:screenSize.size.height];
}


#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSDictionary* selectedPreset = [_presetsArrayController.selectedObjects firstObject];
    _stepperResX.integerValue = [selectedPreset[@"width"] integerValue];
    _stepperResY.integerValue = [selectedPreset[@"height"] integerValue];
}


#pragma mark - Interface Builder Action

- (IBAction)apply:(id)sender
{
    NSPipe *pipeError = [NSPipe pipe];
    NSPipe *pipeOutput = [NSPipe pipe];

    NSTask *task = [[NSTask alloc] init];
    task.currentDirectoryPath = @"/Library/Application Support/VMware Tools/";
    task.launchPath = [task.currentDirectoryPath stringByAppendingPathComponent:@"vmware-resolutionSet"];
    task.arguments = @[_textFieldResX.stringValue, _textFieldResY.stringValue];
    task.standardError = pipeError;
    task.standardOutput = pipeOutput;

    NSError* error = nil;
    if (![task launchAndReturnError:(&error)]) {
        NSLog (@"ERROR:\n%@", error);
        NSAlert* alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:self.mainView.window completionHandler:nil];
        return;
    }

    [task waitUntilExit];
    
    if (task.terminationStatus == 0) {
        // SUCCESS
        NSFileHandle *file = pipeOutput.fileHandleForReading;
        NSData *data = [file readDataToEndOfFile];
        [file closeFile];
        if (data.length == 0) {
            // vmware-resolutionSet writes its log to stderr
            NSFileHandle *file = pipeError.fileHandleForReading;
            data = [file readDataToEndOfFile];
            [file closeFile];
        }
        NSString *outputText = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        NSLog (@"SUCCESS:\n%@", outputText);
    }
    else
    {
        // ERROR
        NSFileHandle *file = pipeError.fileHandleForReading;
        NSData *data = [file readDataToEndOfFile];
        [file closeFile];
        NSString *errorText = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
        NSLog (@"ERROR (%i):\n%@", task.terminationStatus, errorText);

        error = [NSError errorWithDomain:NSPOSIXErrorDomain
                                    code:task.terminationStatus
                                userInfo:@{ NSLocalizedDescriptionKey: errorText }];
        
        NSAlert* alert = [NSAlert alertWithError:error];
        [alert beginSheetModalForWindow:self.mainView.window completionHandler:nil];
    }
}


- (IBAction)presetNameAction:(id)sender
{
    // The ugliest hack ever:
    // In order to trigger NSArrayController to write
    // back changes, we will add/remove an object :(
    id selectedObjects = _presetsArrayController.selectedObjects;

    NSDictionary* newPreset = @{ @"name" : @"dummy", @"width" : @0, @"height" : @0 };
    [_presetsArrayController addObject:newPreset];
    [_presetsArrayController removeObject:newPreset];

    _presetsArrayController.selectedObjects = selectedObjects;
}


- (IBAction)presetsAdd:(id)sender
{
    NSDictionary* newPreset = @{ @"name" : @"New Screen Size", @"width" : @(_textFieldResX.integerValue), @"height" : @(_textFieldResY.integerValue) };
    [_presetsArrayController addObject:newPreset];
}


- (IBAction)presetRename:(id)sender
{
    NSInteger selectedRow = _presetsTableView.selectedRow;
    if (selectedRow >= 0) {
        [_presetsTableView editColumn:0
                                  row:selectedRow
                            withEvent:nil
                               select:YES];
    }
}


- (IBAction)presetReset:(id)sender
{
    NSAlert* alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSAlertStyleWarning];
    [alert setMessageText:@"Reset all presets?"];
    [alert setInformativeText:@"This will remove all presets and restore the defaults!"];
    [alert addButtonWithTitle:@"Reset"];
    [alert addButtonWithTitle:@"Cancel"];

    [alert beginSheetModalForWindow:self.mainView.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode != NSModalResponseCancel) {
            [self loadDefaultPresets:YES];
        }
    }];
}

@end
