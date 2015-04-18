//
//  IDEApplicationCommandsAdditions.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 18/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "DZLImplementationCombine.h"
#import "XcodeCustomFileTemplates.h"

@interface NSObject (IDEApplicationCommands_Additions)
- (void)newDocument:(NSMenuItem *)menuItem;
@end

@interface IDEApplicationCommands_Additions : NSObject
@end

@implementation IDEApplicationCommands_Additions

+ (void)load
{
  dzl_implementationCombine(NSClassFromString(@"IDEApplicationCommands"), self, dzl_no_assert);
}

- (void)newDocument:(NSMenuItem *)menuItem
{
  [XcodeCustomFileTemplates sharedPlugin].shouldShowNewDocumentCustomTemplatesOnly = ([menuItem.title isEqualToString:MenuItemTitleFileFromCustomTemplate]);
  dzlSuper(newDocument:menuItem);
}

@end
