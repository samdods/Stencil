//
//  IDETemplateAdditions.m
//  StencilPlugin
//
//  Created by Sam Dods on 18/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "DZLImplementationCombine.h"
#import "Stencil.h"
#import <objc/message.h>

@interface NSObject ()
+ (id)availableTemplatesOfTemplateKind:(id)kind;
+ (void)_processChildrenOfFilePath:(id)path enumerator:(id)enumerator;
@end


// this is required for the method +[IDETemplate availableTemplatesOfTemplateKind:]
// see http://petersteinberger.com/blog/2014/a-story-about-swizzling-the-right-way-and-touch-forwarding/
static IMP PSPDFReplaceMethodWithBlock(Class c, SEL origSEL, id block) {
  NSCParameterAssert(block);
  
  // get original method
  Method origMethod = class_getClassMethod(c, origSEL);
  if (!origMethod) {
    return nil;
  }
  
  // convert block to IMP trampoline and replace method implementation
  IMP newIMP = imp_implementationWithBlock(block);
  
  // Try adding the method if not yet in the current class
  if (!class_addMethod(object_getClass(c), origSEL, newIMP, method_getTypeEncoding(origMethod))) {
    return method_setImplementation(origMethod, newIMP);
  }else {
    return method_getImplementation(origMethod);
  }
}


@interface IDETemplateAdditions_Additions : NSObject
@end

@implementation IDETemplateAdditions_Additions

+ (void)load
{
  dzl_implementationCombine(NSClassFromString(@"IDETemplate"), self, dzl_no_assert);
  
  SEL selector = NSSelectorFromString(@"availableTemplatesOfTemplateKind:");
  __block IMP originalIMP = PSPDFReplaceMethodWithBlock(NSClassFromString(@"IDETemplate"), selector, ^id(id _self, id kind) {
    // call the original method
    NSArray *templates = ((id ( *)(id, SEL, id))originalIMP)(_self, selector, kind);
    
    // now manipulate if necessary
    if (![Stencil sharedPlugin].showCustomTemplatesOnly) {
      // not necessary, so return result of original method
      return templates;
    }
    
    templates = [templates filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id template, NSDictionary *bindings) {
      BOOL isDataModel = [[template valueForKey:@"templateName"] isEqualToString:@"Data Model"];
      BOOL isMappingModel = [[template valueForKey:@"templateName"] isEqualToString:@"Mapping Model"];
      return !isDataModel && !isMappingModel;
    }]];
    return [[NSSet setWithArray:templates] allObjects];
  });
}

+ (void)_processChildrenOfFilePath:(id)path enumerator:(id)enumerator
{
  if ([Stencil sharedPlugin].showCustomTemplatesOnly && [[path valueForKey:@"pathString"] containsString:@"Templates"]) {
    NSString *rootPath = [Stencil sharedPlugin].projectRootPath;
    if (rootPath) {
      NSString *pathString = [rootPath stringByAppendingPathComponent:PluginNameAndCorrespondingDirectory];
      SEL factorySel = NSSelectorFromString(@"filePathForPathString:");
      path = objc_msgSend([path class], factorySel, pathString);
    }
  }
  
  dzlSuper(_processChildrenOfFilePath:path enumerator:enumerator);
}

@end
