//
//  ProjectGroup.h
//  StencilPlugin
//
//  Created by Sam Dods on 19/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, ProjectGroupErrorCode) {
  ProjectGroupErrorCodeUnsupportedFileType = 33,
};

@protocol ProjectGroup <NSObject>

@property (nonatomic, readonly) NSString *name;

@property (nonatomic, readonly) NSArray *childRepresentedObjects;

@end



@interface NSArray (ProjectGroupAdditions)

- (NSArray *)validatedTemplateFiles:(NSError **)error;

@end
