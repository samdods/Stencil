//
//  IDEStructureNavigatorAdditions.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 18/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "DZLImplementationCombine.h"
#import "Stencil.h"
#import "ProjectGroup.h"

@interface NSObject (IDEAdditions)
- (void)loadView;
- (char)_testOrDeleteItems:(char)items useContextualMenuSelection:(char)selection;
@end

static __weak id sharedNavigator;

@implementation Stencil (IDEStructureNavigator)

+ (id)sharedNavigator
{
  return sharedNavigator;
}

@end


@interface IDEStructureNavigator_Additions : NSObject
@end

@implementation IDEStructureNavigator_Additions

+ (void)load
{
  dzl_implementationCombine(NSClassFromString(@"IDEStructureNavigator"), self, dzl_no_assert);
}

- (void)loadView
{
  sharedNavigator = self;
  dzlSuper(loadView);
}

- (id)projectNavigatorSelectedGroup
{
  id group = [self valueForKey:@"_itemFromContextualClickedRows"];
  if ([group isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
    return group;
  }
  return nil;
}

- (char)_testOrDeleteItems:(char)items useContextualMenuSelection:(char)selection
{
  ProjectGroup *group = [self projectNavigatorSelectedGroup];
  if (!group || ![Stencil sharedPlugin].beginCreateTemplateFromGroup) {
    if (!group) {
      [Stencil sharedPlugin].menuItemCreateTemplateFromGroup.action = nil;
    }
    return dzlSuper(_testOrDeleteItems:items useContextualMenuSelection:selection);
  }
  
  [Stencil sharedPlugin].beginCreateTemplateFromGroup = NO;
  
  NSError *error = nil;
  NSDictionary *fileRefsByType = [group validatedFileRefsByType:&error];
  if (error) {
    [self showAlertForError:error];
    return 0;
  }
  
  NSString *groupName = group.name;
  groupName = [self input:@"Enter template name" defaultValue:groupName];
  if (!groupName) {
    return 0;
  }
  groupName = [groupName stringByAppendingString:@".xctemplate"];
  
  NSString *targetPath = [[[Stencil sharedPlugin].projectRootPath stringByAppendingPathComponent:PluginNameAndCorrespondingDirectory] stringByAppendingPathComponent:FileTemplatesDirectoryPath];
  targetPath = [targetPath stringByAppendingPathComponent:groupName];
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath isDirectory:nil]) {
    [self showAlertWithMessage:@"Template already exists with this name. Will no overwrite."];
    return 0;
  }
  
  NSArray *groupFileRefs = group.childRepresentedObjects;
  NSMutableArray *filePaths = [NSMutableArray new];
  for (id fileRef in groupFileRefs) {
    NSString *newFilePath = [self makeTemplateFromFileRef:fileRef withGroupName:groupName targetPath:targetPath];
    [filePaths addObject:newFilePath];
  }
  
  NSURL *sourceURL = [[Stencil sharedPlugin].pluginBundle URLForResource:@"TemplateInfo" withExtension:@"plist"];
  NSString *targetFilePath = [targetPath stringByAppendingPathComponent:@"TemplateInfo.plist"];
  NSURL *targetURL = [NSURL fileURLWithPath:targetFilePath];
  [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:targetURL error:nil];
  
  NSArray *filesWithoutXIB = [filePaths filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *filePath, NSDictionary *bindings) {
    return ![filePath hasSuffix:@".xib"];
  }]];
  NSArray *filesOnlyXIB = [filePaths filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *filePath, NSDictionary *bindings) {
    return [filePath hasSuffix:@".xib"];
  }]];
  
  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFiles:filesWithoutXIB];
  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFiles:filesOnlyXIB];
  
  return dzlSuper(_testOrDeleteItems:items useContextualMenuSelection:selection);
}

- (NSString *)makeTemplateFromFileRef:(id)fileRef withGroupName:(NSString *)groupName targetPath:(NSString *)targetPath
{
  NSString *sourcePath = [fileRef valueForKeyPath:@"reference.resolvedAbsolutePath"];
  NSURL *sourceURL = [NSURL fileURLWithPath:sourcePath];
  
  NSString *filename = [sourceURL lastPathComponent];
  NSRange rangeOfDot = [filename rangeOfString:@"."];
  
  NSString *fileExtension = [filename substringFromIndex:rangeOfDot.location];
  
  [[NSFileManager defaultManager] createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:nil];
  filename = [@"___FILEBASENAME___" stringByAppendingString:fileExtension];
  targetPath = [targetPath stringByAppendingPathComponent:filename];
  NSURL *targetURL = [NSURL fileURLWithPath:targetPath];
  
  NSError *error = nil;
  [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:targetURL error:&error];
  
  return targetPath;
}

- (NSString *)input:(NSString *)prompt defaultValue:(NSString *)defaultValue
{
  NSAlert *alert = [NSAlert new];
  alert.messageText = prompt;
  [alert addButtonWithTitle:@"OK"];
  [alert addButtonWithTitle:@"Cancel"];
  alert.informativeText = @"";
  
  NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
  input.stringValue = defaultValue;
  alert.accessoryView = input;
  NSInteger button = [alert runModal];
  if (button == NSAlertFirstButtonReturn) {
    [input validateEditing];
    return [input stringValue];
  } else if (button == NSAlertSecondButtonReturn) {
    return nil;
  } else {
    NSAssert1(NO, @"Invalid input dialog button %zd", button);
    return nil;
  }
}


#pragma mark - alert

- (void)showAlertForError:(NSError *)error
{
  
}

- (void)showAlertWithMessage:(NSString *)message
{
  
}

@end
