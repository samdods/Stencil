//
//  TemplateFactory.h
//  StencilPlugin
//
//  Created by Sam Dods on 20/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

@class TemplateConfig;

@interface TemplateFactory : NSObject

+ (instancetype)defaultFactory;

- (void)showAlertForError:(NSError *)error;

- (void)generateTemplateFromConfig:(TemplateConfig *)config;

@end
