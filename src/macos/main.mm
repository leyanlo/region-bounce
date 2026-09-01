#import <Cocoa/Cocoa.h>

#import "RegionBounceAppDelegate.h"

int main(int argc, const char *argv[]) {
  (void)argc;
  (void)argv;
  @autoreleasepool {
    NSApplication *application = NSApplication.sharedApplication;
    RegionBounceAppDelegate *delegate = [[RegionBounceAppDelegate alloc] init];
    application.delegate = delegate;
    [application setActivationPolicy:NSApplicationActivationPolicyRegular];
    [application run];
  }
  return 0;
}
