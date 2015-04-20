//
//  TemplateConfig.h
//  XcodeCustomFileTemplates
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TemplateConfig : NSObject

@property (nonatomic, readonly) NSString *superclassName;
@property (nonatomic, readonly) NSString *templateDescription;

- (instancetype)initWithSuperclassName:(NSString *)name description:(NSString *)description;

@end
