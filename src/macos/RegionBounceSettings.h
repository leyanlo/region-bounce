#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// A snapshot shared by the screen saver, preview, and settings panel.
@interface RegionBounceSettings : NSObject <NSCopying>
@property(nonatomic) NSInteger mapColors;
@property(nonatomic) NSInteger gridColumns;
@property(nonatomic) double speed;
@property(nonatomic) NSTimeInterval reseedSeconds;
@property(nonatomic) BOOL showAgents;
@property(nonatomic) BOOL darkAppearance;
@property(nonatomic) NSInteger palette;

+ (instancetype)loadSettings;
- (void)save;
- (void)normalize;
@end

NS_ASSUME_NONNULL_END
