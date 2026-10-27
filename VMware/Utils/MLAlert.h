//
//  MLAlerts.h
//  VMware
//
//  Created by Martin Løbger on 26/10/2026.
//  Copyright © 2026 ML-Consulting. All rights reserved.
//

@import AppKit;
#import <GitHubRelease/GitHubRelease.h>

NS_ASSUME_NONNULL_BEGIN

static const NSModalResponse NSModalResponseKeep            = (-1000);
static const NSModalResponse NSModalResponseReset           = (-1001);
static const NSModalResponse NSModalResponseView            = (-1002);
static const NSModalResponse NSModalResponseDownload        = (-1003);

@interface MLAlert : NSObject

+ (void)showResetPresetsWithCompletionHandler:(void (^)(NSModalResponse returnCode))handler;
+ (void)showKeepChangesWithCompletionHandler:(void (^)(NSModalResponse returnCode))handler;
+ (void)showNewVersionAvailableForReleaseChecker:(MLGitHubReleaseChecker*)releaseChecker withCompletionHandler:(void (^)(NSModalResponse returnCode, NSControlStateValue suppressionState, MLGitHubAsset* asset))handler;
+ (void)showPrivilegedWarningWithCompletionHandler:(void (^)(NSModalResponse returnCode, NSControlStateValue suppressionState))handler;
//+ (void)showKeepChangesForWindow:(NSWindow *)sheetWindow completionHandler:(void (^)(NSModalResponse returnCode))handler;

+ (void)showError:(NSError*)error;
+ (void)showErrorSheet:(NSError*)error;

@end

NS_ASSUME_NONNULL_END
