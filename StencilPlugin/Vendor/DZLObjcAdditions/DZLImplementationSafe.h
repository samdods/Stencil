//
//  DZLImplementationSafe
//  DZLObjcAdditions
//
//  Created by Sam Dods on 15/05/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//

#import "NSObject+DZLObjcAdditions.h"
#import "DZLSuper.h"

#define implementation_safe(klass, name) \
interface DZLImplementationSafe_ ## klass ## name : klass @end \
@implementation DZLImplementationSafe_ ## klass ## name \
+ (void)load { dzl_implementationSafe(klass.class, self); } @end \
@implementation DZLImplementationSafe_ ## klass ## name (Additions)
