//
//  NSObject+DZLObjcAdditions.m
//  DZLObjcAdditions
//
//  Created by Sam Dods on 15/05/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//

#import <objc/runtime.h>
#import "NSObject+DZLObjcAdditions.h"
#import "DZLSingleton.h"
#import "DZLSuper.h"

NSInteger const dzl_no_assert = 37834;
static const void * const DZLObjcAdditionsSuperCountKey = &DZLObjcAdditionsSuperCountKey;

@interface DZLObjcAdditions ()
@property (nonatomic, strong) NSString *dzl_class_singleton;
@property (nonatomic, strong) id object;
@property (nonatomic, assign) Class class;
@property (nonatomic, assign) SEL selector;
@end

@implementation DZLObjcAdditions

@class_singleton(NSMutableDictionary, underlyingSelectorByReplacementSelector);

+ (void)setUnderlyingSelector:(SEL)underlyingSelector forSelector:(SEL)selector class:(Class)aClass
{
  NSString *key = [self replacementSelectorNameForSelector:selector class:aClass];
  NSString *underlyingName = NSStringFromSelector(underlyingSelector);
  NSString *existingName = self.underlyingSelectorByReplacementSelector[key];
  if (existingName) {
    [self setUnderlyingSelector:NSSelectorFromString(existingName) forSelector:underlyingSelector class:aClass];
  }
  self.underlyingSelectorByReplacementSelector[key] = underlyingName;
}

+ (SEL)underlyingSelectorForSelector:(SEL)selector class:(Class)targetClass
{
  NSString *underlyingName = nil;
  while (targetClass != Nil && underlyingName == nil) {
    NSString *key = [self replacementSelectorNameForSelector:selector class:targetClass];
    underlyingName = self.underlyingSelectorByReplacementSelector[key];
    targetClass = targetClass.superclass;
  }
  return NSSelectorFromString(underlyingName);
}

+ (NSString *)replacementSelectorNameForSelector:(SEL)selector class:(Class)aClass
{
  return [NSString stringWithFormat:@"%@_%@", NSStringFromClass(aClass), NSStringFromSelector(selector)];
}

+ (instancetype)proxyForObject:(id)object class:(Class)class toForwardSelector:(SEL)selector
{
  DZLObjcAdditions *proxy = [DZLObjcAdditions alloc];
  proxy.object = object;
  proxy.class = class;
  proxy.selector = selector;
  return proxy;
}

+ (BOOL)proxyForObject:(id)object class:(Class)class respondsToSelector:(SEL)selector
{
  SEL targetSelector = [DZLObjcAdditions underlyingSelectorForSelector:selector class:class];
  return [object respondsToSelector:targetSelector];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector
{
  return [self.object methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
  Class targetClass = [self targetClassForUnderlyingSelector];
  invocation.selector = [DZLObjcAdditions underlyingSelectorForSelector:self.selector class:targetClass];
  
  if ([self.object respondsToSelector:invocation.selector]) {
    [self modifySuperCountByDelta:1];
    [invocation invokeWithTarget:self.object];
    [self modifySuperCountByDelta:-1];
  }
  
  NSString *name = NSStringFromSelector(self.selector);
  if (![name isEqualToString:@"init"] && [name rangeOfString:@"initWith"].location != 0) {
    self.object = nil;
  }
}

- (Class)targetClassForUnderlyingSelector
{
  Class targetClass = self.class;
  for (NSInteger superCount = 0; superCount < self.currentSuperCount; superCount++) {
    if (targetClass.superclass == Nil) {
      return targetClass;
    }
    targetClass = targetClass.superclass;
  }
  return targetClass;
}

- (NSInteger)currentSuperCount
{
  NSMutableDictionary *superCountBySelector = [self superCountBySelector];
  NSString *key = NSStringFromSelector(self.selector);
  return [superCountBySelector[key] integerValue];
}

- (void)modifySuperCountByDelta:(NSInteger)delta
{
  @synchronized(self.object)
  {
    NSMutableDictionary *superCountBySelector = [self superCountBySelector];
    NSString *key = NSStringFromSelector(self.selector);
    NSInteger superCount = [superCountBySelector[key] integerValue];
    
    superCount += delta;
    
    if (superCount == 0) {
      [superCountBySelector removeObjectForKey:key];
    } else {
      superCountBySelector[key] = @(superCount);
    }
    
    objc_setAssociatedObject(self.object, DZLObjcAdditionsSuperCountKey, superCountBySelector.count ? superCountBySelector : nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  }
}

- (NSMutableDictionary *)superCountBySelector
{
  return objc_getAssociatedObject(self.object, DZLObjcAdditionsSuperCountKey) ?: [NSMutableDictionary new];
}

@end



@implementation NSObject (DZLObjcAdditions)

+ (void)dzl_implementMethodsFromClass:(Class)aClass overrideSuper:(BOOL)shouldOverrideSuper replace:(BOOL)shouldReplace shouldAssert:(BOOL)shouldAssert
{
  [self dzl_doImplementMethodsFromClass:aClass overrideSuper:shouldOverrideSuper replace:shouldReplace shouldAssert:shouldAssert];
  [object_getClass(self) dzl_doImplementMethodsFromClass:object_getClass(aClass) overrideSuper:shouldOverrideSuper replace:shouldReplace shouldAssert:shouldAssert];
}

+ (void)dzl_doImplementMethodsFromClass:(Class)aClass overrideSuper:(BOOL)shouldOverrideSuper replace:(BOOL)shouldReplace shouldAssert:(BOOL)shouldAssert
{
  uint numberOfMethods;
  Method *methods = class_copyMethodList(aClass, &numberOfMethods);
  for (uint m = 0; m < numberOfMethods; m++) {
    Method method = methods[m];
    SEL name = method_getName(method);
    const char *types = method_getTypeEncoding(method);
    
    BOOL instancesRespond = [self instancesRespondToSelector:name];
    NSAssert(!shouldAssert || !shouldReplace || instancesRespond, @"Can't combine with non-existent selector '%@' on class %@", NSStringFromSelector(name), NSStringFromClass(self));
    
    if (!shouldReplace && !shouldOverrideSuper && instancesRespond) {
      continue;
    }
    
    IMP imp = method_getImplementation(method);
    
    [self backupSelector:name forClass:aClass objcTypes:types];
    if (shouldReplace) {
      class_replaceMethod(self, name, imp, types);
    } else {
      class_addMethod(self, name, imp, types);
    }
  }
  free(methods);
}

+ (void)backupSelector:(SEL)name forClass:(Class)aClass objcTypes:(const char *)types
{
  if (![self instancesRespondToSelector:name] && ![self respondsToSelector:name]) {
    return;
  }
  IMP orgImp = class_getMethodImplementation(self, name);
  SEL newName = NSSelectorFromString([DZLObjcAdditions replacementSelectorNameForSelector:name class:aClass]);
  class_addMethod(self, newName, orgImp, types);
  [DZLObjcAdditions setUnderlyingSelector:newName forSelector:name class:self];
}

@end


@implementation DZLObjcAdditions (MixinProtocol)

+ (void)mixinAllIfNecessary
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    [self mixinAll];
  });
}

+ (void)mixinAll
{
  uint numberOfClasses;
  Class *classes = objc_copyClassList(&numberOfClasses);
  for (uint c = 0; c < numberOfClasses; c++) {
    Class targetClass = classes[c];
    uint numberOfProtocols;
    __unsafe_unretained Protocol **protocols = class_copyProtocolList(targetClass, &numberOfProtocols);
    
    for (uint p = 0; p < numberOfProtocols; p++) {
      Protocol *protocol = protocols[p];
      [self mixinProtocol:protocol toClass:targetClass];
    }
    
    free(protocols);
  }
  free(classes);
}

+ (void)mixinProtocol:(Protocol *)mixinProtocol toClass:(Class)targetClass
{
  NSString *className = [NSString stringWithFormat:@"DZLProtocolImplementation_%@", NSStringFromProtocol(mixinProtocol)];
  
  Class mixinClass = NSClassFromString(className);
  if (mixinClass && mixinClass != targetClass && [targetClass isSubclassOfClass:NSObject.class]) {
    [targetClass dzl_implementMethodsFromClass:mixinClass overrideSuper:NO replace:NO shouldAssert:YES];
  }
}

@end



void dzl_implementationSafe(id self, Class aClass)
{
  [self dzl_implementMethodsFromClass:aClass overrideSuper:YES replace:NO shouldAssert:YES];
}

void __attribute__((overloadable)) dzl_implementationCombine(id self, Class aClass)
{
  dzl_implementationCombine(self, aClass, YES);
}

void __attribute__((overloadable)) dzl_implementationCombine(id self, Class aClass, NSInteger shouldAssert)
{
  [self dzl_implementMethodsFromClass:aClass overrideSuper:NO replace:YES shouldAssert:(shouldAssert != dzl_no_assert)];
}
