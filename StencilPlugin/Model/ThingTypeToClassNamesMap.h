//
//  ThingTypeToClassNamesMap.h
//  StencilPlugin
//
//  Created by Sam Dods on 22/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, STCThingType) {
  STCThingTypeObjcInterface,
  STCThingTypeObjcProtocol,
  STCThingTypeSwiftClass,
  STCThingTypeSwiftProtocol,
};

@interface ThingTypeToClassNamesMap : NSObject

@property (nonatomic, readonly) STCThingType thingType;
@property (nonatomic, readonly) NSArray *names;

- (instancetype)initWithThingType:(STCThingType)thingType names:(NSArray *)names;

@property (nonatomic, readonly) NSString *thingTypeString;

@end
