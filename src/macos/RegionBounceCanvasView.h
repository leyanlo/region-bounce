#import <Cocoa/Cocoa.h>
#import "RegionBounceSettings.h"

NS_ASSUME_NONNULL_BEGIN

@interface RegionBounceCanvasView : NSView
- (instancetype)initWithFrame:(NSRect)frame settings:(RegionBounceSettings *)settings;
- (instancetype)initWithFrame:(NSRect)frame;
- (nullable instancetype)initWithCoder:(NSCoder *)coder;

- (void)startAnimating;
- (void)stopAnimating;
- (void)tick;
- (void)reseed;
- (void)applySettings:(RegionBounceSettings *)settings;
@end

NS_ASSUME_NONNULL_END
