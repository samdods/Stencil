//
//  ProjectFile.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ProjectGroup.h"

typedef NS_ENUM(NSInteger, ProjectFileType) {
  ProjectFileUnknown,
  ProjectFileInterface,
  ProjectFileImplementation,
  ProjectFileUserInterface,
};

@protocol ProjectFile <NSObject>

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) ProjectFileType type;

@property (nonatomic, readonly) NSString *extension;

@property (nonatomic, readonly) NSString *fullPath;

@property (nonatomic, readonly) NSURL *fileURL;

@property (nonatomic, readonly) id<ProjectGroup> parentItem;

@end
