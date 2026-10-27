//
//  NSTabViewScreenResolution.m
//  VMware
//
//  Created by Martin Løbger on 26/10/2026.
//  Copyright © 2026 ML-Consulting. All rights reserved.
//

#import "NSTabViewScreenResolution.h"
#import "MLAlert.h"
#import <MLVMwareCommand.h>
#import <MLVMwareGfxCommand.h>
#import <STPrivilegedTask/STPrivilegedTask.h>

NSString* const kPresetName                                 = @"name";
NSString* const kPresetWidth                                = @"width";
NSString* const kPresetHeight                               = @"height";


NSString* const kVMwarePrefsAutoHDPI                        = @"enableAutoHiDPI";

NSString* const kPreferencesDirectory                       = @"Preferences";
NSString* const kVMwareToolsPlist                           = @"com.vmware.tools.plist";

@interface NSTabViewScreenResolution ()

@property (nonatomic, assign) NSInteger                             currentWidth;
@property (nonatomic, assign) NSInteger                             currentHeight;

@property (nonatomic, assign) NSInteger                             resX;
@property (nonatomic, assign) NSInteger                             resY;

@property (nonatomic, strong)   IBOutlet NSArrayController*         presetsArrayController;
@property (nonatomic, weak)     IBOutlet NSUserDefaultsController*  userDefaultsController;

@property (nonatomic, weak)     IBOutlet NSTableView*               presetsTableView;
@property (nonatomic, weak)     IBOutlet NSTextField*               textFieldResX;
@property (nonatomic, weak)     IBOutlet NSStepper*                 stepperResX;
@property (nonatomic, weak)     IBOutlet NSTextField*               textFieldResY;
@property (nonatomic, weak)     IBOutlet NSStepper*                 stepperResY;
@property (nonatomic, weak)     IBOutlet NSButton*                  autoHiDPI;
@property (nonatomic, weak)     IBOutlet NSButton*                  buttonApply;

@end

@implementation NSTabViewScreenResolution

- (instancetype)init
{
    if (self = [super init]) {
        [self setup];
    }
    return self;
}


- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}


- (instancetype)initWithIdentifier:(nullable id)identifier
{
    if (self = [super initWithIdentifier:identifier]) {
        [self setup];
    }
    return self;
}


- (void)setup
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeScreenParametersNotification:)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];

    _autoHiDPI.state = [[self loadVMwarePreferences][kVMwarePrefsAutoHDPI] boolValue] ? NSControlStateValueOn : NSControlStateValueOff;
        
    [self getScreenSize];
    self.resX = _currentWidth;
    self.resY = _currentHeight;
}


- (void)refresh
{
    [self selectPresetWithWidth:_resX andHeight:_resY];
}


- (NSDictionary*)loadVMwarePreferences
{
    NSURL* vmWarePreferencesUrl = [NSURL fileURLWithPathComponents:@[
        NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject,
        kPreferencesDirectory,
        kVMwareToolsPlist]];

    return [NSDictionary dictionaryWithContentsOfURL:vmWarePreferencesUrl];
}


- (NSError*)saveVMwarePreferences:(NSDictionary*)preferences
{
    NSURL* vmWarePreferencesUrl = [NSURL fileURLWithPathComponents:@[
        NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject,
        kPreferencesDirectory,
        kVMwareToolsPlist]];
    
    NSError* error = nil;
    if (![preferences writeToURL:vmWarePreferencesUrl error:&error]) {
        return error;
    }
    
    return nil;
}


- (void)loadDefaultPresets:(bool)reset
{
    NSUserDefaults* userDefaults = _userDefaultsController.defaults;
    NSString* presetsKey = [_bundleIdentifier stringByAppendingString:@".presets"];
    
    if (reset) {
        [_presetsArrayController removeObjects:_presetsArrayController.arrangedObjects];
        [userDefaults removeObjectForKey:presetsKey];
    }
    
    if ([userDefaults arrayForKey:presetsKey].count == 0) {
        NSBundle* prefPaneBundle = [NSBundle bundleForClass:self.class];
        NSURL* presetsUrl = [prefPaneBundle URLForResource:@"Presets" withExtension:@"plist"];
        NSArray* presets = [NSArray arrayWithContentsOfURL:presetsUrl];
        [_presetsArrayController addObjects:presets];
        [_presetsArrayController setSelectionIndexes:[NSIndexSet new]];
    }
    
    [self selectPresetWithWidth:_resX andHeight:_resY];
}


- (void)selectPresetWithWidth:(NSInteger)width andHeight:(NSInteger)height
{
    id widthNumber = @(width);
    id heightNumber = @(height);
    for (NSDictionary* preset in _presetsArrayController.arrangedObjects) {
        if ([preset[kPresetWidth] isEqualToValue:widthNumber] &&
            [preset[kPresetHeight] isEqualToValue:heightNumber]) {
            [_presetsArrayController setSelectedObjects:@[preset]];
            [_presetsTableView scrollRowToVisible:_presetsArrayController.selectionIndex];
            return;
        }
    }
    
    [_presetsArrayController setSelectedObjects:@[]];
}


- (void)getScreenSize
{
    NSScreen* screen = NSScreen.mainScreen;
    NSRect screenSize = screen.frame;
    self.currentWidth = screenSize.size.width;
    self.currentHeight = screenSize.size.height;
}


- (void)setScreenSize:(NSSize)size showRevert:(BOOL)showRevert authorization:(SFAuthorization*)authorization completionHandler:(void (^)(BOOL reverted, NSError* error))handler
{
    MLVMwareCommand* cmd = [MLVMwareGfxSetResolutionCommand resolutionSet:size.width height:size.height];
    [cmd executeWithCompletion:^(NSError *error) {
        if (error != nil) {
            handler(NO, error);
            return;
        }
        
        void (^handlerBlock)(NSModalResponse returnCode) = ^(NSModalResponse returnCode) {
            
            if (returnCode == NSModalResponseCancel) {
                handler(YES, nil);
                return;
            }
            
            if (authorization != nil) {
                STPrivilegedTask* privTask = [[STPrivilegedTask alloc] initWithLaunchPath:cmd.command
                                                                                arguments:cmd.arguments];
                OSStatus processError = [privTask launchWithAuthorization:[authorization authorizationRef]];
                if (processError != errAuthorizationSuccess) {
                    handler(NO, [NSError errorWithDomain:NSOSStatusErrorDomain code:processError userInfo:nil]);
                    return;
                }
                
                [privTask waitUntilExit];
                
                if (privTask.terminationStatus != errAuthorizationSuccess) {
                    NSLog(@"Error: %d", processError);
                }
            }
            
            handler(NO, nil);
        };
        if (!showRevert) {
            handlerBlock(NSModalResponseKeep);
        }
        else {
            [MLAlert showKeepChangesWithCompletionHandler:handlerBlock];
        }
    }];
}


- (void)applySettingsWithRevert:(BOOL)showRevert andAuthorization:(SFAuthorization*)authorization
{
    NSSize newSize = NSMakeSize(_resX, _resY);
    NSSize oldSize = NSMakeSize(_currentWidth, _currentHeight);
    
    NSMutableDictionary* vmWarePreferences = [[self loadVMwarePreferences] mutableCopy];
    BOOL newAutoHiDPIEnabled = _autoHiDPI.state == NSControlStateValueOn;
    BOOL oldAutoHiDPIEnabled = [vmWarePreferences[kVMwarePrefsAutoHDPI] boolValue];
    if (newAutoHiDPIEnabled != oldAutoHiDPIEnabled) {
        vmWarePreferences[kVMwarePrefsAutoHDPI] = @(newAutoHiDPIEnabled);
        [self saveVMwarePreferences:vmWarePreferences];
    }
    
    __weak typeof(self) weakSelf = self;
    [self setScreenSize:newSize showRevert:showRevert authorization:authorization completionHandler:^(BOOL reverted, NSError* error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (reverted && strongSelf != nil) {
            if (newAutoHiDPIEnabled != oldAutoHiDPIEnabled) {
                vmWarePreferences[kVMwarePrefsAutoHDPI] = @(oldAutoHiDPIEnabled);
                [strongSelf saveVMwarePreferences:vmWarePreferences];
                strongSelf.autoHiDPI.state = oldAutoHiDPIEnabled ? NSControlStateValueOn : NSControlStateValueOff;
            }
            [[MLVMwareGfxSetResolutionCommand resolutionSet:oldSize.width height:oldSize.height] executeWithCompletion:nil];
        }
        if (error != nil) {
            [MLAlert showErrorSheet:error];
        }
    }];
}


#pragma mark - Notification Handlers

- (void)applicationDidChangeScreenParametersNotification:(NSNotification*) notification
{
    [self getScreenSize];
}


#pragma mark - NSTableViewDelegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSDictionary* selectedPreset = [_presetsArrayController.selectedObjects firstObject];
    if (selectedPreset != NULL)
    {
        self.resX = [selectedPreset[kPresetWidth] integerValue];
        self.resY = [selectedPreset[kPresetHeight] integerValue];
    }
}


#pragma mark - NSTextFieldDelegate

- (BOOL)control:(NSControl *)control
       textView:(NSTextView *)textView
doCommandBySelector:(SEL)commandSelector
{
    NSInteger delta = 0;
    if (commandSelector == @selector(moveUp:))
    {
        delta = 1;
    }
    else if (commandSelector == @selector(moveUpAndModifySelection:))
    {
        delta = 10;
    }
    else if (commandSelector == @selector(moveToBeginningOfDocumentAndModifySelection:))
    {
        delta = 100;
    }
    else if (commandSelector == @selector(moveDown:))
    {
        delta = -1;
    }
    else if (commandSelector == @selector(moveDownAndModifySelection:))
    {
        delta = -10;
    }
    else if (commandSelector == @selector(moveToEndOfDocumentAndModifySelection:))
    {
        delta = -100;
    }
    else
    {
        return NO;   // let the text field handle every other key
    }
    
    if (control == _textFieldResX)
    {
        // Passing by textfield, inforces number formatting
        _textFieldResX.integerValue += delta;
        self.resX = _textFieldResX.integerValue;
    }
    else if (control == _textFieldResY)
    {
        // Passing by textfield, inforces number formatting
        _textFieldResY.integerValue += delta;
        self.resY = _textFieldResY.integerValue;
    }
    else
    {
        return NO;   // let the text field handle every other key
    }
    
    [textView selectAll:nil];   // keeps the field editable and makes repeated presses feel natural
    return YES;
}


#pragma mark - Interface Builder Action

- (IBAction)presetNameAction:(id)sender
{
    // Binding is not triggered when bound properties are set
    NSDictionary *bindingInfo = [_presetsArrayController infoForBinding:@"contentArray"];
    if (bindingInfo) {
        NSObject *object = [bindingInfo objectForKey:NSObservedObjectKey];
        NSString *keyPath = [bindingInfo objectForKey:NSObservedKeyPathKey];
        
        // Ignoring options to apply value transformer, placeholder, etc. to value
        // NSDictionary *options = [bindingInfo objectForKey:NSOptionsKey];
        
        // Tell the model or controller object the new value
        [object setValue:_presetsArrayController.content forKeyPath:keyPath];
    }
}


- (IBAction)presetsAdd:(id)sender
{
    NSDictionary* newPreset = @{
        kPresetName : @"New Screen Size",
        kPresetWidth : @(_resX),
        kPresetHeight : @(_resY),
    };
    [_presetsArrayController addObject:newPreset];
    
    [_presetsArrayController setSelectedObjects:@[newPreset]];
    [_presetsTableView scrollRowToVisible:_presetsArrayController.selectionIndex];
    
    [self presetRename:sender];
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
    [MLAlert showResetPresetsWithCompletionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseReset) {
            [self loadDefaultPresets:YES];
        }
    }];
}

- (IBAction)apply:(id)sender
{
    BOOL optionsKeyPressed = false;//TODO [self isOptionsKeyPressed];
    NSUserDefaults* userDefaults = _userDefaultsController.defaults;
    NSString* skipPrivilegedWarningKey = [_bundleIdentifier stringByAppendingString:@".skipPrivilegedWarning"];
    
    if (_authorization != nil) {//_authorizationView.authorizationState == SFAuthorizationViewUnlockedState) {
        [self applySettingsWithRevert:!optionsKeyPressed andAuthorization:_authorization];
    }
    else if ([userDefaults boolForKey:skipPrivilegedWarningKey]) {
        [self applySettingsWithRevert:!optionsKeyPressed andAuthorization:nil];
    }
    else {
        [MLAlert showPrivilegedWarningWithCompletionHandler:^(NSModalResponse returnCode, NSControlStateValue suppressionState) {
            if (returnCode == NSModalResponseCancel) {
                return;
            }
            if (suppressionState == NSControlStateValueOn) {
                // Suppress this alert from now on
                [userDefaults setBool:YES forKey:skipPrivilegedWarningKey];
            }
            [self applySettingsWithRevert:!optionsKeyPressed andAuthorization:nil];
        }];
    }
}


#pragma mark - Property Access Methods

- (void)setResX:(NSInteger)resX
{
    if (_resX == resX) {
        return;
    }
    _resX = resX;
    
    [self selectPresetWithWidth:_resX andHeight:_resY];
}


- (void)setResY:(NSInteger)resY
{
    if (_resY == resY) {
        return;
    }
    _resY = resY;

    [self selectPresetWithWidth:_resX andHeight:_resY];
}

@end
