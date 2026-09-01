#import <Cocoa/Cocoa.h>
#import <ScreenSaver/ScreenSaver.h>

int main(int argc, const char *argv[]) {
  @autoreleasepool {
    [NSApplication sharedApplication];
    if (argc != 2) {
      NSLog(@"Expected a path to RegionBounce.saver");
      return 2;
    }

    NSString *path = [NSString stringWithUTF8String:argv[1]];
    NSBundle *bundle = [NSBundle bundleWithPath:path];
    NSError *error = nil;
    if (![bundle loadAndReturnError:&error]) {
      NSLog(@"Could not load saver bundle: %@", error);
      return 3;
    }

    Class principalClass = bundle.principalClass;
    if (![principalClass isSubclassOfClass:ScreenSaverView.class]) {
      NSLog(@"Principal class is not a ScreenSaverView: %@", principalClass);
      return 4;
    }

    ScreenSaverView *view = [[principalClass alloc] initWithFrame:NSMakeRect(0, 0, 800, 500)
                                                        isPreview:YES];
    if (!view) {
      NSLog(@"Could not instantiate the saver view");
      return 5;
    }
    [view startAnimation];
    for (int frame = 0; frame < 8; ++frame) {
      [view animateOneFrame];
    }
    [view display];
    [view stopAnimation];
    if (!view.hasConfigureSheet || view.configureSheet == nil) {
      NSLog(@"Saver did not provide its configuration sheet");
      return 6;
    }
    [view startAnimation];
    [view animateOneFrame];
    [view stopAnimation];
    NSLog(@"Loaded and exercised %@", path.lastPathComponent);
  }
  return 0;
}
