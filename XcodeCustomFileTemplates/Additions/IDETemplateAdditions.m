//
//  IDETemplateAdditions.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 18/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "DZLImplementationCombine.h"
#import "XcodeCustomFileTemplates.h"
#import <objc/message.h>

@interface NSObject ()
+ (id)availableTemplatesOfTemplateKind:(id)kind;
+ (void)_processChildrenOfFilePath:(id)path enumerator:(id)enumerator;
@end


@interface IDETemplateAdditions_Additions : NSObject
@end

@implementation IDETemplateAdditions_Additions

+ (void)load
{
  dzl_implementationCombine(NSClassFromString(@"IDETemplate"), self, dzl_no_assert);
}

+ (id)availableTemplatesOfTemplateKind:(id)kind
{
  NSArray *templates = dzlSuper(availableTemplatesOfTemplateKind:kind);
  
  if (![XcodeCustomFileTemplates sharedPlugin].showCustomTemplatesOnly) {
    return templates;
  }
  
  templates = [templates filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id template, NSDictionary *bindings) {
    BOOL isDataModel = [[template valueForKey:@"templateName"] isEqualToString:@"Data Model"];
    BOOL isMappingModel = [[template valueForKey:@"templateName"] isEqualToString:@"Mapping Model"];
    return !isDataModel && !isMappingModel;
  }]];
  return [[NSSet setWithArray:templates] allObjects];
}

+ (void)_processChildrenOfFilePath:(id)path enumerator:(id)enumerator
{
  if ([XcodeCustomFileTemplates sharedPlugin].showCustomTemplatesOnly && [[path valueForKey:@"pathString"] containsString: @"Templates"]) {
    NSString *pathString = [[XcodeCustomFileTemplates sharedPlugin].projectRootPath stringByAppendingPathComponent:PluginNameAndCorrespondingDirectory];
    SEL factorySel = NSSelectorFromString(@"filePathForPathString:");
    path = objc_msgSend([path class], factorySel, pathString);
  }
  
  dzlSuper(_processChildrenOfFilePath:path enumerator:enumerator);
}

@end
