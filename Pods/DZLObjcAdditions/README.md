Handy Objective-C 'Extensions'
================

This library includes extensions to enhance the language and to avoid the need for common boiler-plate code. It is light-weight and can be installed in a project completely risk-free.

# Summary of Extensions

### @implementation_combine

Like a normal category implementation with one crucial difference: any method already implemented on the underlying class is replaced in such a way that the original implementation is left intact and can be invoked with the `dzlSuper` or `dzlCombine` macro.

### @implementation_safe

Like a normal category implementation, but any method already implemented on the underlying class is not replaced. If a method is implemented by a class from which the underlying class inherits, the implementation in the category is added to the underlying class and the super class's implementation can be invoked with the `dzlSuper` macro.

### @protocol_implementation

An implementation for a protocol specification. Any optional protocol methods may be implemented here and these methods will automatically be added to any class that conforms to the protocol. (Anyone familiar with Ruby could think of this as an Objective-C equivalent to a mixin.)

### @synthesize_lazy

Synthesize an instance variable getter method, in which the underlying ivar is returned if non-nil. If the ivar is nil the ivar is set to a new instance of the given type and returned.

### @class_singleton / @class_singleton_setup

Implements a class method with the given name, returning a singleton of the specified type, with optional additional setup.

# Examples

### @implementation_combine

This is really useful if you're trying to separate concerns. For example, you might be implementing usage analytics in your app. You don't want to clutter your view controller with analytics code, because it doesn't belong there. Instead you can add a "combine" category, which effectively allows you to add new functionality to the original method.

```objc
#import "DZLImplementationCombine.h"

@implementation_combine(MainViewController, CombinedAdditions)

- (void)viewDidAppear:(BOOL)animated
{
  dzlSuper(viewDidAppear:animated); // call the underlying method.
  
  // add extra functionality.
}

@end
```

The call to `dzlSuper` can be placed anywhere in the method, or it may be omitted completely (but that would defeat the objective).

The code passed into the `dzlSuper` macro should be exactly what you would send to `super` if you were overriding this method, as in the example of `viewDidAppear:animated` above. You should not call `super` directly.

Each method specified in an `@implementation_combine` must be implemented by the underlying class, otherwise an exception is raised (from a Foundation assertion). This is because it usually only makes sense to combine with a method that already exists.

If you wish to avoid the assertion because you intentionally want to combine with a method that isn't implemented on the underlying class (because perhaps it will be at a later date), you can do so by passing the `dzl_no_assert` parameter as follows:

```objc
@implementation_combine(MainViewController, CombinedAdditions, dzl_no_assert)

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
  dzlCombine(scrollViewDidScroll:scrollView); // call the underlying method
  
  // add extra functionality.
}

@end
```

This is particularly useful if you want to "combine" with a delegate method that may legitimately be unimplemented on the underlying class.

The `dzlCombine` macro has exactly the same syntax as the `dzlSuper` macro, but does not require the method to be implemented on the underlying class. (The difference is that it will not silence the compiler's "must call super" warning if a method is declared with the `NS_REQUIRES_SUPER` attribute.)

You can check if the underlying class implements the current method by calling `dzlCanCombine()`, which returns YES if the underlying class implements the same method from which it was called. Calling `dzlSuper` or `dzlCombine` will not cause any problems if the underlying class does not implement the method, so it's not always necessary to check. It is useful if the method is expected to return a particular value.

### @implementation_safe

This is useful if you want to add a method to a class without risking replacing an existing implementation if one exists.

```objc
#import "DZLImplementationSafe.h"

@implementation_safe(MainViewController, SafeAdditions)

- (void)viewWillAppear:(BOOL)animated
{
  // do something here.
  
  dzlSuper(viewWillAppear:animated);
  
  // do some more stuff here.
}

@end
```

The call to `safeSuper` can be placed anywhere in the method, or it may be omitted.

The code passed into the `dzlSuper` macro should be exactly what you would send to `super` if you were overriding this method, as in the example of `viewWillAppear:animated` above. You should not call `super` directly.

### @protocol_implementation

This is useful if you want to provide default implementations for optional protocol methods.

For example, if you have a protocol defined as follows:

```objc
@protocol Talkative
@optional
- (void)saySomething;
@end
```

You can define default implementations for the protocol methods as follows:

```objc
#import "DZLProtocolImplementation.h"

@protocol_implementation(Talkative)

- (void)saySomething
{
  NSLog(@"Hello world!");
}

@end
```

Then your class that adopts the protocol may do so without implementing the optional methods. The optional methods may be called and the default implementation will be used.

### @synthesize_lazy

Lazy initialisation is common for many types of property, for example an `NSMutableArray` instance might be initialised as follows:

```objc
- (NSMutableArray *)transactions
{
  return _transactions ?: (_transactions = [NSMutableArray new]);
}
```

Using the `@synthesize_lazy` directive, it is simplified further as follows:

```objc
@synthesize_lazy (NSMutableArray, transactions);
```

You can place this directive at any place within your implementation.

### @class_singleton

Singletons are how we have a shared or default instance of a class, and are very common in Cocoa (`NSFileManager`, `NSNotificationCenter`, etc.). When we define them ourselves we repeat the same boiler-plate code over and over, throughout a project, which usually looks like the following:

```objc
+ (HTTPClient *)defaultClient
{
  static HTTPClient *defaultClient;
  static dispatch_once_t onceToken;
  
  dispatch_once(&onceToken, ^{
    defaultClient = [HTTPClient new];
  });
  
  return defaultClient;
}
```

This can be simplied by declaring the `@class_singleton` in your implementation:

```objc
@implementation HTTPClient

@class_singleton (HTTPClient, defaultClient);

// rest of implementation code here.

@end
```

If you need to expose your singleton in the interface, you can do so as you would normally, for example:

```objc
@interface HTTPClient

+ (instancetype)defaultClient;

@end
```

### @class_singleton_setup

Sometimes you may wish to perform further setup of your shared instance in your singleton method. Of course, common initialisation should be done in the `-init` method of your class, which will be invoked by the singleton method. But if there is any setup required specifically for the shared instance, it can achieved easily with the `@class_singleton_setup` directive:

```objc
@class_singleton_setup (HTTPClient, defaultClient,
  defaultClient.operationQueue = [NSOperationQueue new];
  defaultClient.operationQueue.maxConcurrentOperationCount = 5;
)
```

Using this method, you can refer to the newly-created shared instance by the same variable name as the name you have provided to the method. And in Xcode, you will be greeted by code-completion, which is nice!

# Installing

Available as a CocoaPod.

Alternatively, you can copy the DZLObjcAdditions directory into your project. Import the relevant header files as you need them:
* **@implementation_combine** defined in DZLImplementationCombine.h
* **@implementation_safe** defined in DZLImplementationSafe.h
* **@protocol_implementation** defined in DZLProtocolImplementation.h
* **@synthesize_lazy** defined in DZLSynthesizeLazy.h
* **@class_singleton** / **@class_singleton_setup** defined in DZLClassSingleton.h

# Disclaimer

This library makes use of the Objective-C ability to 'swizzle' methods at runtime. The implementation is very simple and I believe it is much cleaner than other examples of achieving similar results, e.g. block injection. While some people would advise against extensive method swizzling, I see no harm in it when there is a valid use-case.

Furthermore, none of the above extensions are really compiler directives. They are just macros. But the macros are written in such a way that they require the '@' symbol prefix, which I think makes them look cool!

# Twitter

If you like this, you can [follow me on twitter][twitter] for more of the same!

[twitter]: http://twitter.com/dodsios
