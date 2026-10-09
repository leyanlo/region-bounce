#import <ScreenSaver/ScreenSaver.h>

#import "RegionBounceCanvasView.h"
#import "RegionBounceSettingsController.h"

@interface RegionBounceSaverView : ScreenSaverView
@property(nonatomic, strong) RegionBounceCanvasView *canvas;
@property(nonatomic, strong) RegionBounceSettingsController *settingsController;
@end

@implementation RegionBounceSaverView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
  self = [super initWithFrame:frame isPreview:isPreview];
  if (self) {
    self.animationTimeInterval = 1.0 / 60.0;
    self.autoresizesSubviews = YES;
    self.canvas = [[RegionBounceCanvasView alloc] initWithFrame:self.bounds
                                                     settings:[RegionBounceSettings loadSettings]];
    [self addSubview:self.canvas];
  }
  return self;
}

- (void)startAnimation {
  [super startAnimation];
  [self.canvas applySettings:[RegionBounceSettings loadSettings]];
  [self.canvas startAnimating];
}

- (void)animateOneFrame {
  [self.canvas tick];
}

- (void)stopAnimation {
  [self.canvas stopAnimating];
  [super stopAnimation];
}

- (BOOL)hasConfigureSheet {
  return YES;
}

- (NSWindow *)configureSheet {
  if (!self.settingsController) {
    self.settingsController = [[RegionBounceSettingsController alloc] init];
  }
  __weak RegionBounceSaverView *weakSelf = self;
  return [self.settingsController configureSheetWithCompletion:^(RegionBounceSettings *settings) {
    [weakSelf.canvas applySettings:settings];
  }];
}

@end
