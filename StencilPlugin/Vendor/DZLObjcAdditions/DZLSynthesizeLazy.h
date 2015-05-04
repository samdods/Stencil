//
//  DZLSynthesizeLazy.h
//  DZLObjcAdditions
//
//  Created by Sam Dods on 23/05/2014.
//  Copyright (c) 2014 Sam Dods. All rights reserved.
//


#define synthesize_lazy(type, propertyName) synthesize propertyName = _ ## propertyName; \
- (type *)propertyName { \
return _ ## propertyName ?: (_ ## propertyName = [type new]); \
}
