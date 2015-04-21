//
//  TemplateConfig.h
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProjectGroup.h"

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
+ (instancetype)defaultConfigForGroup:(id<ProjectGroup>)group error:(NSError **)error;

@property (nonatomic, readonly) NSArray *availableSuperclassNames;
@property (nonatomic, readonly) NSDictionary *fileRefs;

@property (nonatomic, assign) NSUInteger selectedSuperclassNameIndex;
@property (nonatomic, copy) NSString *templateDescription;

@end
