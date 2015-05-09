//
//  IDEStructureNavigatorAdditions.m
//  StencilPlugin
//
//  Created by Sam Dods on 18/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "DZLImplementationCombine.h"
#import "Stencil.h"
#import "ProjectGroup.h"
#import "ProjectFile.h"
#import "TemplateFactory.h"
#import "TemplateConfig.h"

@interface NSObject (IDEAdditions)
- (char)_testOrDeleteItems:(char)items useContextualMenuSelection:(char)selection;
@end


@interface IDEStructureNavigator_Additions : NSObject
@end

@implementation IDEStructureNavigator_Additions

+ (void)load
{
  dzl_implementationCombine(NSClassFromString(@"IDEStructureNavigator"), self, dzl_no_assert);
}

- (NSArray *)dzl_selectedFiles
{
  NSArray *files = [self valueForKey:@"selectedObjects"];
  if (![files isKindOfClass:[NSArray class]]) {
    return nil;
  }
  for (id file in files) {
    if (![file isKindOfClass:NSClassFromString(@"IDEFileReferenceNavigableItem")]) {
      return nil;
    }
  }
  return files;
}

- (char)_testOrDeleteItems:(char)items useContextualMenuSelection:(char)selection
{
  if (![Stencil sharedPlugin].beginCreateTemplateFromGroup) {
    return dzlSuper(_testOrDeleteItems:items useContextualMenuSelection:selection);
  }
  
  NSArray *files = [self dzl_selectedFiles];
  if (!files) {
    [[TemplateFactory defaultFactory] showAlertWithMessage:@"You cannot create a template from the current selection. Please ensure you have selected source files only."];
    return 0;
  }
  
  [Stencil sharedPlugin].beginCreateTemplateFromGroup = NO;
  
  NSError *error = nil;
  TemplateConfig *config = [TemplateConfig defaultConfigForFiles:files error:&error];
  if (error) {
    [[TemplateFactory defaultFactory] showAlertForError:error];
    return 0;
  }
  if (!config.thingTypeToNamesMaps.count) {
    [[TemplateFactory defaultFactory] showAlertWithMessage:@"Unsupported file type."];
    return 0;
  }
  
  [[Stencil sharedPlugin] showTemplateOptionsInWindow:[NSApp mainWindow] defaultTemplateConfig:config];
  return 0;
}

@end
