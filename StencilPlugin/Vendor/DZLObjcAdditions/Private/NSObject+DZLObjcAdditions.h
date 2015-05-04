//
//  NSObject+DZLObjcAdditions.h
//  DZLObjcAdditions
//
//  Created by Sam Dods on 15/05/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

extern void dzl_implementationSafe(id self, Class aClass);
extern void __attribute__((overloadable)) dzl_implementationCombine(id self, Class aClass);
extern void __attribute__((overloadable)) dzl_implementationCombine(id self, Class aClass, NSInteger shouldAssert);


@interface DZLObjcAdditions : NSProxy

+ (instancetype)proxyForObject:(id)object class:(Class)class toForwardSelector:(SEL)selector;

+ (BOOL)proxyForObject:(id)object class:(Class)class respondsToSelector:(SEL)selector;

@end


@interface DZLObjcAdditions (MixinProtocol)

+ (void)mixinAllIfNecessary;

@end
