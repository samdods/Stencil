//
//  ProjectFile.m
//  StencilPlugin
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "ProjectFile.h"
#import "DZLImplementationSafe.h"

@interface ProjectFile : NSObject
@end

@implementation ProjectFile

+ (void)load
{
  dzl_implementationSafe(NSClassFromString(@"Xcode3FileReference"), self);
}

- (NSString *)fullPath
{
  return [self valueForKeyPath:@"reference.resolvedAbsolutePath"];
}

- (NSURL *)fileURL
{
  return [NSURL fileURLWithPath:self.fullPath];
}

- (NSString *)name
{
  return self.fullPath.lastPathComponent;
}

- (NSString *)nameWithoutExtension
{
  NSString *name = self.name;
  NSRange rangeOfDot = [name rangeOfString:@"."];
  return [name substringToIndex:rangeOfDot.location];
}

- (NSString *)extension
{
  NSString *name = self.name;
  NSRange rangeOfDot = [name rangeOfString:@"."];
  return [name substringFromIndex:rangeOfDot.location];
}

- (ProjectFileType)type
{
  NSString *extension = self.extension;
  if ([extension isEqualToString:@".h"]) {
    return ProjectFileObjcInterface;
  } else if ([extension isEqualToString:@".m"]) {
    return ProjectFileObjcImplementation;
  } else if ([extension isEqualTo:@".swift"]) {
    return ProjectFileSwift;
  } else if ([extension isEqualToString:@".xib"] || [extension isEqualToString:@".storyboard"]) {
    return ProjectFileUserInterface;
  }
  return ProjectFileUnknown;
}

@end
