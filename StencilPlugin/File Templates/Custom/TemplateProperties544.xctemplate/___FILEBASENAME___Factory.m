//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import "___FILEBASENAME___.h"
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
  NSString *templateName = [config.properties.templateName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
  templateName = [templateName stringByAppendingString:@".xctemplate"];
  
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
  
  NSDictionary *fileTypeByTargetPath = [self processConfig:config targetBasePath:targetPath];
  [self openFilePaths:fileTypeByTargetPath];
}

#pragma mark - processing

- (NSDictionary *)processConfig:(TemplateConfig *)config targetBasePath:(NSString *)targetPath
{
  NSMutableDictionary *fileTypeByTargetPath = [NSMutableDictionary new];
  for (id<ProjectFile> file in config.fileRefs) {
    NSString *targetFilePath = config.properties.templateFilenameByOriginalFilename[file.name];
    targetFilePath = [targetPath stringByAppendingPathComponent:targetFilePath];
    if (config.properties.thingType == STCThingTypeObjcInterface) {
      [self createObjcInterfaceTemplateFromFile:file targetPath:targetFilePath type:file.type configProperties:config.properties];
    } else if (config.properties.thingType == STCThingTypeObjcProtocol) {
      [self createObjcProtocolTemplateFromFile:file targetPath:targetFilePath type:file.type configProperties:config.properties];
    } else if (config.properties.thingType == STCThingTypeSwiftClass) {
      [self createSwiftClassTemplateFromFile:file targetPath:targetFilePath type:file.type configProperties:config.properties];
    } else if (config.properties.thingType == STCThingTypeSwiftProtocol) {
      [self createSwiftProtocolTemplateFromFile:file targetPath:targetFilePath type:file.type configProperties:config.properties];
    }
    fileTypeByTargetPath[targetFilePath] = @(file.type);
  };
  return fileTypeByTargetPath.copy;
}

#pragma mark - copying template

- (void)copyTemplateInfoPlistToPath:(NSString *)targetPath config:(TemplateConfig *)config error:(NSError **)error
{
  NSString *readmeSourcePath = [[Stencil sharedPlugin].pluginBundle pathForResource:@"StencilREADME" ofType:@""];
  NSString *readmeTargetPath = @"/tmp/StencilREADME";
  [[NSFileManager defaultManager] copyItemAtPath:readmeSourcePath toPath:readmeTargetPath error:nil];
  
  NSString *sourcePath = [[Stencil sharedPlugin].pluginBundle pathForResource:@"TemplateInfo" ofType:@"plist"];
  NSString *targetFilePath = [targetPath stringByAppendingPathComponent:@"TemplateInfo.plist"];
  
  [self copySourceFileAtPath:sourcePath toPath:targetFilePath withTopComment:nil through:^NSString *(NSString *line) {
    NSMutableString *mutableLine = [line mutableCopy];
    [mutableLine matchPattern:@"__STC_DESCRIPTION__" replaceWith:config.properties.templateDescription];
    return [mutableLine copy];
  }];
}

#pragma mark - copying objective-c

- (void)createObjcInterfaceTemplateFromFile:(id<ProjectFile>)file targetPath:(NSString *)targetPath type:(ProjectFileType)filetype configProperties:(TemplateProperties *)templateProperties
{
  NSString *topComment = [self topCommentForFileType:filetype configProperties:templateProperties];
  [self copySourceFileAtPath:file.fullPath toPath:targetPath withTopComment:topComment through:^NSString *(NSString *line) {
    if (filetype == ProjectFileUserInterface) {
      return [self stringByTemplatifyingXIB:line configProperties:templateProperties];
    }
    NSString *output = [self stringByTemplatifyingInterface:line configProperties:templateProperties];
    if (filetype == ProjectFileObjcImplementation) {
      NSMutableString *mutableOutput = [output mutableCopy];
      [mutableOutput matchPattern:[NSString stringWithFormat:@"#import \"%@.h\"", file.nameWithoutExtension] replaceWith:@"#import \"___FILEBASENAME___.h\""];
      return [mutableOutput copy];
    }
    return output;
  }];
}

- (void)createObjcProtocolTemplateFromFile:(id<ProjectFile>)file targetPath:(NSString *)targetPath type:(ProjectFileType)filetype configProperties:(TemplateProperties *)templateProperties
{
  NSString *topComment = [self topCommentForFileType:filetype configProperties:templateProperties];
  [self copySourceFileAtPath:file.fullPath toPath:targetPath withTopComment:topComment through:^NSString *(NSString *line) {
    if (filetype != ProjectFileUserInterface) {
      return [self stringByTemplatifyingObjcProtocol:line configProperties:templateProperties];
    }
    return line;
  }];
  if (filetype == ProjectFileObjcImplementation) {
    [self showAlertWithMessage:@"Warning: you have created a protocol template which includes an implementation file (.m). This is flagged as a warning, because it is mostly unexpected, but it is allowed."];
  }
}

#pragma mark - copying swift

- (void)createSwiftClassTemplateFromFile:(id<ProjectFile>)file targetPath:(NSString *)targetPath type:(ProjectFileType)filetype configProperties:(TemplateProperties *)templateProperties
{
  NSString *topComment = [self topCommentForFileType:filetype configProperties:templateProperties];
  [self copySourceFileAtPath:file.fullPath toPath:targetPath withTopComment:topComment through:^NSString *(NSString *line) {
    if (filetype == ProjectFileUserInterface) {
      return [self stringByTemplatifyingXIB:line configProperties:templateProperties];
    }
    return [self stringByTemplatifyingSwift:line configProperties:templateProperties];
  }];
}

- (void)createSwiftProtocolTemplateFromFile:(id<ProjectFile>)file targetPath:(NSString *)targetPath type:(ProjectFileType)filetype configProperties:(TemplateProperties *)templateProperties
{
  NSString *topComment = [self topCommentForFileType:filetype configProperties:templateProperties];
  [self copySourceFileAtPath:file.fullPath toPath:targetPath withTopComment:topComment through:^NSString *(NSString *line) {
    if (filetype != ProjectFileUserInterface) {
      return [self stringByTemplatifyingSwift:line configProperties:templateProperties];
    }
    return line;
  }];
}

#pragma mark - top comment

- (NSString *)topCommentForFileType:(ProjectFileType)filetype configProperties:(TemplateProperties *)templateProperties
{
  switch (filetype) {
    case ProjectFileObjcImplementation:
    case ProjectFileSwift:
      return [self defaultHeaderComments];
    case ProjectFileObjcInterface: {
      NSString *comments = [self defaultHeaderComments];
      return [comments stringByAppendingFormat:@"\n#import \"%@.h\"\n", templateProperties.thingNameToInheritFrom];
    }
    default:
      return nil;
  }
}

- (NSString *)defaultHeaderComments
{
  NSURL *url = [[Stencil sharedPlugin].pluginBundle URLForResource:@"HeaderComments" withExtension:@"sctemplate"];
  NSData *data = [[NSData alloc] initWithContentsOfURL:url];
  return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

#pragma mark - generic copying

- (void)copySourceFileAtPath:(NSString *)sourcePath toPath:(NSString *)targetPath withTopComment:(NSString *)topComment through:(NSString *(^)(NSString *line))modifiedStringBlock
{
  NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:sourcePath];
  [inputStream open];
  
  NSOutputStream *outputStream = [NSOutputStream outputStreamToFileAtPath:targetPath append:NO];
  [outputStream open];
  
  if (topComment) {
    [outputStream stc_writeString:topComment];
  }
  
  BOOL hasReachedFirstNonComment = (topComment == nil);
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    if (!hasReachedFirstNonComment && ![line hasPrefix:@"//"]) {
      hasReachedFirstNonComment = YES;
    }
    if (!hasReachedFirstNonComment) {
      line = inputStream.stc_nextReadLine;
      continue;
    }
    NSString *output = modifiedStringBlock(line);
    [outputStream stc_writeString:output];
    line = inputStream.stc_nextReadLine;
  }
  
  [inputStream close];
  [outputStream close];
}

#pragma mark - templates: objective-c

- (NSString *)stringByTemplatifyingInterface:(NSString *)line configProperties:(TemplateProperties *)templateProperties
{
  NSMutableString *output = [line mutableCopy];
  NSString *const nameToReplace = templateProperties.thingNameToReplace;
  NSString *const newInherit = templateProperties.thingNameToInheritFrom;
  static NSString *const FileBaseNameAsID = @"___FILEBASENAMEASIDENTIFIER___";
  
  // substitute interface definition
  [output matchPattern:[NSString stringWithFormat:@"^@interface\\s+%@\\s*:\\s*\\w+", nameToReplace]
           replaceWith:[NSString stringWithFormat:@"@interface %@ : %@", FileBaseNameAsID, newInherit]];
  
  // substitute interface extension
  [output matchPattern:[NSString stringWithFormat:@"^@interface\\s+%@\\s*\\((\\w*)\\)", nameToReplace]
           replaceWith:[NSString stringWithFormat:@"@interface %@ ($1)", FileBaseNameAsID]];
  
  // substitute implementation definition
  [output matchPattern:[NSString stringWithFormat:@"^@implementation\\s+%@\\b", nameToReplace]
           replaceWith:[NSString stringWithFormat:@"@implementation %@", FileBaseNameAsID]];
  
  return [output copy];
}

- (NSString *)stringByTemplatifyingObjcProtocol:(NSString *)line configProperties:(TemplateProperties *)templateProperties
{
  NSMutableString *output = [line mutableCopy];
  NSString *const nameToReplace = templateProperties.thingNameToReplace;
  NSString *const newInherit = templateProperties.thingNameToInheritFrom;
  static NSString *const FileBaseNameAsID = @"___FILEBASENAMEASIDENTIFIER___";
  
  // sub protocol definition
  [output matchPattern:[NSString stringWithFormat:@"@protocol\\s+%@\\s*<\\w+>", nameToReplace]
           replaceWith:[NSString stringWithFormat:@"@protocol %@ <%@>", FileBaseNameAsID, newInherit]];
  
  return [output copy];
}

#pragma mark - templates: swift

- (NSString *)stringByTemplatifyingSwift:(NSString *)line configProperties:(TemplateProperties *)templateProperties
{
  NSMutableString *output = [line mutableCopy];
  NSString *const nameToReplace = templateProperties.thingNameToReplace;
  NSString *const newInherit = templateProperties.thingNameToInheritFrom;
  static NSString *const FileBaseNameAsID = @"___FILEBASENAMEASIDENTIFIER___";
  
  // substitute class/protocol definition
  [output matchPattern:[NSString stringWithFormat:@"^\\s*(class|protocol|extension)\\s+%@\\s*:\\s*\\w+", nameToReplace]
           replaceWith:[NSString stringWithFormat:@"$1 %@ : %@", FileBaseNameAsID, newInherit]];
  
  return [output copy];
}

#pragma mark - templates: xib & storyboard

- (NSString *)stringByTemplatifyingXIB:(NSString *)line configProperties:(TemplateProperties *)templateProperties
{
  NSMutableString *output = [line mutableCopy];
  NSString *const nameToReplace = templateProperties.thingNameToReplace;
  static NSString *const FileBaseNameAsID = @"___FILEBASENAMEASIDENTIFIER___";
  
  [output matchPattern:[NSString stringWithFormat:@"customClass=\"%@\"", nameToReplace]
           replaceWith:[NSString stringWithFormat:@"customClass=\"%@\"", FileBaseNameAsID]];
  
  return [output copy];
}

#pragma mark - opening

- (void)openFilePaths:(NSDictionary *)fileTypeByTargetPath
{
  NSMutableArray *codeFilePaths = [NSMutableArray new];
  NSMutableArray *interfaceFilePaths = [NSMutableArray new];
  [fileTypeByTargetPath enumerateKeysAndObjectsUsingBlock:^(NSString *filePath, NSNumber *fileType, BOOL *stop) {
    if (fileType.integerValue == ProjectFileUserInterface) {
      [interfaceFilePaths addObject:filePath];
    } else {
      [codeFilePaths addObject:filePath];
    }
  }];
  codeFilePaths = [[codeFilePaths sortedArrayUsingComparator:^NSComparisonResult(NSString *path1, NSString *path2) {
    return [path1 compare:path2];
  }] mutableCopy];
  [codeFilePaths addObject:@"/tmp/StencilREADME"];
  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFiles:codeFilePaths];
  [[[NSApplication sharedApplication] delegate] application:[NSApplication sharedApplication] openFiles:interfaceFilePaths];
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
