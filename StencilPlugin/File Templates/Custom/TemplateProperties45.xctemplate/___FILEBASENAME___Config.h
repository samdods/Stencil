//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import "TemplateProperties.h"

#import <Foundation/Foundation.h>
#import "ProjectGroup.h"
#import "ThingTypeToClassNamesMap.h"


@interface ___FILEBASENAMEASIDENTIFIER___ : TemplateProperties

@property (nonatomic, readonly) NSString *templateName;
@property (nonatomic, readonly) STCThingType thingType;
@property (nonatomic, readonly) NSString *thingNameToReplace;
@property (nonatomic, readonly) NSString *thingNameToInheritFrom;
@property (nonatomic, readonly) NSString *templateDescription;
@property (nonatomic, readonly) NSDictionary *templateFilenameByOriginalFilename;

- (instancetype)initWithName:(NSString *)name thingType:(STCThingType)thingType nameToReplace:(NSString *)replace inheritFrom:(NSString *)inherit description:(NSString *)description templateFileMap:(NSDictionary *)templateFileMap;

@end



@interface TemplateConfig : NSObject

/**
 *  Generates the defaults for the given group. Use this method to instantiate a template config and then
 *  change the properties as needed, usually based on user input.
 *
 *  @param group  The group on which the template config will be based.
 *  @param error  On return, this error will be set if something went wrong. Otherwise this will be unchanged from input.
 *
 *  @return A new template config instance, with default properties based on the specified group, or nil if something went wrong.
 */
+ (instancetype)defaultConfigForFiles:(NSArray *)files error:(NSError **)error;

@property (nonatomic, readonly) NSArray *thingTypeToNamesMaps;
@property (nonatomic, readonly) NSArray *fileRefs;

@property (nonatomic, readonly) TemplateProperties *properties;

@end
