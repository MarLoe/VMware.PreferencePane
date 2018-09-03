//
//  MainPane.m
//  VMware Screen Resulution
//
//  Created by Martin Løbger on 11/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MainPane.h"
#import <CoreFoundation/CoreFoundation.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import <sys/xattr.h>
#import <GitHubRelease/GitHubRelease.h>
#import "MLVMwareCommand.h"
#import "NSView+Enabled.h"

#define TEST_ENVIROMENT (DEBUG && FALSE)

#if (TEST_ENVIROMENT)
NSString* const kTestReleaseName            = @"1.2.1";
#endif

NSString* const kPresetName                 = @"name";
NSString* const kPresetWidth                = @"width";
NSString* const kPresetHeight               = @"height";

NSString* const kVMWarePrefsAutoHDPI        = @"enableAutoHiDPI";

static NSModalResponse const NSModalResponseView        = 1001;
static NSModalResponse const NSModalResponseDownload    = 1002;


@interface MainPane() <MLGitHubReleaseCheckerDelegate>

@property (nonatomic, weak) IBOutlet NSTableView*           presetsTableView;
@property (nonatomic, weak) IBOutlet NSTextField*           textFieldResX;
@property (nonatomic, weak) IBOutlet NSStepper*             stepperResX;
@property (nonatomic, weak) IBOutlet NSTextField*           textFieldResY;
@property (nonatomic, weak) IBOutlet NSStepper*             stepperResY;

@property (nonatomic, weak) IBOutlet NSButton*              autoHiDPI;

@property (nonatomic, weak) IBOutlet SFAuthorizationView*   authorizationView;
@property (nonatomic, weak) IBOutlet NSButton*              buttonApply;

@property (strong) IBOutlet NSUserDefaultsController*       userDefaultsController;
@property (strong) IBOutlet NSArrayController*              presetsArrayController;

@end

@implementation MainPane
{
    BOOL                        _forceCheckForUpdate;
    NSString*                   _bundleIdentifier;
    MLGitHubReleaseChecker*     _releaseChecker;
    NSURL*                      _vmWarePreferencesUrl;
    NSMutableDictionary*        _vmWarePreferencesDict;
    
    dispatch_source_t           _revertAlertTimer;
}


- (instancetype)initWithBundle:(NSBundle *)bundle
{
    if (self = [super initWithBundle:bundle]) {
        _forceCheckForUpdate |= [self isOptionsKeyPressed];
    }
    return self;
}


- (void)awakeFromNib
{
    [super awakeFromNib];
    _forceCheckForUpdate |= [self isOptionsKeyPressed];
}


- (void)mainViewDidLoad
{
    _forceCheckForUpdate |= [self isOptionsKeyPressed];
    
    // Fix for size according to :
    // https://blog.timschroeder.net/2016/07/16/the-strange-case-of-the-os-x-system-preferences-window-width
    NSSize size = self.mainView.frame.size;
    size.width = [self preferenceWindowWidth];
    [[self mainView] setFrameSize:size];
    
    NSBundle* prefPaneBundle = [NSBundle bundleForClass:self.class];
    _bundleIdentifier = [prefPaneBundle objectForInfoDictionaryKey:(NSString*)kCFBundleIdentifierKey];
    
    self.version = [prefPaneBundle objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
#if TEST_ENVIROMENT
    self.version = kTestReleaseName;
#endif
    
    [self applicationDidChangeScreenParametersNotification:nil];
    
    [self loadDefaultPresets:NO];
    
    _stepperResX.integerValue = _currentWidth.integerValue;
    _stepperResY.integerValue = _currentHeight.integerValue;
    
    for (NSDictionary* preset in _presetsArrayController.arrangedObjects) {
        if ([preset[kPresetWidth] isEqualToValue:_currentWidth] &&
            [preset[kPresetHeight] isEqualToValue:_currentHeight]) {
            [_presetsArrayController setSelectedObjects:@[preset]];
            [_presetsTableView scrollRowToVisible:_presetsArrayController.selectionIndex];
            break;
        }
    }
    
    NSString* libraryFolder = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    _vmWarePreferencesUrl = [NSURL fileURLWithPathComponents:@[libraryFolder, @"Preferences", @"com.vmware.tools.plist"]];
    _vmWarePreferencesDict = [[NSDictionary dictionaryWithContentsOfURL:_vmWarePreferencesUrl] mutableCopy];
    _autoHiDPI.state = [_vmWarePreferencesDict[kVMWarePrefsAutoHDPI] boolValue] ? NSControlStateValueOn : NSControlStateValueOff;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeScreenParametersNotification:)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];
    
    if ([_authorizationView.subviews count] == 0) {
        // On earlier versions (seen on Yosemite) the SFAuthorizationView does
        // not deserialieze from xib correctly, leaving it "empty".
        // If it is empty we know it failed and we can mauallyt create
        // one to work around it - thank you Apple :(
        SFAuthorizationView* authView = [[SFAuthorizationView alloc] initWithFrame:_authorizationView.frame];
        [_authorizationView.superview addSubview:authView];
        [_authorizationView removeFromSuperview];
        _authorizationView = authView;
    }
    
    // Setup security.
    AuthorizationItem items = {kAuthorizationRightExecute, 0, NULL, 0};
    AuthorizationRights rights = {1, &items};
    _authorizationView.delegate = self;
    [_authorizationView setAuthorizationRights:&rights];
    [_authorizationView updateStatus:nil];
}


- (void)willSelect
{
    _forceCheckForUpdate |= [self isOptionsKeyPressed];
}


- (void)didSelect
{
    _forceCheckForUpdate |= [self isOptionsKeyPressed];
    
    NSString* releaseName = self.version;
    if (_releaseChecker == nil) {
        _releaseChecker = [[MLGitHubReleaseChecker alloc] initWithUser:@"MarLoe" andProject:@"VMware.PreferencePane"];
        _releaseChecker.delegate = self;
    }
    
    if (!_forceCheckForUpdate) {
        // The standard check for update was not bypassed - so do it :)
        NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        if ([[userDefaults stringForKey:@"skip"] isEqualToString:releaseName]) {
            // The user has opted out of more alerts regarding this version.
            return;
        }
        
#if !TEST_ENVIROMENT // <- Drop the 24 hour check interval if we are in test enviroment
        NSDate* lastCheck = [userDefaults objectForKey:releaseName];
        if (lastCheck != nil && [lastCheck timeIntervalSinceNow] > -24*60*60) {
            // It has been less than 24 hours since last check
            return;
        }
#endif
    }
    
    _forceCheckForUpdate = NO;
    
    [_releaseChecker checkReleaseWithName:releaseName];
}


- (void)willUnselect
{
    if (_revertAlertTimer) {
        dispatch_source_cancel(self->_revertAlertTimer);
        _revertAlertTimer = nil;
    }
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


- (void)setScreenSize:(NSSize)size authorization:(SFAuthorization*)authorization
{
    NSInteger oldWidth = _currentWidth.integerValue;
    NSInteger oldHeight = _currentHeight.integerValue;
    
    
    [[MLVMwareCommand resolutionSet:size.width height:size.height] executeWithCompletion:^(NSError *error) {
        if (error != nil) {
            [self showErrorSheet:error];
            return;
        }
        
        // Show timer for reverting back to previous screen size
        NSInteger __block countDown = 15;
        NSString* informativeText = NSLocalizedString(@"Reverting to previous resolution in %@ seconds.", -);
        NSAlert* alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleInformational;
        alert.messageText = NSLocalizedString(@"Will you keep this display resolution?", -);
        alert.informativeText = [NSString stringWithFormat:informativeText, @(countDown)];
        [alert addButtonWithTitle:NSLocalizedString(@"Keep", -)].tag = NSModalResponseOK;
        NSButton* revertButton = [alert addButtonWithTitle:NSLocalizedString(@"Revert", -)];
        revertButton.tag = NSModalResponseCancel;
        [alert beginSheetModalForWindow:self.mainView.window completionHandler:^(NSModalResponse returnCode) {
            
            if (self->_revertAlertTimer) {
                dispatch_source_cancel(self->_revertAlertTimer);
                self->_revertAlertTimer = nil;
            }
            
            if (returnCode == NSModalResponseCancel) {
                [[MLVMwareCommand resolutionSet:oldWidth height:oldHeight] executeWithCompletion:nil];
                return;
            }
            
            if (authorization != nil) {
                
                const char **argv = (const char **)malloc(sizeof(char *) * (2 + 1));
                argv[0] = [@(size.width).stringValue UTF8String];
                argv[1] = [@(size.height).stringValue UTF8String];
                argv[2] = nil;
                
                NSString* launchPath = [kVMwareToolsFolder stringByAppendingPathComponent:kVMwareToolsResolutionSet];
                
                // This is depricated - but if it works, it works - and if it works, don't fix it
                // Anyway, someday I might look a bit more int SMJobBless
                OSErr processError = AuthorizationExecuteWithPrivileges([authorization authorizationRef],
                                                                        [launchPath UTF8String],
                                                                        kAuthorizationFlagDefaults,
                                                                        (char *const *)argv,
                                                                        NULL);
                
                free(argv);
                
                if (processError != errAuthorizationSuccess) {
                    NSLog(@"Error: %d", processError);
                    return;
                }
            }
        }];
        
        self->_revertAlertTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
        dispatch_source_set_timer(self->_revertAlertTimer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(self->_revertAlertTimer, ^{
            if (countDown < 0) {
                [revertButton performClick:self];
            }
            alert.informativeText = [NSString stringWithFormat:informativeText, @(countDown)];
            countDown -= 1;
        });
        dispatch_resume(self->_revertAlertTimer);
        
    }];
}


- (void)downloadAsset:(MLGitHubAsset*)asset
{
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSString* downloadFolder = NSSearchPathForDirectoriesInDomains(NSDownloadsDirectory, NSUserDomainMask, YES).firstObject;
    NSURL* downloadUrl = [NSURL fileURLWithPathComponents:@[downloadFolder, asset.name]];
    
    // Find unique file name
    for (int i = 1; [fileManager fileExistsAtPath:downloadUrl.path]; i++) {
        NSString* assetName = [[NSString stringWithFormat:@"%@ (%i)", [asset.name stringByDeletingPathExtension], i] stringByAppendingPathExtension:[asset.name pathExtension]];
        downloadUrl = [NSURL fileURLWithPathComponents:@[downloadFolder, assetName]];
    }
    // Create a placeholde until we are done downloading.
    [fileManager createFileAtPath:downloadUrl.path contents:nil attributes:nil];
    
    [asset downloadWithProgressHandler:^(NSURLResponse* _Nullable response, NSProgress* _Nullable progress) {
        if (progress.completedUnitCount == 0) {
            // This part will activate progress in "Downloads stack" in the dock
            progress.kind = NSProgressKindFile;
            [progress setUserInfoObject:NSProgressFileOperationKindDownloading forKey:NSProgressFileOperationKindKey];
            [progress setUserInfoObject:downloadUrl forKey:NSProgressFileURLKey];
            [progress publish];
        }
    } andCompletionHandler:^(NSURLResponse* _Nullable response, NSProgress* _Nullable progress, NSURL* _Nullable location, NSError* _Nullable error) {
        if (error == nil && [response isKindOfClass:NSHTTPURLResponse.class]) {
            NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;
            if (httpResponse.statusCode != 200) {
                error = [NSError errorWithDomain:NSURLErrorDomain
                                            code:httpResponse.statusCode
                                        userInfo:@{
                                                   NSLocalizedDescriptionKey : [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode]
                                                   }];
            }
        }
        
        if (error == nil && location!= nil) {
            [fileManager replaceItemAtURL:downloadUrl
                            withItemAtURL:location
                           backupItemName:nil
                                  options:NSFileManagerItemReplacementUsingNewMetadataOnly
                         resultingItemURL:nil
                                    error:&error];
            // To avoid getting quarantiened by macOS, we must remove the xattr
            removexattr(downloadUrl.path.UTF8String, "com.apple.quarantine", 0);
        }
        
        if (error == nil) {
            // Make the "Downloads stack" bounce
            [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"com.apple.DownloadFileFinished" object:downloadUrl.path];
        }
        
        if (error != nil) {
            NSLog(@"ERROR: %@", error);
            // In case of error, remove our placeholder file.
            [fileManager removeItemAtURL:downloadUrl error:nil];
            [[NSAlert alertWithError:error] runModal];
        }
        
        [progress unpublish]; // End "Downloads stack" progress
    }];
}


- (BOOL)isOptionsKeyPressed
{
    return ([NSEvent modifierFlags] & NSEventModifierFlagOption) == NSEventModifierFlagOption;
}


- (void)showError:(NSError*)error
{
    NSLog(@"ERROR: %@", error);
    NSAlert* alert = [NSAlert alertWithError:error];
    [alert runModal];
}


- (void)showErrorSheet:(NSError*)error
{
    NSLog (@"ERROR:\n%@", error);
    NSAlert* alert = [NSAlert alertWithError:error];
    [alert beginSheetModalForWindow:self.mainView.window completionHandler:nil];
}


#pragma mark - MLGitHubReleaseCheckerDelegate

- (void)gitHubReleaseChecker:(MLGitHubReleaseChecker*)sender foundReleaseInfo:(MLGitHubRelease*)releaseInfo
{
    NSLog(@"%@", releaseInfo);
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSDate date] forKey:releaseInfo.name];
    [userDefaults synchronize];
}


- (void)gitHubReleaseChecker:(MLGitHubReleaseChecker*)sender foundNewReleaseInfo:(MLGitHubRelease*)releaseInfo
{
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (releaseInfo.htmlURL == nil) {
        return;
    }
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name == %@", @"VMware.prefPane.zip"];
    MLGitHubAsset* asset = [releaseInfo.assets filteredArrayUsingPredicate:predicate].firstObject;
    
    // Setup release note
    NSDictionary<NSAttributedStringKey, id>* titleAttr = @{
                                                           NSFontAttributeName : [NSFont boldSystemFontOfSize:14.0]
                                                           };
    NSAttributedString* releaseNote = [sender generateReleaseNoteFromRelease:sender.currentRelease
                                                                   toRelease:sender.availableRelease
                                                        withHeaderAttributes:titleAttr
                                                           andBodyAttributes:nil];
    
    NSTextField* releaseNoteTextField;
    if (@available(macOS 10.12, *)) {
        releaseNoteTextField = [NSTextField labelWithAttributedString:releaseNote];
    }
    else {
        // This might clip some of the bottom :(
        // The size calculation is incorrect and neither me nor Google knows what's wrong...
        NSRect frame = { .origin = NSZeroPoint, .size = [releaseNote size]};
        releaseNoteTextField = [[NSTextField alloc] initWithFrame:frame];
        releaseNoteTextField.bordered = NO;
        releaseNoteTextField.editable = NO;
        releaseNoteTextField.attributedStringValue = releaseNote;
    }
    
    NSScrollView* releaseNoteScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(0, 0, 300, 100)];
    releaseNoteScrollView.hasVerticalScroller = YES;
    releaseNoteScrollView.hasHorizontalScroller = YES;
    releaseNoteScrollView.documentView = releaseNoteTextField;
    
    
    // Now create the alert
    NSAlert* alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.showsSuppressionButton = YES; // Uses default checkbox title
    alert.messageText = NSLocalizedString(@"A new version is available", -);
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Version %@ is available.\nYou are currently running %@", -),
                             releaseInfo.name,
                             sender.currentRelease.name
                             ];
    alert.accessoryView = releaseNoteScrollView;
    
    
    [alert addButtonWithTitle:NSLocalizedString(@"View", -)].tag = NSModalResponseView;
    if (asset != nil) {
        [alert addButtonWithTitle:NSLocalizedString(@"Download", -)].tag = NSModalResponseDownload;
    }
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", -)].tag = NSModalResponseCancel;
    
    [alert beginSheetModalForWindow:self.mainView.window completionHandler:^(NSModalResponse returnCode) {
        if (alert.suppressionButton.state == NSOnState) {
            // Suppress this alert from now on
            [userDefaults setObject:releaseInfo.name forKey:@"skip"];
        }
        
        if (returnCode == NSModalResponseView) {
            [[NSWorkspace sharedWorkspace] openURL:releaseInfo.htmlURL];
            return;
        }
        
        if (returnCode == NSModalResponseDownload) {
            [self downloadAsset:asset];
            return;
        }
    }];
}


- (void)gitHubReleaseChecker:(MLGitHubReleaseChecker *)sender failedWithError:(NSError *)error
{
    [self showError:error];
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
    _stepperResX.integerValue = [selectedPreset[kPresetWidth] integerValue];
    _stepperResY.integerValue = [selectedPreset[kPresetHeight] integerValue];
}


#pragma mark - Interface Builder Action

- (IBAction)apply:(id)sender
{
    NSSize size = NSMakeSize(_textFieldResX.integerValue, _textFieldResY.integerValue);
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* skipPrivilegedWarningKey = [_bundleIdentifier stringByAppendingString:@"@skipPrivilegedWarning"];
    
    BOOL autoHiDPIEnabled = _autoHiDPI.state == NSControlStateValueOn;
    if (autoHiDPIEnabled != [_vmWarePreferencesDict[kVMWarePrefsAutoHDPI] boolValue]) {
        _vmWarePreferencesDict[kVMWarePrefsAutoHDPI] = @(autoHiDPIEnabled);
        [_vmWarePreferencesDict writeToURL:_vmWarePreferencesUrl atomically:YES];
    }
    
    if (_authorizationView.authorizationState == SFAuthorizationViewUnlockedState) {
        [self setScreenSize:size authorization:[_authorizationView authorization]];
    }
    else if ([userDefaults boolForKey:skipPrivilegedWarningKey]) {
        [self setScreenSize:size authorization:nil];
    }
    else {
        NSAlert* alert = [[NSAlert alloc] init];
        alert.alertStyle = NSAlertStyleWarning;
        alert.showsSuppressionButton = YES; // Uses default checkbox title
        alert.messageText = NSLocalizedString(@"This is not permanent!", -);
        alert.informativeText = NSLocalizedString(@"To make the screen size change accross reboots, you must unlock the padlock before pressing \"Apply\"!", -);
        [alert addButtonWithTitle:NSLocalizedString(@"Continue", -)];
        [alert addButtonWithTitle:NSLocalizedString(@"Cancel", -)].tag = NSModalResponseCancel;
        
        [alert beginSheetModalForWindow:self.mainView.window completionHandler:^(NSModalResponse returnCode) {
            if (returnCode == NSModalResponseCancel) {
                return;
            }
            
            if (alert.suppressionButton.state == NSOnState) {
                // Suppress this alert from now on
                [userDefaults setBool:YES forKey:skipPrivilegedWarningKey];
            }
            
            [self setScreenSize:size authorization:nil];
        }];
    }
}


- (IBAction)presetNameAction:(id)sender
{
    // The ugliest hack ever:
    // In order to trigger NSArrayController to write
    // back changes, we will add/remove an object :(
    // Please, anyone! Tell me how to go bout this....
    id selectedObjects = _presetsArrayController.selectedObjects;
    
    NSDictionary* newPreset = @{
                                kPresetName : @"dummy",
                                kPresetWidth : @0,
                                kPresetHeight : @0
                                };
    [_presetsArrayController addObject:newPreset];
    [_presetsArrayController removeObject:newPreset];
    
    _presetsArrayController.selectedObjects = selectedObjects;
}


- (IBAction)presetsAdd:(id)sender
{
    NSDictionary* newPreset = @{
                                kPresetName : @"New Screen Size",
                                kPresetWidth : @(_textFieldResX.integerValue),
                                kPresetHeight : @(_textFieldResY.integerValue)
                                };
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
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = NSLocalizedString(@"Reset all presets?", -);
    alert.informativeText = NSLocalizedString(@"This will remove all presets and restore the defaults!", -);
    [alert addButtonWithTitle:NSLocalizedString(@"Reset", -)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", -)].tag = NSModalResponseCancel;
    
    [alert beginSheetModalForWindow:self.mainView.window completionHandler:^(NSModalResponse returnCode) {
        if (returnCode == NSModalResponseCancel) {
            return;
        }
        [self loadDefaultPresets:YES];
    }];
}

@end
