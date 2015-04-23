//
//  ThingTypeToClassNamesMap.m
//  StencilPlugin
//
//  Created by Sam Dods on 22/04/2015.
//  Copyright (c) 2015 Sam Dods. All rights reserved.
//

#import "ThingTypeToClassNamesMap.h"

@implementation ThingTypeToClassNamesMap

- (instancetype)initWithThingType:(STCThingType)thingType names:(NSArray *)names
{
  if (!(self = [super init])) {
    return nil;
  }
  _thingType = thingType;
  _names = names;
  return self;
}

- (NSString *)thingTypeString
{
  switch (self.thingType) {
    case STCThingTypeObjcInterface:
      return @"interface";
    case STCThingTypeSwiftClass:
      return @"class";
    case STCThingTypeObjcProtocol:
    case STCThingTypeSwiftProtocol:
      return @"protocol";
  }
}

@end
