#import "RegionBounceSettings.h"
#import <ScreenSaver/ScreenSaver.h>

#include "RegionSimulation.hpp"
#include <algorithm>
#include <cmath>

namespace {
// Keep the existing domain and keys so installed screen saver preferences survive.
ScreenSaverDefaults *Preferences() {
  ScreenSaverDefaults *defaults =
      [ScreenSaverDefaults defaultsForModuleWithName:@"com.leyanlo.RegionBounce.saver"];
  [defaults synchronize];
  return defaults;
}
} // namespace

@implementation RegionBounceSettings

- (instancetype)init {
  self = [super init];
  if (self) {
    const region_bounce::Configuration defaults;
    _mapColors = defaults.mapColorCount;
    _gridColumns = defaults.columns;
    _speed = defaults.speed;
    _palette = defaults.palette;
    _reseedSeconds = 12.0 * 60.0;
    _showAgents = YES;
    _darkAppearance = YES;
  }
  return self;
}

+ (instancetype)loadSettings {
  RegionBounceSettings *settings = [[self alloc] init];
  ScreenSaverDefaults *defaults = Preferences();
  [defaults registerDefaults:@{
    @"MapColorCount" : @(settings.mapColors),
    @"GridColumnsV2" : @(settings.gridColumns),
    @"Speed" : @(settings.speed),
    @"ReseedMinutes" : @(settings.reseedSeconds / 60.0),
    @"ShowAgents" : @(settings.showAgents),
    @"DarkAppearance" : @(settings.darkAppearance),
    @"Palette" : @(settings.palette),
  }];
  settings.mapColors = [defaults integerForKey:@"MapColorCount"];
  settings.gridColumns = [defaults integerForKey:@"GridColumnsV2"];
  settings.speed = [defaults doubleForKey:@"Speed"];
  settings.reseedSeconds = [defaults doubleForKey:@"ReseedMinutes"] * 60.0;
  settings.showAgents = [defaults boolForKey:@"ShowAgents"];
  settings.darkAppearance = [defaults boolForKey:@"DarkAppearance"];
  settings.palette = [defaults integerForKey:@"Palette"];
  [settings normalize];
  return settings;
}

- (void)normalize {
  self.mapColors = std::clamp<NSInteger>(self.mapColors, 3, 30);
  self.gridColumns = std::clamp<NSInteger>(self.gridColumns, 8, 96);
  RegionBounceSettings *defaults = [[RegionBounceSettings alloc] init];
  self.speed = std::isfinite(self.speed) ? std::clamp(self.speed, 0.5, 30.0) : defaults.speed;
  self.reseedSeconds = std::isfinite(self.reseedSeconds)
                           ? std::clamp(self.reseedSeconds, 60.0, 3600.0)
                           : defaults.reseedSeconds;
  self.palette = std::clamp<NSInteger>(self.palette, 0, 3);
}

- (void)save {
  [self normalize];
  ScreenSaverDefaults *defaults = Preferences();
  [defaults setInteger:self.mapColors forKey:@"MapColorCount"];
  [defaults setInteger:self.gridColumns forKey:@"GridColumnsV2"];
  [defaults setDouble:self.speed forKey:@"Speed"];
  [defaults setDouble:self.reseedSeconds / 60.0 forKey:@"ReseedMinutes"];
  [defaults setBool:self.showAgents forKey:@"ShowAgents"];
  [defaults setBool:self.darkAppearance forKey:@"DarkAppearance"];
  [defaults setInteger:self.palette forKey:@"Palette"];
  [defaults synchronize];
}

- (id)copyWithZone:(NSZone *)zone {
  RegionBounceSettings *copy = [[[self class] allocWithZone:zone] init];
  copy.mapColors = self.mapColors;
  copy.gridColumns = self.gridColumns;
  copy.speed = self.speed;
  copy.reseedSeconds = self.reseedSeconds;
  copy.showAgents = self.showAgents;
  copy.darkAppearance = self.darkAppearance;
  copy.palette = self.palette;
  return copy;
}

@end
