//
//  DZLProtocolImplementation.h
//  DZLObjcAdditions
//
//  Created by Sam Dods on 15/05/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//

#import "NSObject+DZLObjcAdditions.h"

#define protocol_implementation(name) \
interface DZLProtocolImplementation_ ## name : NSObject <name> @end \
@implementation DZLProtocolImplementation_ ## name \
+ (void)load { [DZLObjcAdditions mixinAllIfNecessary]; } @end \
@implementation DZLProtocolImplementation_ ## name (Additions)
