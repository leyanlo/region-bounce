#import <ScreenSaver/ScreenSaver.h>

#import "RegionBounceCanvasView.h"

namespace {

NSString *const kRegionCountKey = @"RegionCount";
NSString *const kGridColumnsKey = @"GridColumns";
NSString *const kSpeedKey = @"Speed";
NSString *const kReseedMinutesKey = @"ReseedMinutes";
NSString *const kShowAgentsKey = @"ShowAgents";
NSString *const kPaletteKey = @"Palette";

NSDictionary<NSString *, id> *DefaultValues() {
  return @{
    kRegionCountKey : @14,
    kGridColumnsKey : @64,
    kSpeedKey : @7.0,
    kReseedMinutesKey : @12,
    kShowAgentsKey : @YES,
    kPaletteKey : @0,
  };
}

NSTextField *Label(NSString *text) {
  NSTextField *label = [NSTextField labelWithString:text];
  label.alignment = NSTextAlignmentRight;
  return label;
}

NSTextField *IntegerField(NSInteger value, NSInteger minimum, NSInteger maximum) {
  NSTextField *field = [NSTextField textFieldWithString:[NSString stringWithFormat:@"%ld", value]];
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  formatter.allowsFloats = NO;
  formatter.minimum = @(minimum);
  formatter.maximum = @(maximum);
  field.formatter = formatter;
  return field;
}

NSTextField *DecimalField(double value, double minimum, double maximum) {
  NSTextField *field = [NSTextField textFieldWithString:[NSString stringWithFormat:@"%.1f", value]];
  NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
  formatter.allowsFloats = YES;
  formatter.minimum = @(minimum);
  formatter.maximum = @(maximum);
  field.formatter = formatter;
  return field;
}

} // namespace

@interface RegionBounceSaverView : ScreenSaverView
@property(nonatomic, strong) RegionBounceCanvasView *canvas;
@property(nonatomic, strong) NSPanel *settingsPanel;
@property(nonatomic, strong) NSTextField *regionsField;
@property(nonatomic, strong) NSTextField *columnsField;
@property(nonatomic, strong) NSTextField *speedField;
@property(nonatomic, strong) NSTextField *reseedField;
@property(nonatomic, strong) NSButton *agentsCheckbox;
@property(nonatomic, strong) NSPopUpButton *palettePopup;
@end

@implementation RegionBounceSaverView

- (instancetype)initWithFrame:(NSRect)frame isPreview:(BOOL)isPreview {
  self = [super initWithFrame:frame isPreview:isPreview];
  if (self) {
    self.animationTimeInterval = 1.0 / 60.0;
    self.autoresizesSubviews = YES;
    [self installCanvas];
  }
  return self;
}

- (ScreenSaverDefaults *)preferences {
  NSString *identifier = [NSBundle bundleForClass:self.class].bundleIdentifier;
  ScreenSaverDefaults *defaults = [ScreenSaverDefaults defaultsForModuleWithName:identifier];
  [defaults registerDefaults:DefaultValues()];
  return defaults;
}

- (void)installCanvas {
  ScreenSaverDefaults *defaults = [self preferences];
  self.canvas =
      [[RegionBounceCanvasView alloc] initWithFrame:self.bounds
                                            regions:[defaults integerForKey:kRegionCountKey]
                                        gridColumns:[defaults integerForKey:kGridColumnsKey]
                                              speed:[defaults doubleForKey:kSpeedKey]
                                      reseedSeconds:[defaults doubleForKey:kReseedMinutesKey] * 60.0
                                         showAgents:[defaults boolForKey:kShowAgentsKey]
                                            palette:[defaults integerForKey:kPaletteKey]];
  [self addSubview:self.canvas];
}

- (void)startAnimation {
  [super startAnimation];
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
  [self buildSettingsPanelIfNeeded];
  [self populateSettingsFields];
  return self.settingsPanel;
}

- (void)buildSettingsPanelIfNeeded {
  if (self.settingsPanel) {
    return;
  }

  self.settingsPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 500, 430)
                                                  styleMask:NSWindowStyleMaskTitled
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
  self.settingsPanel.title = @"RegionBounce Settings";

  self.regionsField = IntegerField(14, 2, 30);
  self.columnsField = IntegerField(64, 16, 140);
  self.speedField = DecimalField(7.0, 0.5, 30.0);
  self.reseedField = IntegerField(12, 1, 60);
  self.agentsCheckbox = [NSButton checkboxWithTitle:@"Show moving balls" target:nil action:nil];
  self.palettePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
  [self.palettePopup addItemsWithTitles:@[ @"Earth", @"Sorbet", @"Ocean", @"Monochrome" ]];

  NSGridView *grid = [NSGridView gridViewWithViews:@[
    @[ Label(@"Regions (one ball each)"), self.regionsField ],
    @[ Label(@"Grid columns"), self.columnsField ],
    @[ Label(@"Ball speed"), self.speedField ],
    @[ Label(@"New world after (minutes)"), self.reseedField ],
    @[ Label(@"Palette"), self.palettePopup ],
  ]];
  grid.rowSpacing = 10.0;
  grid.columnSpacing = 18.0;
  [grid columnAtIndex:0].width = 205.0;
  [grid columnAtIndex:1].width = 190.0;

  NSTextField *title = [NSTextField labelWithString:@"RegionBounce"];
  title.font = [NSFont systemFontOfSize:22.0 weight:NSFontWeightSemibold];
  NSTextField *subtitle = [NSTextField
      labelWithString:
          @"Each region starts with one ball; every boundary collision converts one pixel."];
  subtitle.textColor = NSColor.secondaryLabelColor;

  NSButton *cancel = [NSButton buttonWithTitle:@"Cancel"
                                        target:self
                                        action:@selector(cancelSettings:)];
  cancel.keyEquivalent = @"\e";
  NSButton *save = [NSButton buttonWithTitle:@"Save" target:self action:@selector(saveSettings:)];
  save.keyEquivalent = @"\r";
  NSStackView *buttons = [NSStackView stackViewWithViews:@[ cancel, save ]];
  buttons.orientation = NSUserInterfaceLayoutOrientationHorizontal;
  buttons.spacing = 10.0;
  buttons.alignment = NSLayoutAttributeCenterY;

  NSStackView *content =
      [NSStackView stackViewWithViews:@[ title, subtitle, grid, self.agentsCheckbox, buttons ]];
  content.orientation = NSUserInterfaceLayoutOrientationVertical;
  content.alignment = NSLayoutAttributeLeading;
  content.spacing = 14.0;
  content.translatesAutoresizingMaskIntoConstraints = NO;
  [self.settingsPanel.contentView addSubview:content];

  [NSLayoutConstraint activateConstraints:@[
    [content.leadingAnchor constraintEqualToAnchor:self.settingsPanel.contentView.leadingAnchor
                                          constant:28.0],
    [content.trailingAnchor constraintEqualToAnchor:self.settingsPanel.contentView.trailingAnchor
                                           constant:-28.0],
    [content.topAnchor constraintEqualToAnchor:self.settingsPanel.contentView.topAnchor
                                      constant:24.0],
    [content.bottomAnchor
        constraintLessThanOrEqualToAnchor:self.settingsPanel.contentView.bottomAnchor
                                 constant:-24.0],
  ]];
}

- (void)populateSettingsFields {
  ScreenSaverDefaults *defaults = [self preferences];
  self.regionsField.integerValue = [defaults integerForKey:kRegionCountKey];
  self.columnsField.integerValue = [defaults integerForKey:kGridColumnsKey];
  self.speedField.doubleValue = [defaults doubleForKey:kSpeedKey];
  self.reseedField.integerValue = [defaults integerForKey:kReseedMinutesKey];
  self.agentsCheckbox.state =
      [defaults boolForKey:kShowAgentsKey] ? NSControlStateValueOn : NSControlStateValueOff;
  [self.palettePopup selectItemAtIndex:[defaults integerForKey:kPaletteKey]];
}

- (void)saveSettings:(id)sender {
  (void)sender;
  ScreenSaverDefaults *defaults = [self preferences];
  [defaults setInteger:self.regionsField.integerValue forKey:kRegionCountKey];
  [defaults setInteger:self.columnsField.integerValue forKey:kGridColumnsKey];
  [defaults setDouble:self.speedField.doubleValue forKey:kSpeedKey];
  [defaults setInteger:self.reseedField.integerValue forKey:kReseedMinutesKey];
  [defaults setBool:self.agentsCheckbox.state == NSControlStateValueOn forKey:kShowAgentsKey];
  [defaults setInteger:self.palettePopup.indexOfSelectedItem forKey:kPaletteKey];
  [defaults synchronize];

  [self.canvas applyRegions:self.regionsField.integerValue
                gridColumns:self.columnsField.integerValue
                      speed:self.speedField.doubleValue
              reseedSeconds:self.reseedField.doubleValue * 60.0
                 showAgents:self.agentsCheckbox.state == NSControlStateValueOn
                    palette:self.palettePopup.indexOfSelectedItem];
  [NSApp endSheet:self.settingsPanel returnCode:NSModalResponseOK];
}

- (void)cancelSettings:(id)sender {
  (void)sender;
  [NSApp endSheet:self.settingsPanel returnCode:NSModalResponseCancel];
}

@end
