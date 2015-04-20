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
#import "ProjectFile.h"
#import "NSInputStream+StencilAdditions.h"
#import "NSOutputStream+StencilAdditions.h"

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

- (id<ProjectGroup>)selectedGroup
{
  id group = [self valueForKey:@"_itemFromContextualClickedRows"];
  if ([group isKindOfClass:NSClassFromString(@"IDEGroupNavigableItem")]) {
    return group;
  }
  return nil;
}

- (id<ProjectFile>)selectedFile
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
  
  id<ProjectGroup> group = [self selectedGroup];
  if (!group) {
    id<ProjectFile> file = [self selectedFile];
    group = file.parentItem;
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
    [self showAlertWithMessage:@"Template already exists with this name. Will not overwrite."];
    return 0;
  }
  
  [[NSFileManager defaultManager] createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:nil];
  NSURL *sourceURL = [[Stencil sharedPlugin].pluginBundle URLForResource:@"TemplateInfo" withExtension:@"plist"];
  NSString *targetFilePath = [targetPath stringByAppendingPathComponent:@"TemplateInfo.plist"];
  NSURL *targetURL = [NSURL fileURLWithPath:targetFilePath];
  
  [[NSFileManager defaultManager] copyItemAtURL:sourceURL toURL:targetURL error:&error];
  if (error) {
    [self showAlertForError:error];
    return 0;
  }
  
  NSDictionary *targetPathsByType = [self targetFileURLByType:fileRefsByType targetBasePath:targetPath];
  NSMutableArray *sourceFilePaths = [NSMutableArray new];
  
  __block NSError *copyError = nil;
  [targetPathsByType enumerateKeysAndObjectsUsingBlock:^(NSNumber *filetype, NSString *targetFilePath, BOOL *stop) {
    if (filetype.integerValue == ProjectFileInterface || filetype.integerValue == ProjectFileImplementation) {
      [sourceFilePaths addObject:targetFilePath];
    }
    NSURL *targetURL = [NSURL fileURLWithPath:targetFilePath];
    copyError = [self createTemplateFromFile:fileRefsByType[filetype] targetURL:targetURL type:filetype.integerValue];
    if (copyError) {
      *stop = YES;
    }
  }];
  if (copyError) {
    [self showAlertForError:copyError];
  }
  
  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFiles:sourceFilePaths];
  
  NSString *uiFilePath = targetPathsByType[@(ProjectFileUserInterface)];
  if (uiFilePath) {
    [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFile:uiFilePath];
  }
  
  return 0;
}

- (NSDictionary *)targetFileURLByType:(NSDictionary *)fileRefsByType targetBasePath:(NSString *)targetPath
{
  NSMutableDictionary *targetPathsByType = [NSMutableDictionary new];
  [fileRefsByType enumerateKeysAndObjectsUsingBlock:^(NSNumber *filetype, id<ProjectFile> fileRef, BOOL *stop) {
    NSString *targetFileName = [@"___FILEBASENAME___" stringByAppendingString:fileRef.extension];
    targetPathsByType[filetype] = [targetPath stringByAppendingPathComponent:targetFileName];
  }];
  return targetPathsByType;
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

#pragma mark - copying

- (NSError *)createTemplateFromFile:(id<ProjectFile>)file targetURL:(NSURL *)targetURL type:(ProjectFileType)filetype
{
  NSURL *sourceURL = file.fileURL;
  NSInputStream *inputStream = [NSInputStream inputStreamWithURL:sourceURL];
  [inputStream open];
  
  NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:targetURL append:NO];
  [outputStream open];
  
  
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    // substitute interface definition
    NSString *pattern = [NSString stringWithFormat:@"@interface\\s%@\\s*:\\s*\\w+", file.nameWithoutExtension];
    NSString *template = [NSString stringWithFormat:@"@interface ___FILEBASENAMEASIDENTIFIER___ : %@", file.nameWithoutExtension];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSString *outputLine = [regex stringByReplacingMatchesInString:line options:0 range:NSMakeRange(0, line.length) withTemplate:template];
    
    // substitute interface extension
    pattern = [NSString stringWithFormat:@"@interface\\s%@\\s*\\((\\w*)\\)", file.nameWithoutExtension];
    template = [NSString stringWithFormat:@"@interface ___FILEBASENAMEASIDENTIFIER___ ($1)"];
    regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    outputLine = [regex stringByReplacingMatchesInString:outputLine options:0 range:NSMakeRange(0, line.length) withTemplate:template];
    
    // substitute implementation definition
    pattern = [NSString stringWithFormat:@"@implementation\\s%@\\b", file.nameWithoutExtension];
    template = [NSString stringWithFormat:@"@implementation ___FILEBASENAMEASIDENTIFIER___"];
    regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    outputLine = [regex stringByReplacingMatchesInString:outputLine options:0 range:NSMakeRange(0, line.length) withTemplate:template];
    
    // write out
    [outputStream stc_writeString:outputLine];
    
    // read next
    line = inputStream.stc_nextReadLine;
  }
  
  // close
  [inputStream close];
  [outputStream close];
  
  return nil;
}

#pragma mark - alert

- (void)showAlertForError:(NSError *)error
{
  [self showAlertWithMessage:error.userInfo[NSLocalizedDescriptionKey]];
}

- (void)showAlertWithMessage:(NSString *)message
{
  NSAlert *alert = [NSAlert new];
  alert.messageText = message;
  [alert addButtonWithTitle:@"OK"];
  [alert runModal];
}

@end
