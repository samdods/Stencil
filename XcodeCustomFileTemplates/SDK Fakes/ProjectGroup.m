//
//  ProjectGroup.m
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "ProjectGroup.h"
#import "ProjectFile.h"
#import "DZLImplementationSafe.h"

@implementation ProjectGroup

+ (void)load
{
  dzl_implementationSafe(NSClassFromString(@"IDEGroupNavigableItem"), self);
}

- (NSDictionary *)validatedFileRefsByType:(NSError **)error
{
  NSArray *groupFileRefs = [self valueForKey:@"childRepresentedObjects"];
  NSMutableDictionary *validatedFileRefsByType = [NSMutableDictionary new];
  for (ProjectFile *file in groupFileRefs) {
    switch (file.type) {
      case ProjectFileInterface:
      case ProjectFileImplementation:
      case ProjectFileUserInterface:
        if (validatedFileRefsByType[@(file.type)]) {
          NSString *message = [NSString stringWithFormat:@"Multiple of the same filetype (%@)", file.extension];
          [self setError:error code:ProjectGroupErrorCodeMultipleOfSameFileType message:message];
          return nil;
        }
        validatedFileRefsByType[@(file.type)] = file;
        break;
      default: {
        NSString *message = [NSString stringWithFormat:@"Unsupported filetype (%@)", file.extension];
        [self setError:error code:ProjectGroupErrorCodeUnsupportedFileType message:message];
        return nil;
      } break;
    }
  }
  return validatedFileRefsByType.copy;
}

- (void)setError:(NSError **)error code:(NSInteger)code message:(NSString *)message
{
  if (error) {
    *error = [NSError errorWithDomain:@"com.sdods.Stencil" code:code userInfo:@{NSLocalizedDescriptionKey : message}];
  }
}

@end
