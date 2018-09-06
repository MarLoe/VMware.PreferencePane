//
//  NSTimeIntervalTransformer.m
//  VMware
//
//  Created by Martin Løbger on 20/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import "NSTimeIntervalTransformer.h"

@implementation NSTimeIntervalTransformer

- (nullable id)transformedValue:(nullable id)value
{
    NSTimeInterval timeInterval = [value doubleValue];
    if (timeInterval <= 0) {
        return @"N/A";
    }
    
    NSDateComponentsFormatter *formatter = [[NSDateComponentsFormatter alloc] init];
    formatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
    formatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad | NSDateComponentsFormatterZeroFormattingBehaviorDefault;
    formatter.allowedUnits = NSCalendarUnitDay | NSCalendarUnitHour | NSCalendarUnitMinute | NSCalendarUnitSecond;
    return [formatter stringFromTimeInterval:timeInterval];
}

@end
