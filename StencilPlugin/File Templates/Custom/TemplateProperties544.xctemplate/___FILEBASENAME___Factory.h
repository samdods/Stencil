//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import "TemplateProperties.h"

#import <Foundation/Foundation.h>

@class TemplateConfig;

@interface TemplateFactory : NSObject

+ (instancetype)defaultFactory;

- (void)showAlertForError:(NSError *)error;

- (void)showAlertWithMessage:(NSString *)message;

- (void)generateTemplateFromConfig:(TemplateConfig *)config;

@end
