//
//  ComLobgerVMwarePreferencePane.m
//  VMware Screen Resulution
//
//  Created by Martin Løbger on 11/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "ComLobgerVMwarePreferencePane.h"
#import <CoreFoundation/CoreFoundation.h>
#import <SecurityInterface/SFAuthorizationView.h>
#import <sys/xattr.h>
#import <GitHubRelease/GitHubRelease.h>
#import <STPrivilegedTask/STPrivilegedTask.h>
#import "MLAlert.h"
#import "MLVMwareCommand.h"
#import "MLVMwareGfxCommand.h"
#import "NSTabViewScreenResolution.h"
#import "NSTabViewItemInfo.h"
#import "NSView+Enabled.h"

#define TEST_ENVIROMENT (DEBUG && FALSE)

#if (TEST_ENVIROMENT)
NSString* const kTestReleaseName                            = @"1.2.1";
#endif


@interface ComLobgerVMwarePreferencePane() <MLGitHubReleaseCheckerDelegate>

@property (nonatomic, weak) IBOutlet NSTabView*                     tabView;
@property (nonatomic, weak) IBOutlet NSTabViewScreenResolution*     tabViewScreenResolution;
@property (nonatomic, weak) IBOutlet NSTabViewItemInfo*             tabViewItemInfo;

@property (nonatomic, weak) IBOutlet SFAuthorizationView*           authorizationView;

@property (strong) IBOutlet NSUserDefaultsController*       userDefaultsController;
//@property (strong) IBOutlet NSArrayController*              presetsArrayController;

@end

@implementation ComLobgerVMwarePreferencePane
{
    BOOL                        _forceCheckForUpdate;
    NSString*                   _bundleIdentifier;
    MLGitHubReleaseChecker*     _releaseChecker;
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
    
    _tabViewScreenResolution.bundleIdentifier = _bundleIdentifier;
    [_tabViewScreenResolution loadDefaultPresets:NO];


    if ([_authorizationView.subviews count] == 0) {
        // On earlier versions (seen on Yosemite) the SFAuthorizationView does
        // not deserialieze from xib correctly, leaving it "empty".
        // If it is empty we know it failed and we can maually create
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


- (void)revealElementForKey:(NSString*)key
{
    @try {
        [_tabView selectTabViewItemWithIdentifier:[NSString stringWithFormat:@"tab_%@", key]];
    }
    @catch (NSException* ex) {
        NSLog(@"Error: Tab with identifier %@ was not found", key);
        [_tabView selectFirstTabViewItem:self];
    }
}


- (void)willSelect
{
    _forceCheckForUpdate |= [self isOptionsKeyPressed];
}


- (void)didSelect
{
    _forceCheckForUpdate |= [self isOptionsKeyPressed];
    
    if (_releaseChecker == nil) {
        _releaseChecker = [[MLGitHubReleaseChecker alloc] initWithUser:@"MarLoe" andProject:@"VMware.PreferencePane"];
        _releaseChecker.delegate = self;
    }
    
    if (!_forceCheckForUpdate) {
        // The standard check for update was not bypassed - so do it :)
        NSUserDefaults* userDefaults = _userDefaultsController.defaults;
        NSString* skipKey = [_bundleIdentifier stringByAppendingString:@".skip"];
        NSString* releaseKey = [_bundleIdentifier stringByAppendingFormat:@".(%@)", self.version];
        if ([[userDefaults stringForKey:skipKey] isEqualToString:releaseKey]) {
            // The user has opted out of more alerts regarding this version.
            return;
        }
        
#if !TEST_ENVIROMENT // <- Drop the 24 hour check interval if we are in test enviroment
        NSDate* lastCheck = [userDefaults objectForKey:releaseKey];
        if (lastCheck != nil && [lastCheck timeIntervalSinceNow] > -24*60*60) {
            // It has been less than 24 hours since last check
            return;
        }
#endif
    }
    
    _forceCheckForUpdate = NO;
    
    [_releaseChecker checkReleaseWithName:self.version];
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
                                        userInfo:@{ NSLocalizedDescriptionKey : [NSHTTPURLResponse localizedStringForStatusCode:httpResponse.statusCode] }];
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
            // In case of error, remove our placeholder file.
            [fileManager removeItemAtURL:downloadUrl error:nil];
            [MLAlert showErrorSheet:error];
        }
        
        [progress unpublish]; // End "Downloads stack" progress
    }];
}


- (BOOL)isShiftKeyPressed
{
    return ([NSEvent modifierFlags] & NSEventModifierFlagShift) == NSEventModifierFlagShift;
}


- (BOOL)isOptionsKeyPressed
{
    return ([NSEvent modifierFlags] & NSEventModifierFlagOption) == NSEventModifierFlagOption;
}


#pragma mark - SFAuthorizationViewDelegate

- (void)authorizationViewDidAuthorize:(SFAuthorizationView *)view
{
    _tabViewScreenResolution.authorization = view.authorization;
    _tabViewItemInfo.authorization = view.authorization;
}


- (void)authorizationViewDidDeauthorize:(SFAuthorizationView *)view
{
    _tabViewScreenResolution.authorization = nil;
    _tabViewItemInfo.authorization = nil;
}


#pragma mark - MLGitHubReleaseCheckerDelegate

- (void)gitHubReleaseChecker:(MLGitHubReleaseChecker*)sender foundReleaseInfo:(MLGitHubRelease*)releaseInfo
{
    NSLog(@"%@", releaseInfo);
    NSUserDefaults* userDefaults = _userDefaultsController.defaults;
    NSString* releaseKey = [_bundleIdentifier stringByAppendingFormat:@".(%@)", releaseInfo.name];
    [userDefaults setObject:[NSDate date] forKey:releaseKey];
}


- (void)gitHubReleaseChecker:(MLGitHubReleaseChecker*)sender foundNewReleaseInfo:(MLGitHubRelease*)releaseInfo
{
    NSUserDefaults* userDefaults = _userDefaultsController.defaults;
    NSString* skipKey = [_bundleIdentifier stringByAppendingString:@".skip"];
    
    if (releaseInfo.htmlURL == nil) {
        return;
    }
    
    // Now create the alert
    [MLAlert showNewVersionAvailableForReleaseChecker:_releaseChecker withCompletionHandler:^(NSModalResponse returnCode, NSControlStateValue suppressionState, MLGitHubAsset* asset) {
        if (suppressionState == NSControlStateValueOn) {
            // Suppress this alert from now on
            [userDefaults setObject:releaseInfo.name forKey:skipKey];
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
    [MLAlert showError:error];
}


#pragma mark - NSTabViewDelegate

- (void)tabView:(NSTabView *)tabView willSelectTabViewItem:(nullable NSTabViewItem *)tabViewItem
{
    if (tabViewItem == _tabViewScreenResolution) {
        [_tabViewScreenResolution refresh];
    }
    else if (tabViewItem == _tabViewItemInfo) {
        [_tabViewItemInfo refresh];
    }
}

@end
