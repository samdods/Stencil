//
//  ProjectGroup.m
//  StencilPlugin
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "ProjectGroup.h"
#import "ProjectFile.h"
#import "DZLImplementationSafe.h"

@interface ProjectGroup : NSObject
@end

@implementation ProjectGroup

+ (void)load
{
  dzl_implementationSafe(NSClassFromString(@"IDEGroupNavigableItem"), self);
}

- (NSDictionary *)validatedFileRefsByType:(NSError **)error
{
  NSArray *groupFileRefs = [[self valueForKey:@"childRepresentedObjects"] filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
    return [evaluatedObject isKindOfClass:NSClassFromString(@"Xcode3FileReference")];
  }]];
  NSMutableDictionary *validatedFileRefsByType = [NSMutableDictionary new];
  for (id<ProjectFile> file in groupFileRefs) {
    switch (file.type) {
      case ProjectFileObjcInterface:
      case ProjectFileObjcImplementation:
      case ProjectFileUserInterface:
      case ProjectFileSwift:
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
  
  NSDictionary *fileRefs = validatedFileRefsByType.copy;
  BOOL isValid = [self areHeaderAndImplementationSameName:fileRefs];
  isValid = isValid && [self isNotMixingSwiftWithObjc:fileRefs];
  return isValid ? fileRefs : nil;
}

- (BOOL)areHeaderAndImplementationSameName:(NSDictionary *)fileRefsByType
{
  id<ProjectFile> header = fileRefsByType[@(ProjectFileObjcInterface)];
  id<ProjectFile> implem = fileRefsByType[@(ProjectFileObjcImplementation)];
  if (header && implem) {
    return [header.nameWithoutExtension isEqualToString:implem.nameWithoutExtension];
  }
  return YES;
}

- (BOOL)isNotMixingSwiftWithObjc:(NSDictionary *)fileRefsByType
{
  id<ProjectFile> swiftFile = fileRefsByType[@(ProjectFileSwift)];
  if (!swiftFile) {
    return YES;
  }
  id<ProjectFile> header = fileRefsByType[@(ProjectFileObjcInterface)];
  id<ProjectFile> implem = fileRefsByType[@(ProjectFileObjcImplementation)];
  return (!header && !implem);
}

- (void)setError:(NSError **)error code:(NSInteger)code message:(NSString *)message
{
  if (error) {
    *error = [NSError errorWithDomain:@"com.sdods.Stencil" code:code userInfo:@{NSLocalizedDescriptionKey : message}];
  }
}

@end
