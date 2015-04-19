//
//  ProjectGroup.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ProjectGroupErrorCode) {
  ProjectGroupErrorCodeMultipleOfSameFileType = 32,
  ProjectGroupErrorCodeUnsupportedFileType = 33,
};

@interface ProjectGroup : NSObject

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSArray *childRepresentedObjects;

- (NSDictionary *)validatedFileRefsByType:(NSError **)error;

@end
