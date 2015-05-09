//
//  ___FILENAME___
//  ___PROJECTNAME___
//
//  Created by ___FULLUSERNAME___ on ___DATE___.
//___COPYRIGHT___
//

#import "___FILEBASENAME___.h"

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

- (NSUInteger)hash
{
  return self.thingType ^ self.names.hash;
}

@end
