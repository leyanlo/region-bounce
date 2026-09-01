#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RegionBounceCanvasView : NSView

- (instancetype)initWithFrame:(NSRect)frame
                    mapColors:(NSInteger)mapColors
                  gridColumns:(NSInteger)gridColumns
                        speed:(double)speed
                reseedSeconds:(NSTimeInterval)reseedSeconds
                   showAgents:(BOOL)showAgents
                      palette:(NSInteger)palette;

- (instancetype)initWithFrame:(NSRect)frame;
- (nullable instancetype)initWithCoder:(NSCoder *)coder;

- (void)startAnimating;
- (void)stopAnimating;
- (void)tick;
- (void)reseed;
- (void)applyMapColors:(NSInteger)mapColors
           gridColumns:(NSInteger)gridColumns
                 speed:(double)speed
         reseedSeconds:(NSTimeInterval)reseedSeconds
            showAgents:(BOOL)showAgents
               palette:(NSInteger)palette;

@end

NS_ASSUME_NONNULL_END
