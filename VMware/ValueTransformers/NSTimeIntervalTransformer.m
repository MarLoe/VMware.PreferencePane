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

    NSDate *date = [NSDate dateWithTimeIntervalSince1970:timeInterval];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm:ss"];
    [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
    return [dateFormatter stringFromDate:date];
}

@end
