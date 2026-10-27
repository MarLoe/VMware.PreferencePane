//
//  MLAlerts.m
//  VMware
//
//  Created by Martin Løbger on 26/10/2026.
//  Copyright © 2026 ML-Consulting. All rights reserved.
//

#import "MLAlert.h"

@interface MLAlert()

@property (nonatomic, weak) NSWindow *mainWindow;

@end

@implementation MLAlert

- (instancetype)initWithView:(NSView*)view
{
    if (self = [super init]) {
        self.mainWindow = view.window;
    }
    
    return self;
}

+ (instancetype)alertOnView:(NSView*)view
{
    return [[MLAlert alloc] initWithView:view];
}

- (void)showResetPresetsWithCompletionHandler:(void (^)(NSModalResponse returnCode))handler
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.messageText = NSLocalizedString(@"Reset all presets?", -);
    alert.informativeText = NSLocalizedString(@"This will remove all presets and restore the defaults!", -);
    [alert addButtonWithTitle:NSLocalizedString(@"Reset", -)].tag = NSModalResponseReset;
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", -)].tag = NSModalResponseCancel;
    
    [alert beginSheetModalForWindow:_mainWindow completionHandler:handler];
}


- (void)showKeepChangesWithCompletionHandler:(void (^)(NSModalResponse returnCode))handler
{
    static dispatch_source_t timer = NULL;
    
    if (timer != NULL) {
        dispatch_source_cancel(timer);
        timer = nil;
    }
    
    // Show timer for reverting back to previous screen size
    NSInteger __block countDown = 15;
    NSString* informativeText = NSLocalizedString(@"Reverting to previous resolution in %@ seconds.", -);
    NSAlert* alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleInformational;
    alert.messageText = NSLocalizedString(@"Will you keep this display resolution?", -);
    alert.informativeText = [NSString stringWithFormat:informativeText, @(countDown)];
    [alert addButtonWithTitle:NSLocalizedString(@"Keep", -)].tag = NSModalResponseKeep;
    NSButton* revertButton = [alert addButtonWithTitle:NSLocalizedString(@"Revert", -)];
    revertButton.tag = NSModalResponseCancel;
    [alert beginSheetModalForWindow:_mainWindow completionHandler:^(NSModalResponse returnCode) {
        if (timer != NULL) {
            dispatch_source_cancel(timer);
            timer = nil;
        }
        handler(returnCode);
    }];
    
    timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 1.0 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(timer, ^{
        if (countDown < 0) {
            [revertButton performClick:self];
        }
        alert.informativeText = [NSString stringWithFormat:informativeText, @(countDown)];
        countDown -= 1;
    });
    dispatch_resume(timer);
}


- (void)showNewVersionAvailableForReleaseChecker:(MLGitHubReleaseChecker*)releaseChecker withCompletionHandler:(void (^)(NSModalResponse returnCode, NSControlStateValue suppressionState, MLGitHubAsset* asset))handler
{
    // Setup release note
    NSDictionary<NSAttributedStringKey, id>* titleAttr = @{
        NSFontAttributeName : [NSFont boldSystemFontOfSize:14.0]
    };
    NSAttributedString* releaseNote = [releaseChecker generateReleaseNoteFromRelease:releaseChecker.currentRelease
                                                                           toRelease:releaseChecker.availableRelease
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
    
    NSPredicate* predicate = [NSPredicate predicateWithFormat:@"name == %@", @"VMware.prefPane.zip"];
    MLGitHubAsset* asset = [releaseChecker.availableRelease.assets filteredArrayUsingPredicate:predicate].firstObject;
    
    
    NSAlert* alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.showsSuppressionButton = YES; // Uses default checkbox title
    alert.messageText = NSLocalizedString(@"A new version is available", -);
    alert.informativeText = [NSString stringWithFormat:NSLocalizedString(@"Version %@ is available.\nYou are currently running %@", -),
                                releaseChecker.availableRelease.name,
                                releaseChecker.currentRelease.name];
    alert.accessoryView = releaseNoteScrollView;
    
    
    [alert addButtonWithTitle:NSLocalizedString(@"View", -)].tag = NSModalResponseView;
    if (asset != nil) {
        [alert addButtonWithTitle:NSLocalizedString(@"Download", -)].tag = NSModalResponseDownload;
    }
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", -)].tag = NSModalResponseCancel;
    
    [alert beginSheetModalForWindow:_mainWindow completionHandler:^(NSModalResponse returnCode) {
        handler(returnCode, alert.suppressionButton.state, asset);
    }];
}


- (void)showPrivilegedWarningWithCompletionHandler:(void (^)(NSModalResponse returnCode, NSControlStateValue suppressionState))handler
{
    NSAlert* alert = [[NSAlert alloc] init];
    alert.alertStyle = NSAlertStyleWarning;
    alert.showsSuppressionButton = YES; // Uses default checkbox title
    alert.messageText = NSLocalizedString(@"This is not permanent!", -);
    alert.informativeText = NSLocalizedString(@"To make the screen size change accross reboots, you must unlock the padlock before pressing \"Apply\"!", -);
    [alert addButtonWithTitle:NSLocalizedString(@"Continue", -)];
    [alert addButtonWithTitle:NSLocalizedString(@"Cancel", -)].tag = NSModalResponseCancel;
    
    [alert beginSheetModalForWindow:_mainWindow completionHandler:^(NSModalResponse returnCode) {
        handler(returnCode, alert.suppressionButton.state);
    }];
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
    [alert beginSheetModalForWindow:_mainWindow completionHandler:nil];
}

@end
