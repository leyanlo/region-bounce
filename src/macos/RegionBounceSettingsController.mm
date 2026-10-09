#import "RegionBounceSettingsController.h"

namespace {

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

@interface RegionBounceSettingsController ()
@property(nonatomic, strong) NSTextField *mapColorsField;
@property(nonatomic, strong) NSTextField *columnsField;
@property(nonatomic, strong) NSTextField *speedField;
@property(nonatomic, strong) NSTextField *reseedField;
@property(nonatomic, strong) NSButton *agentsCheckbox;
@property(nonatomic, strong) NSButton *darkCheckbox;
@property(nonatomic, strong) NSPopUpButton *palettePopup;
@property(nonatomic, copy) void (^completion)(RegionBounceSettings *settings);
@end

@implementation RegionBounceSettingsController

- (instancetype)init {
  return [super initWithWindow:nil];
}

- (NSWindow *)configureSheetWithCompletion:(void (^)(RegionBounceSettings *))completion {
  if (!self.window) {
    [self loadWindow];
  }
  NSWindow *sheet = self.window;
  self.completion = completion;
  RegionBounceSettings *settings = [RegionBounceSettings loadSettings];
  self.mapColorsField.integerValue = settings.mapColors;
  self.columnsField.integerValue = settings.gridColumns;
  self.speedField.doubleValue = settings.speed;
  self.reseedField.integerValue = settings.reseedSeconds / 60.0;
  self.agentsCheckbox.state = settings.showAgents ? NSControlStateValueOn : NSControlStateValueOff;
  self.darkCheckbox.state = settings.darkAppearance ? NSControlStateValueOn : NSControlStateValueOff;
  [self.palettePopup selectItemAtIndex:settings.palette];
  return sheet;
}

- (void)loadWindow {
  self.window = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 540, 470)
                                                  styleMask:NSWindowStyleMaskTitled
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
  self.window.title = @"RegionBounce Settings";

  self.mapColorsField = IntegerField(0, 3, 30);
  self.columnsField = IntegerField(0, 8, 96);
  self.speedField = DecimalField(0, 0.5, 30.0);
  self.reseedField = IntegerField(0, 1, 60);
  self.agentsCheckbox = [NSButton checkboxWithTitle:@"Show moving balls" target:nil action:nil];
  self.darkCheckbox = [NSButton checkboxWithTitle:@"Dark appearance" target:nil action:nil];
  self.palettePopup = [[NSPopUpButton alloc] initWithFrame:NSZeroRect pullsDown:NO];
  [self.palettePopup addItemsWithTitles:@[ @"Earth", @"Sorbet", @"Ocean", @"Monochrome" ]];

  NSGridView *grid = [NSGridView gridViewWithViews:@[
    @[ Label(@"Random starting colors"), self.mapColorsField ],
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
          @"Three balls carry distinct colors and gradually replace the randomized map."];
  subtitle.lineBreakMode = NSLineBreakByWordWrapping;
  subtitle.maximumNumberOfLines = 0;
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
      [NSStackView stackViewWithViews:@[ title, subtitle, grid, self.agentsCheckbox, self.darkCheckbox, buttons ]];
  content.orientation = NSUserInterfaceLayoutOrientationVertical;
  content.alignment = NSLayoutAttributeLeading;
  content.spacing = 14.0;
  content.translatesAutoresizingMaskIntoConstraints = NO;
  [self.window.contentView addSubview:content];

  [NSLayoutConstraint activateConstraints:@[
    [content.leadingAnchor constraintEqualToAnchor:self.window.contentView.leadingAnchor
                                          constant:28.0],
    [content.trailingAnchor constraintEqualToAnchor:self.window.contentView.trailingAnchor
                                           constant:-28.0],
    [content.topAnchor constraintEqualToAnchor:self.window.contentView.topAnchor
                                      constant:24.0],
    [content.bottomAnchor
        constraintLessThanOrEqualToAnchor:self.window.contentView.bottomAnchor
                                 constant:-24.0],
  ]];
}

- (void)saveSettings:(id)sender {
  (void)sender;
  // Commit the active field before reading it; invalid edits keep the sheet open.
  if (![self.window makeFirstResponder:nil]) {
    return;
  }
  RegionBounceSettings *settings = [[RegionBounceSettings alloc] init];
  settings.mapColors = self.mapColorsField.integerValue;
  settings.gridColumns = self.columnsField.integerValue;
  settings.speed = self.speedField.doubleValue;
  settings.reseedSeconds = self.reseedField.doubleValue * 60.0;
  settings.showAgents = self.agentsCheckbox.state == NSControlStateValueOn;
  settings.darkAppearance = self.darkCheckbox.state == NSControlStateValueOn;
  settings.palette = self.palettePopup.indexOfSelectedItem;
  [settings save];
  if (self.completion) {
    self.completion(settings);
  }
  self.completion = nil;
  [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseOK];
}

- (void)cancelSettings:(id)sender {
  (void)sender;
  // Discard even an invalid in-progress edit when cancelling.
  [self.window endEditingFor:nil];
  self.completion = nil;
  [self.window.sheetParent endSheet:self.window returnCode:NSModalResponseCancel];
}

@end
