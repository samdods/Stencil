//
//  TemplateFactory.m
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "TemplateFactory.h"
#import "TemplateConfig.h"
#import "ProjectGroup.h"
#import "ProjectFile.h"
#import "Stencil.h"
#import "NSInputStream+StencilAdditions.h"
#import "NSOutputStream+StencilAdditions.h"
#import "NSString+StencilRegex.h"

@implementation TemplateFactory

+ (instancetype)defaultFactory
{
  static TemplateFactory *factory = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    factory = [TemplateFactory new];
  });
  return factory;
}

- (void)generateTemplateFromConfig:(TemplateConfig *)config
{
  NSString *superclassName = [config.thingNameToReplace stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  NSString *templateName = [superclassName stringByAppendingString:@".xctemplate"];
  
  NSString *targetPath = [[[Stencil sharedPlugin].projectRootPath stringByAppendingPathComponent:PluginNameAndCorrespondingDirectory] stringByAppendingPathComponent:FileTemplatesDirectoryPath];
  targetPath = [targetPath stringByAppendingPathComponent:templateName];
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:targetPath isDirectory:nil]) {
    [self showAlertWithMessage:@"Template already exists with this name. Will not overwrite."];
    return;
  }
  
  [[NSFileManager defaultManager] createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:nil];
  
  NSError *error = nil;
  [self copyTemplateInfoPlistToPath:targetPath config:config error:&error];
  if (error) {
    [self showAlertForError:error];
    return;
  }
  
  NSDictionary *targetPathsByType = [self targetFileURLByType:config.fileRefs targetBasePath:targetPath];
  NSMutableArray *sourceFilePaths = [NSMutableArray new];
  
  __block NSError *copyError = nil;
  [targetPathsByType enumerateKeysAndObjectsUsingBlock:^(NSNumber *filetype, NSString *targetFilePath, BOOL *stop) {
    if (filetype.integerValue == ProjectFileInterface || filetype.integerValue == ProjectFileImplementation) {
      [sourceFilePaths addObject:targetFilePath];
    }
    copyError = [self createTemplateFromFile:config.fileRefs[filetype] targetPath:targetFilePath type:filetype.integerValue];
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


#pragma mark - copying

- (void)copyTemplateInfoPlistToPath:(NSString *)targetPath config:(TemplateConfig *)config error:(NSError **)error
{
  NSString *sourcePath = [[Stencil sharedPlugin].pluginBundle pathForResource:@"TemplateInfo" ofType:@"plist"];
  NSString *targetFilePath = [targetPath stringByAppendingPathComponent:@"TemplateInfo.plist"];
  
  [self copySourceFileAtPath:sourcePath toPath:targetFilePath through:^NSString *(NSString *line) {
    NSMutableString *mutableLine = [line mutableCopy];
    [mutableLine matchPattern:@"__STC_DESCRIPTION__" replaceWith:config.templateDescription];
    return [mutableLine copy];
  }];
}

- (NSError *)createTemplateFromFile:(id<ProjectFile>)file targetPath:(NSString *)targetPath type:(ProjectFileType)filetype
{
  [self copySourceFileAtPath:file.fullPath toPath:targetPath through:^NSString *(NSString *line) {
    return [self stringByTemplatifying:line file:file];
  }];
  
  return nil;
}

- (void)copySourceFileAtPath:(NSString *)sourcePath toPath:(NSString *)targetPath through:(NSString *(^)(NSString *line))modifiedStringBlock
{
  NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:sourcePath];
  [inputStream open];
  
  NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:targetPath append:NO];
  [outputStream open];
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    NSString *output = modifiedStringBlock(line);
    [outputStream stc_writeString:output];
    line = inputStream.stc_nextReadLine;
  }
  
  [inputStream close];
  [outputStream close];
}

- (NSString *)stringByTemplatifying:(NSString *)line file:(id<ProjectFile>)file
{
  NSMutableString *output = [line mutableCopy];
  NSString *const className = file.nameWithoutExtension;
  static NSString *const FileBaseNameAsID = @"___FILEBASENAMEASIDENTIFIER___";
  
  // substitute interface definition
  [output matchPattern:[NSString stringWithFormat:@"@interface\\s+%@\\s*:\\s*\\w+", className]
           replaceWith:[NSString stringWithFormat:@"@interface %@ : %@", FileBaseNameAsID, className]];
  
  // substitute interface extension
  [output matchPattern:[NSString stringWithFormat:@"@interface\\s+%@\\s*\\((\\w*)\\)", className]
           replaceWith:[NSString stringWithFormat:@"@interface %@ ($1)", FileBaseNameAsID]];
  
  // substitute implementation definition
  [output matchPattern:[NSString stringWithFormat:@"@implementation\\s+%@\\b", className]
           replaceWith:[NSString stringWithFormat:@"@implementation %@", FileBaseNameAsID]];
  
  return [output copy];
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
