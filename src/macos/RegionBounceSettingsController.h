#import <Cocoa/Cocoa.h>
#import "RegionBounceSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface RegionBounceSettingsController : NSWindowController
// Reload each time the sheet is opened. Only Save persists and invokes completion.
- (NSWindow *)configureSheetWithCompletion:(void (^)(RegionBounceSettings *settings))completion;
@end

NS_ASSUME_NONNULL_END
