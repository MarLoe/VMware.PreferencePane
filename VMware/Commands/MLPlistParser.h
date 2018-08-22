//
//  MLPlistParser.h
//  VMware
//
//  Created by Martin Løbger on 22/08/2018.
//  Copyright © 2018 ML-Consulting. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MLPlistParser : NSObject

+ (NSDictionary*)parsePlist:(NSString*)plist error:(out NSError **)error;

@end
