//
//  NSMenu+StencilAdditions.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 18/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "NSMenu+StencilAdditions.h"
#import "DZLImplementationCombine.h"
#import "XcodeCustomFileTemplates.h"

static NSString *const ProjectNavigatorContextualMenu = @"Project navigator contextual menu";

@implementation_combine(NSMenu, Additions)

- (instancetype)initWithTitle:(NSString *)aTitle
{
  if ([XcodeCustomFileTemplates sharedPlugin].canCreateFromCustomTemplate) {
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate.action = [XcodeCustomFileTemplates sharedPlugin].menuItemNewFile.action;
  } else {
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate.action = nil;
  }
  
  if ([[XcodeCustomFileTemplates sharedNavigator] projectNavigatorSelectedGroup] != nil) {
    [XcodeCustomFileTemplates sharedPlugin].menuItemCreateTemplateFromGroup.action = [XcodeCustomFileTemplates sharedPlugin].menuItemDelete.action;
  } else {
    [XcodeCustomFileTemplates sharedPlugin].menuItemCreateTemplateFromGroup.action = nil;
  }
  
  return dzlSuper(initWithTitle:aTitle);
}

- (void)addItem:(NSMenuItem *)menuItemBeingAddedByXcode
{
  BOOL isContextualMenu = [self.title isEqualToString:ProjectNavigatorContextualMenu];
  if (isContextualMenu) {
    self.delegate = [XcodeCustomFileTemplates sharedPlugin];
  }
  
  BOOL addCustomFileItem = (isContextualMenu && [menuItemBeingAddedByXcode.title isEqualToString:@"New File…"]);
  
  if (addCustomFileItem) {
    NSMenuItem *customMenuItem = [[NSMenuItem alloc] initWithTitle:MenuItemTitleNewFileFromCustomTemplate action:menuItemBeingAddedByXcode.action keyEquivalent:@""];
    dzlSuper(addItem:customMenuItem);
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFile = menuItemBeingAddedByXcode;
    [XcodeCustomFileTemplates sharedPlugin].menuItemNewFromCustomTemplate = customMenuItem;
    if (![XcodeCustomFileTemplates sharedPlugin].canCreateFromCustomTemplate) {
      customMenuItem.action = nil;
    }
  }
  
  BOOL addCreateTemplate = (isContextualMenu && [menuItemBeingAddedByXcode.title isEqualToString:@"Delete"]);
  
  if (addCreateTemplate) {
    NSMenuItem *customMenuItem = [[NSMenuItem alloc] initWithTitle:@"Create File Template from Group" action:menuItemBeingAddedByXcode.action keyEquivalent:@""];
    dzlSuper(addItem:customMenuItem);
    [XcodeCustomFileTemplates sharedPlugin].menuItemDelete = menuItemBeingAddedByXcode;
    [XcodeCustomFileTemplates sharedPlugin].menuItemCreateTemplateFromGroup = customMenuItem;
    [self addItem:[NSMenuItem separatorItem]];
  }
  
  dzlSuper(addItem:menuItemBeingAddedByXcode);
}


@end


@implementation NSMenu (StencilAdditions)

- (void)duplicateItemWithTitle:(NSString *)existingTitle duplicateTitle:(NSString *)duplicateTitle
{
  NSUInteger index = [self indexOfItemWithTitle:existingTitle];
  NSMenuItem *originalItem = [self itemWithTitle:existingTitle];
  NSMenuItem *customNewMenuItem = [[NSMenuItem alloc] initWithTitle:duplicateTitle action:originalItem.action keyEquivalent:@""];
  [self insertItem:customNewMenuItem atIndex:index];
}

@end