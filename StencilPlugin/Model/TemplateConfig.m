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
#import "ThingTypeToClassNamesMap.h"

@interface TemplateConfig ()
@property (nonatomic, readwrite) TemplateProperties *properties;
@end


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
  
  NSArray *maps = nil;
  
  id<ProjectFile> headerFile = fileRefsByType[@(ProjectFileObjcInterface)];
  if (headerFile) {
    maps = [self objcMapsFromFileAtPath:headerFile.fullPath];
  } else {
    id<ProjectFile> implementationFile = fileRefsByType[@(ProjectFileObjcImplementation)];
    if (implementationFile) {
      maps = [self objcMapsFromFileAtPath:headerFile.fullPath];
    }
  }
  
  id<ProjectFile> swiftFile = fileRefsByType[@(ProjectFileSwift)];
  if (swiftFile) {
    maps = [self swiftMapsFromFileAtPath:swiftFile.fullPath];
  }
  
  return [[self alloc] initWithThingTypeToNamesMaps:maps fileRefsByType:fileRefsByType];
}

#pragma mark - objective-c

+ (NSArray *)objcMapsFromFileAtPath:(NSString *)filePath
{
  NSMutableArray *maps = [NSMutableArray new];
  [self processFileAtPath:filePath matching:@"^@interface\\s+(\\w+)\\s*:\\s*(\\w+).*" thingType:STCThingTypeObjcInterface maps:maps];
  [self processFileAtPath:filePath matching:@"^@protocol\\s+(\\w+)\\s*<(\\w+)>.*" thingType:STCThingTypeObjcProtocol maps:maps];
  return maps.copy;
}

#pragma mark - swift

+ (NSArray *)swiftMapsFromFileAtPath:(NSString *)filePath
{
  NSMutableArray *maps = [NSMutableArray new];
  [self processFileAtPath:filePath matching:@"^\\s*class\\s+(\\w+)\\s*:\\s*(\\w+).*" thingType:STCThingTypeSwiftClass maps:maps];
  [self processFileAtPath:filePath matching:@"^\\s*protocol\\s+(\\w+)\\s*:\\s*(\\w+).*" thingType:STCThingTypeSwiftProtocol maps:maps];
  return maps.copy;
}

#pragma mark - generic

+ (void)processFileAtPath:(NSString *)filePath matching:(NSString *)pattern thingType:(STCThingType)thingType maps:(NSMutableArray *)maps
{
  [self enumerateFileAtPath:filePath thingsMatching:pattern block:^(NSArray *protocolNames) {
    ThingTypeToClassNamesMap *map = [[ThingTypeToClassNamesMap alloc] initWithThingType:thingType names:protocolNames];
    [maps addObject:map];
  }];
}

+ (void)enumerateFileAtPath:(NSString *)filePath thingsMatching:(NSString *)pattern block:(void(^)(NSArray *thingNames))block
{
  NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
  [inputStream open];
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    NSString *output = [[line stringByMatching:pattern replaceWith:@"$1:$2"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSArray *protocolNames = [output componentsSeparatedByString:@":"];
    if (protocolNames) {
      block(protocolNames);
    }
    line = inputStream.stc_nextReadLine;
  }
  
  [inputStream close];
}

#pragma mark - init

- (instancetype)initWithThingTypeToNamesMaps:(NSArray *)maps fileRefsByType:(NSDictionary *)fileRefsByType
{
  if (!(self = [super init])) {
    return nil;
  }
  _thingTypeToNamesMaps = maps;
  _fileRefs = fileRefsByType;
  return self;
}

@end



@implementation TemplateProperties

- (instancetype)initWithName:(NSString *)name thingType:(STCThingType)thingType nameToReplace:(NSString *)replace inheritFrom:(NSString *)inherit description:(NSString *)description
{
  if (!(self = [super init])) {
    return nil;
  }
  _templateName = name;
  _thingType = thingType;
  _thingNameToReplace = replace;
  _thingNameToInheritFrom = inherit;
  _templateDescription = description;
  return self;
}

@end
