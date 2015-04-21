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
  NSString *superclassName = [config.availableSuperclassNames[config.selectedSuperclassNameIndex] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
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
    NSURL *targetURL = [NSURL fileURLWithPath:targetFilePath];
    copyError = [self createTemplateFromFile:config.fileRefs[filetype] targetURL:targetURL type:filetype.integerValue];
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

- (void)copyTemplateInfoPlistToPath:(NSString *)targetPath config:(TemplateConfig *)config error:(NSError **)error
{
  NSURL *sourceURL = [[Stencil sharedPlugin].pluginBundle URLForResource:@"TemplateInfo" withExtension:@"plist"];
  NSString *targetFilePath = [targetPath stringByAppendingPathComponent:@"TemplateInfo.plist"];
  NSURL *targetURL = [NSURL fileURLWithPath:targetFilePath];
    
  NSInputStream *inputStream = [NSInputStream inputStreamWithURL:sourceURL];
  [inputStream open];
  
  NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:targetURL append:NO];
  [outputStream open];
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    NSMutableString *outputLine = [line mutableCopy];
    [outputLine matchPattern:@"__STC_DESCRIPTION__" replaceWith:config.templateDescription];
    [outputStream stc_writeString:outputLine];
    line = inputStream.stc_nextReadLine;
  }
  
  [inputStream close];
  [outputStream close];
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

- (NSError *)createTemplateFromFile:(id<ProjectFile>)file targetURL:(NSURL *)targetURL type:(ProjectFileType)filetype
{
  NSURL *sourceURL = file.fileURL;
  NSInputStream *inputStream = [NSInputStream inputStreamWithURL:sourceURL];
  [inputStream open];
  
  NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:targetURL append:NO];
  [outputStream open];
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    NSString *outputLine = [self stringByTemplatifying:line file:file];
    [outputStream stc_writeString:outputLine];
    line = inputStream.stc_nextReadLine;
  }
  
  [inputStream close];
  [outputStream close];
  
  return nil;
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
  
  return output;
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
