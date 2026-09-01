#import "RegionBounceAppDelegate.h"

#import "RegionBounceCanvasView.h"

@interface RegionBounceAppDelegate ()
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) RegionBounceCanvasView *canvas;
@property(nonatomic, strong) NSTimer *timer;
@end

@implementation RegionBounceAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
  (void)notification;
  [self installMenus];

  self.window = [[NSWindow alloc]
      initWithContentRect:NSMakeRect(0, 0, 1120, 760)
                styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                          NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                  backing:NSBackingStoreBuffered
                    defer:NO];
  self.window.title = @"RegionBounce";
  self.window.minSize = NSMakeSize(560, 360);
  self.window.backgroundColor = NSColor.blackColor;
  self.window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;

  self.canvas = [[RegionBounceCanvasView alloc] initWithFrame:self.window.contentView.bounds];
  self.window.contentView = self.canvas;
  [self.window center];
  [self.window makeKeyAndOrderFront:nil];
  [NSApp activateIgnoringOtherApps:YES];

  [self.canvas startAnimating];
  __weak RegionBounceCanvasView *weakCanvas = self.canvas;
  self.timer = [NSTimer scheduledTimerWithTimeInterval:1.0 / 60.0
                                               repeats:YES
                                                 block:^(NSTimer *timer) {
                                                   (void)timer;
                                                   [weakCanvas tick];
                                                 }];
  self.timer.tolerance = 1.0 / 240.0;
}

- (void)installMenus {
  NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@""];

  NSMenuItem *applicationItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
  NSMenu *applicationMenu = [[NSMenu alloc] initWithTitle:@"RegionBounce"];
  [applicationMenu addItemWithTitle:@"About RegionBounce"
                             action:@selector(orderFrontStandardAboutPanel:)
                      keyEquivalent:@""];
  [applicationMenu addItem:NSMenuItem.separatorItem];
  [applicationMenu addItemWithTitle:@"Quit RegionBounce"
                             action:@selector(terminate:)
                      keyEquivalent:@"q"];
  applicationItem.submenu = applicationMenu;
  [mainMenu addItem:applicationItem];

  NSMenuItem *worldItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
  NSMenu *worldMenu = [[NSMenu alloc] initWithTitle:@"World"];
  NSMenuItem *newWorld = [worldMenu addItemWithTitle:@"New World"
                                              action:@selector(newWorld:)
                                       keyEquivalent:@"n"];
  newWorld.target = self;
  [worldMenu addItem:NSMenuItem.separatorItem];
  [worldMenu addItemWithTitle:@"Enter Full Screen"
                       action:@selector(toggleFullScreen:)
                keyEquivalent:@"f"];
  worldItem.submenu = worldMenu;
  [mainMenu addItem:worldItem];

  NSApp.mainMenu = mainMenu;
}

- (void)newWorld:(id)sender {
  (void)sender;
  [self.canvas reseed];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
  (void)sender;
  return YES;
}

- (void)applicationWillTerminate:(NSNotification *)notification {
  (void)notification;
  [self.timer invalidate];
  self.timer = nil;
  [self.canvas stopAnimating];
}

@end
