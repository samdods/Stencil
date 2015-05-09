//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import "___FILEBASENAME___.h"
#import "ProjectFile.h"
#import "ProjectGroup.h"
#import "NSInputStream+StencilAdditions.h"
#import "NSString+StencilRegex.h"
#import "ThingTypeToClassNamesMap.h"

@interface ___FILEBASENAMEASIDENTIFIER___ ()
@property (nonatomic, readwrite) TemplateProperties *properties;
@end


@implementation ___FILEBASENAMEASIDENTIFIER___

+ (instancetype)defaultConfigForFiles:(NSArray *)files error:(NSError **)error
{
  NSError *internalError = nil;
  NSArray *fileRefs = [files validatedTemplateFiles:&internalError];
  if (internalError) {
    if (error) {
      *error = internalError;
    }
    return nil;
  }
  
  NSMutableOrderedSet *maps = [NSMutableOrderedSet new];
  
  for (id<ProjectFile> file in fileRefs) {
    if (file.type == ProjectFileObjcInterface || file.type == ProjectFileObjcImplementation) {
      NSOrderedSet *mapsForFile = [self objcMapsFromFileAtPath:file.fullPath];
      [maps addObjectsFromArray:mapsForFile.array];
    } else if (file.type == ProjectFileSwift) {
      NSOrderedSet *mapsForFile = [self swiftMapsFromFileAtPath:file.fullPath];
      [maps addObjectsFromArray:mapsForFile.array];
    }
  }
  
  return [[self alloc] initWithThingTypeToNamesMaps:maps.array fileRefs:fileRefs];
}

#pragma mark - objective-c

+ (NSOrderedSet *)objcMapsFromFileAtPath:(NSString *)filePath
{
  NSMutableOrderedSet *maps = [NSMutableOrderedSet new];
  [self processFileAtPath:filePath matching:@"^@interface\\s+(\\w+)\\s*\\(\\s*\\w*\\s*\\).*" thingType:STCThingTypeObjcInterface maps:maps];
  [self processFileAtPath:filePath matching:@"^@interface\\s+(\\w+)\\s*:\\s*(\\w+).*" thingType:STCThingTypeObjcInterface maps:maps];
  [self processFileAtPath:filePath matching:@"^@protocol\\s+(\\w+)\\s*<(\\w+)>.*" thingType:STCThingTypeObjcProtocol maps:maps];
  return maps.copy;
}

#pragma mark - swift

+ (NSOrderedSet *)swiftMapsFromFileAtPath:(NSString *)filePath
{
  NSMutableOrderedSet *maps = [NSMutableOrderedSet new];
  [self processFileAtPath:filePath matching:@"^\\s*extension\\s+(\\w+).*" thingType:STCThingTypeSwiftClass maps:maps];
  [self processFileAtPath:filePath matching:@"^\\s*class\\s+(\\w+).*" thingType:STCThingTypeSwiftClass maps:maps];
  [self processFileAtPath:filePath matching:@"^\\s*class\\s+(\\w+)\\s*:\\s*(\\w+).*" thingType:STCThingTypeSwiftClass maps:maps];
  [self processFileAtPath:filePath matching:@"^\\s*protocol\\s+(\\w+)\\s*:\\s*(\\w+).*" thingType:STCThingTypeSwiftProtocol maps:maps];
  return maps.copy;
}

#pragma mark - generic

+ (void)processFileAtPath:(NSString *)filePath matching:(NSString *)pattern thingType:(STCThingType)thingType maps:(NSMutableOrderedSet *)maps
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
    NSArray *names = [output componentsSeparatedByString:@":"];
    if (names) {
      if ([names.lastObject isKindOfClass:[NSString class]] && ![names.lastObject length]) {
        names = @[names.firstObject];
      }
      block(names);
    }
    line = inputStream.stc_nextReadLine;
  }
  
  [inputStream close];
}

#pragma mark - init

- (instancetype)initWithThingTypeToNamesMaps:(NSArray *)maps fileRefs:(NSArray *)fileRefs
{
  if (!(self = [super init])) {
    return nil;
  }
  _thingTypeToNamesMaps = maps;
  _fileRefs = fileRefs;
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
