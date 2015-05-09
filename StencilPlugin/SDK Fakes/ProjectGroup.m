//
//  ProjectGroup.m
//  StencilPlugin
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "ProjectGroup.h"
#import "ProjectFile.h"

@implementation NSArray (ProjectGroupAdditions)

- (NSArray *)validatedTemplateFiles:(NSError **)error
{
  NSMutableArray *validatedFileRefs = [NSMutableArray new];
  for (id<ProjectFile> file in [self valueForKey:@"representedObject"]) {
    switch (file.type) {
      case ProjectFileObjcInterface:
      case ProjectFileObjcImplementation:
      case ProjectFileUserInterface:
      case ProjectFileSwift:
        [validatedFileRefs addObject:file];
        break;
      default: {
        NSString *message = [NSString stringWithFormat:@"Unsupported filetype (%@)", file.extension];
        [self setError:error code:ProjectGroupErrorCodeUnsupportedFileType message:message];
        return nil;
      } break;
    }
  }
  
  NSArray *fileRefs = validatedFileRefs.copy;
  BOOL isValid = [self isNotMixingSwiftWithObjc:fileRefs];
  return isValid ? fileRefs : nil;
}

- (BOOL)isNotMixingSwiftWithObjc:(NSArray *)fileRefs
{
  BOOL hasSwift = NO;
  BOOL hasObjc = NO;
  for (id<ProjectFile> file in fileRefs) {
    if (file.type == ProjectFileSwift) {
      hasSwift = YES;
    } else if (file.type != ProjectFileUserInterface) {
      hasObjc = YES;
    }
  }
  return !(hasObjc && hasSwift);
}

- (void)setError:(NSError **)error code:(NSInteger)code message:(NSString *)message
{
  if (error) {
    *error = [NSError errorWithDomain:@"com.sdods.Stencil" code:code userInfo:@{NSLocalizedDescriptionKey : message}];
  }
}

@end
