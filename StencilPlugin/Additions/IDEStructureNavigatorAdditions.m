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

- (id<ProjectGroup>)dzl_selectedGroup
{
  id group = [self valueForKey:@"_itemFromContextualClickedRows"];
  if ([group isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
    return group;
  }
  return nil;
}

- (id<ProjectFile>)dzl_selectedFile
{
  id file = [self valueForKey:@"_itemFromContextualClickedRows"];
  if ([file isKindOfClass:NSClassFromString(@"IDEFileReferenceNavigableItem")]) {
    return file;
  }
  return nil;
}

- (char)_testOrDeleteItems:(char)items useContextualMenuSelection:(char)selection
{
  if (![Stencil sharedPlugin].beginCreateTemplateFromGroup) {
    return dzlSuper(_testOrDeleteItems:items useContextualMenuSelection:selection);
  }
  
  id<ProjectGroup> group = [self dzl_selectedGroup];
  if (!group) {
    id<ProjectFile> file = [self dzl_selectedFile];
    group = file.parentItem;
  }
  
  [Stencil sharedPlugin].beginCreateTemplateFromGroup = NO;
  
  NSError *error = nil;
  TemplateConfig *config = [TemplateConfig defaultConfigForGroup:group error:&error];
  if (error) {
    [[TemplateFactory defaultFactory] showAlertForError:error];
    return 0;
  }
  
  [[Stencil sharedPlugin] showTemplateOptionsInWindow:[NSApp mainWindow] defaultTemplateConfig:config];
  return 0;
}

@end
