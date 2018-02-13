//
//  MainPane.m
//  VMware Screen Resulution
//
//  Created by Martin Løbger on 11/02/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "MainPane.h"
#import "IntegerValueFormatter.h"


@interface MainPane()

@property (nonatomic, weak) IBOutlet NSTextField* textFieldResX;
@property (nonatomic, weak) IBOutlet NSStepper* stepperResX;
@property (nonatomic, weak) IBOutlet NSTextField* textFieldResY;
@property (nonatomic, weak) IBOutlet NSStepper* stepperResY;
@property (nonatomic, weak) IBOutlet NSButton* buttonApply;

@end

@implementation MainPane

- (void)mainViewDidLoad
{
    [super mainViewDidLoad];

    IntegerValueFormatter *formatter = [[IntegerValueFormatter alloc] init];
    [_textFieldResX setFormatter:formatter];
    [_textFieldResY setFormatter:formatter];

    NSScreen* screen = NSScreen.mainScreen;
    NSRect screenSize = screen.frame;

    _textFieldResX.intValue = screenSize.size.width;
    _stepperResX.intValue = screenSize.size.width;
    _textFieldResY.intValue = screenSize.size.height;
    _stepperResY.intValue = screenSize.size.height;
}


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

@end
