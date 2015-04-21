//
//  TemplateConfig.m
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "TemplateConfig.h"
#import "ProjectFile.h"
#import "NSInputStream+StencilAdditions.h"
#import "NSString+StencilRegex.h"

@implementation TemplateConfig

+ (instancetype)defaultConfigForGroup:(id<ProjectGroup>)group error:(NSError **)error
{
  NSError *internalError = nil;
  NSDictionary *fileRefsByType = [group validatedFileRefsByType:&internalError];
  if (internalError) {
    if (error) {
      *error = internalError;
    }
    return nil;
  }
  
  NSMutableArray *classNames = [NSMutableArray new];
  
  id<ProjectFile> headerFile = fileRefsByType[@(ProjectFileInterface)];
  if (headerFile) {
    NSArray *parsedClassNames = [self parsedClassNamesFromFileAtPath:headerFile.fullPath];
    [classNames addObjectsFromArray:parsedClassNames];
  }
  
  id<ProjectFile> implementationFile = fileRefsByType[@(ProjectFileImplementation)];
  if (implementationFile) {
    NSArray *parsedClassNames = [self parsedClassNamesFromFileAtPath:implementationFile.fullPath];
    [classNames addObjectsFromArray:parsedClassNames];
  }
  
  return [[self alloc] initWithAvailableSuperclassNames:classNames.copy fileRefsByType:fileRefsByType];
}

+ (NSArray *)parsedClassNamesFromFileAtPath:(NSString *)path
{
  NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];
  [inputStream open];
  
  NSMutableArray *classes = [NSMutableArray new];
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    NSString *output = [line stringByMatching:@".*@interface\\s+(\\w+)\\s*:\\s*\\w+.*" replaceWith:@"$1"];
    if (output) {
      [classes addObject:output];
    }
    line = inputStream.stc_nextReadLine;
  }
  return classes.copy;
}

- (instancetype)initWithAvailableSuperclassNames:(NSArray *)superclassNames fileRefsByType:(NSDictionary *)fileRefsByType
{
  if (!(self = [super init])) {
    return nil;
  }
  _availableSuperclassNames = superclassNames;
  _fileRefs = fileRefsByType;
  return self;
}

@end
