//
//  NSMenuAdditions.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 18/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "DZLImplementationCombine.h"
#import "XcodeCustomFileTemplates.h"


@implementation_combine(NSMenu, Additions)

- (instancetype)initWithTitle:(NSString *)aTitle
{
  if ([XcodeCustomFileTemplates canCreateFromCustomTemplate]) {
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate.action = [XcodeCustomFileTemplates sharedPlugin].menuItemNewFile.action;
  } else {
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate.action = nil;
  }
  return dzlSuper(initWithTitle:aTitle);
}

- (void)addItem:(NSMenuItem *)menuItemBeingAddedByXcode
{
  BOOL shouldAdd = ([self.title isEqualToString:@"Project navigator contextual menu"] && [menuItemBeingAddedByXcode.title isEqualToString:@"New File…"]);
  
  if (shouldAdd) {
    NSMenuItem *customMenuItem = [[NSMenuItem alloc] initWithTitle:MenuItemTitleNewFileFromCustomTemplate action:menuItemBeingAddedByXcode.action keyEquivalent:@""];
    dzlSuper(addItem:customMenuItem);
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate = customMenuItem;
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFile = menuItemBeingAddedByXcode;
    if (![XcodeCustomFileTemplates canCreateFromCustomTemplate]) {
      customMenuItem.action = nil;
    }
  }
  
  dzlSuper(addItem:menuItemBeingAddedByXcode);
}

@end
