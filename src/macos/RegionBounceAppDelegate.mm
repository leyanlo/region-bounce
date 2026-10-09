#import "RegionBounceAppDelegate.h"

#import "RegionBounceCanvasView.h"
#import "RegionBounceSettingsController.h"

@interface RegionBounceAppDelegate ()
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) RegionBounceCanvasView *canvas;
@property(nonatomic, strong) NSTimer *timer;
@property(nonatomic, strong) RegionBounceSettingsController *settingsController;
@property(nonatomic, strong) NSMenuItem *darkAppearanceItem;
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
  self.window.title = @"RegionBounce Preview";
  self.window.minSize = NSMakeSize(560, 360);
  self.window.backgroundColor = NSColor.blackColor;
  self.window.collectionBehavior = NSWindowCollectionBehaviorFullScreenPrimary;

  self.canvas = [[RegionBounceCanvasView alloc] initWithFrame:self.window.contentView.bounds
                                                   settings:[RegionBounceSettings loadSettings]];
  [self reloadSettings];
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
  NSMenu *applicationMenu = [[NSMenu alloc] initWithTitle:@"RegionBounce Preview"];
  [applicationMenu addItemWithTitle:@"About RegionBounce Preview"
                             action:@selector(orderFrontStandardAboutPanel:)
                      keyEquivalent:@""];
  [applicationMenu addItem:NSMenuItem.separatorItem];
  NSMenuItem *settings = [applicationMenu addItemWithTitle:@"Settings…"
                                                 action:@selector(showSettings:)
                                          keyEquivalent:@","];
  settings.target = self;
  [applicationMenu addItem:NSMenuItem.separatorItem];
  [applicationMenu addItemWithTitle:@"Quit RegionBounce Preview"
                             action:@selector(terminate:)
                      keyEquivalent:@"q"];
  applicationItem.submenu = applicationMenu;
  [mainMenu addItem:applicationItem];

  NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
  NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
  [editMenu addItemWithTitle:@"Cut" action:@selector(cut:) keyEquivalent:@"x"];
  [editMenu addItemWithTitle:@"Copy" action:@selector(copy:) keyEquivalent:@"c"];
  [editMenu addItemWithTitle:@"Paste" action:@selector(paste:) keyEquivalent:@"v"];
  [editMenu addItemWithTitle:@"Select All" action:@selector(selectAll:) keyEquivalent:@"a"];
  editItem.submenu = editMenu;
  [mainMenu addItem:editItem];

  NSMenuItem *worldItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
  NSMenu *worldMenu = [[NSMenu alloc] initWithTitle:@"World"];
  NSMenuItem *newWorld = [worldMenu addItemWithTitle:@"New World"
                                              action:@selector(newWorld:)
                                       keyEquivalent:@"n"];
  newWorld.target = self;
  NSMenuItem *darkAppearance = [worldMenu addItemWithTitle:@"Dark Appearance"
                                                  action:@selector(toggleDarkAppearance:)
                                           keyEquivalent:@"d"];
  darkAppearance.target = self;
  self.darkAppearanceItem = darkAppearance;
  [worldMenu addItem:NSMenuItem.separatorItem];
  [worldMenu addItemWithTitle:@"Enter Full Screen"
                       action:@selector(toggleFullScreen:)
                keyEquivalent:@"f"];
  worldItem.submenu = worldMenu;
  [mainMenu addItem:worldItem];

  NSApp.mainMenu = mainMenu;
}

- (BOOL)validateMenuItem:(NSMenuItem *)item {
  if (item.action == @selector(toggleDarkAppearance:) || item.action == @selector(newWorld:)) {
    return self.window.attachedSheet == nil;
  }
  return YES;
}

- (void)reloadSettings {
  RegionBounceSettings *settings = [RegionBounceSettings loadSettings];
  [self.canvas applySettings:settings];
  self.darkAppearanceItem.state = settings.darkAppearance ? NSControlStateValueOn
                                                         : NSControlStateValueOff;
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
  (void)notification;
  [self reloadSettings];
}

- (void)toggleDarkAppearance:(NSMenuItem *)sender {
  (void)sender;
  RegionBounceSettings *settings = [RegionBounceSettings loadSettings];
  settings.darkAppearance = !settings.darkAppearance;
  [settings save];
  [self reloadSettings];
}

- (void)showSettings:(id)sender {
  (void)sender;
  if (self.window.attachedSheet) {
    return;
  }
  if (!self.settingsController) {
    self.settingsController = [[RegionBounceSettingsController alloc] init];
  }
  __weak RegionBounceAppDelegate *weakSelf = self;
  NSWindow *sheet = [self.settingsController
      configureSheetWithCompletion:^(RegionBounceSettings *settings) {
        (void)settings;
        [weakSelf reloadSettings];
      }];
  [self.window beginSheet:sheet completionHandler:nil];
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
