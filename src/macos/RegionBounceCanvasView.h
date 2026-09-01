#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface RegionBounceCanvasView : NSView

- (instancetype)initWithFrame:(NSRect)frame
                      regions:(NSInteger)regions
                    particles:(NSInteger)particles
                  gridColumns:(NSInteger)gridColumns
                   resistance:(NSInteger)resistance
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
- (void)applyRegions:(NSInteger)regions
           particles:(NSInteger)particles
         gridColumns:(NSInteger)gridColumns
          resistance:(NSInteger)resistance
               speed:(double)speed
       reseedSeconds:(NSTimeInterval)reseedSeconds
          showAgents:(BOOL)showAgents
             palette:(NSInteger)palette;

@end

NS_ASSUME_NONNULL_END
