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
  
  id<ProjectFile> headerFile = fileRefsByType[@(ProjectFileInterface)];
  if (headerFile) {
    maps = [self mapsFromFileAtPath:headerFile.fullPath];
  } else {
    id<ProjectFile> implementationFile = fileRefsByType[@(ProjectFileImplementation)];
    if (implementationFile) {
      maps = [self mapsFromFileAtPath:headerFile.fullPath];
    }
  }
  
  return [[self alloc] initWithThingTypeToNamesMaps:maps fileRefsByType:fileRefsByType];
}

+ (NSArray *)mapsFromFileAtPath:(NSString *)filePath
{
  NSMutableArray *maps = [NSMutableArray new];
  [self enumerateInterfaceDefinitionsFromFileAtPath:filePath block:^(NSArray *classNames) {
    if (classNames) {
      ThingTypeToClassNamesMap *map = [[ThingTypeToClassNamesMap alloc] initWithThingType:STCThingTypeInterface names:classNames];
      [maps addObject:map];
    }
  }];
  [self enumerateProtocolDefinitionsFromFileAtPath:filePath block:^(NSArray *protocolNames) {
    if (protocolNames) {
      ThingTypeToClassNamesMap *map = [[ThingTypeToClassNamesMap alloc] initWithThingType:STCThingTypeProtocol names:protocolNames];
      [maps addObject:map];
    }
  }];
  return maps.copy;
}

+ (void)enumerateInterfaceDefinitionsFromFileAtPath:(NSString *)path block:(void(^)(NSArray *classNames))block
{
  NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];
  [inputStream open];
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    NSString *output = [line stringByMatching:@"^@interface\\s+(\\w+)\\s*:\\s*(\\w+).*" replaceWith:@"$1:$2"];
    NSArray *interfaceNames = [output componentsSeparatedByString:@":"];
    block(interfaceNames);
    line = inputStream.stc_nextReadLine;
  }
  
  [inputStream close];
}

+ (void)enumerateProtocolDefinitionsFromFileAtPath:(NSString *)path block:(void(^)(NSArray *protocolNames))block
{
  NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:path];
  [inputStream open];
  
  NSString *line = inputStream.stc_nextReadLine;
  while (line) {
    NSString *output = [line stringByMatching:@"^@protocol\\s+(\\w+)\\s*<(\\w+)>.*" replaceWith:@"$1:$2"];
    NSArray *protocolNames = [output componentsSeparatedByString:@":"];
    block(protocolNames);
    line = inputStream.stc_nextReadLine;
  }
  
  [inputStream close];
}

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
