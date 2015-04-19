//
//  NSWindow+StencilAdditions.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "NSWindow+StencilAdditions.h"
#import <objc/runtime.h>
#import "StencilWeakObjectWrapper.h"

@implementation NSWindow (StencilAdditions)

+ (instancetype)mainWindow
{
  return [[NSApplication sharedApplication] mainWindow];
}

- (id)projectStructureNavigator
{
  StencilWeakObjectWrapper *wrapper = objc_getAssociatedObject(self, _cmd);
  return wrapper.wrappedObject;
}

- (void)setProjectStructureNavigator:(id)projectStructureNavigator
{
  StencilWeakObjectWrapper *wrapper = [StencilWeakObjectWrapper new];
  wrapper.wrappedObject = projectStructureNavigator;
  objc_setAssociatedObject(self, @selector(projectStructureNavigator), wrapper, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end



@implementation StencilProjectStructureNavigator
@end
