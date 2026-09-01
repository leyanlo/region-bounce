#import "RegionBounceCanvasView.h"

#include "RegionSimulation.hpp"

#include <algorithm>
#include <cmath>
#include <memory>

using region_bounce::Color;
using region_bounce::Configuration;
using region_bounce::Simulation;

@implementation RegionBounceCanvasView {
  std::unique_ptr<Simulation> _simulation;
  NSInteger _regions;
  NSInteger _particles;
  NSInteger _gridColumns;
  NSInteger _resistance;
  double _speed;
  NSTimeInterval _reseedSeconds;
  BOOL _showAgents;
  NSInteger _palette;
  BOOL _active;
  NSTimeInterval _lastTick;
  NSTimeInterval _worldAge;
  NSInteger _currentRows;
}

- (instancetype)initWithFrame:(NSRect)frame {
  return [self initWithFrame:frame
                     regions:14
                   particles:8
                 gridColumns:64
                  resistance:4
                       speed:7.0
               reseedSeconds:12.0 * 60.0
                  showAgents:YES
                     palette:0];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self applyRegions:14
             particles:8
           gridColumns:64
            resistance:4
                 speed:7.0
         reseedSeconds:12.0 * 60.0
            showAgents:YES
               palette:0];
  }
  return self;
}

- (instancetype)initWithFrame:(NSRect)frame
                      regions:(NSInteger)regions
                    particles:(NSInteger)particles
                  gridColumns:(NSInteger)gridColumns
                   resistance:(NSInteger)resistance
                        speed:(double)speed
                reseedSeconds:(NSTimeInterval)reseedSeconds
                   showAgents:(BOOL)showAgents
                      palette:(NSInteger)palette {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self applyRegions:regions
             particles:particles
           gridColumns:gridColumns
            resistance:resistance
                 speed:speed
         reseedSeconds:reseedSeconds
            showAgents:showAgents
               palette:palette];
  }
  return self;
}

- (BOOL)isOpaque {
  return YES;
}

- (BOOL)isFlipped {
  return YES;
}

- (void)applyRegions:(NSInteger)regions
           particles:(NSInteger)particles
         gridColumns:(NSInteger)gridColumns
          resistance:(NSInteger)resistance
               speed:(double)speed
       reseedSeconds:(NSTimeInterval)reseedSeconds
          showAgents:(BOOL)showAgents
             palette:(NSInteger)palette {
  _regions = std::clamp<NSInteger>(regions, 2, 30);
  _particles = std::clamp<NSInteger>(particles, 1, 24);
  _gridColumns = std::clamp<NSInteger>(gridColumns, 16, 140);
  _resistance = std::clamp<NSInteger>(resistance, 1, 20);
  _speed = std::clamp(speed, 0.5, 30.0);
  _reseedSeconds = std::clamp<NSTimeInterval>(reseedSeconds, 60.0, 60.0 * 60.0);
  _showAgents = showAgents;
  _palette = std::clamp<NSInteger>(palette, 0, 3);
  [self rebuildForCurrentBounds];
}

- (void)rebuildForCurrentBounds {
  const NSSize size = self.bounds.size;
  const double width = std::max(1.0, static_cast<double>(size.width));
  const double height = std::max(1.0, static_cast<double>(size.height));
  _currentRows = std::max<NSInteger>(8, std::lround(_gridColumns * height / width));

  Configuration configuration;
  configuration.columns = static_cast<int>(_gridColumns);
  configuration.rows = static_cast<int>(_currentRows);
  configuration.regionCount = static_cast<int>(_regions);
  configuration.agentCount = static_cast<int>(_particles);
  configuration.resistance = static_cast<int>(_resistance);
  configuration.speed = _speed;
  configuration.palette = static_cast<int>(_palette);
  _simulation = std::make_unique<Simulation>(configuration);
  _worldAge = 0.0;
  self.needsDisplay = YES;
}

- (void)ensureGridMatchesBounds {
  const NSSize size = self.bounds.size;
  if (size.width <= 0.0 || size.height <= 0.0) {
    return;
  }
  const NSInteger desiredRows =
      std::max<NSInteger>(8, std::lround(_gridColumns * static_cast<double>(size.height) /
                                         static_cast<double>(size.width)));
  if (!_simulation || desiredRows != _currentRows) {
    [self rebuildForCurrentBounds];
  }
}

- (void)startAnimating {
  _active = YES;
  _lastTick = NSProcessInfo.processInfo.systemUptime;
  [self ensureGridMatchesBounds];
}

- (void)stopAnimating {
  _active = NO;
  _lastTick = 0.0;
  _simulation.reset();
}

- (void)tick {
  if (!_active) {
    return;
  }

  [self ensureGridMatchesBounds];
  const NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
  const NSTimeInterval elapsed = std::clamp(now - _lastTick, 0.0, 0.1);
  _lastTick = now;
  _worldAge += elapsed;
  if (_worldAge >= _reseedSeconds) {
    [self reseed];
  } else if (_simulation) {
    _simulation->advance(elapsed);
  }
  self.needsDisplay = YES;
}

- (void)reseed {
  if (!_simulation) {
    [self rebuildForCurrentBounds];
  } else {
    _simulation->reset();
    _worldAge = 0.0;
    self.needsDisplay = YES;
  }
}

- (void)drawRect:(NSRect)dirtyRect {
  (void)dirtyRect;
  CGContextRef context = NSGraphicsContext.currentContext.CGContext;
  CGContextSetRGBFillColor(context, 0.025, 0.028, 0.03, 1.0);
  CGContextFillRect(context, NSRectToCGRect(self.bounds));
  if (!_simulation) {
    return;
  }

  const CGFloat cellWidth = self.bounds.size.width / _simulation->columns();
  const CGFloat cellHeight = self.bounds.size.height / _simulation->rows();
  CGContextSetShouldAntialias(context, false);

  for (int row = 0; row < _simulation->rows(); ++row) {
    for (int column = 0; column < _simulation->columns(); ++column) {
      const region_bounce::Cell &cell = _simulation->cell(column, row);
      const Color base = _simulation->colorForOwner(cell.owner);
      CGContextSetRGBFillColor(context, base.red, base.green, base.blue, 1.0);
      const CGRect cellRect =
          CGRectMake(column * cellWidth, row * cellHeight, cellWidth + 0.5, cellHeight + 0.5);
      CGContextFillRect(context, cellRect);

      if (cell.challenger >= 0 && cell.impacts > 0) {
        const Color challenge = _simulation->colorForOwner(cell.challenger);
        const CGFloat progress =
            std::clamp(static_cast<CGFloat>(cell.impacts) / _simulation->resistance(), 0.0, 1.0);
        const CGFloat scale = std::sqrt(progress);
        const CGFloat width = cellWidth * scale;
        const CGFloat height = cellHeight * scale;
        const CGRect contested = CGRectMake(CGRectGetMidX(cellRect) - width / 2.0,
                                            CGRectGetMidY(cellRect) - height / 2.0, width, height);
        CGContextSetRGBFillColor(context, challenge.red * 0.86, challenge.green * 0.86,
                                 challenge.blue * 0.86, 1.0);
        CGContextFillRect(context, contested);
      }
    }
  }

  if (!_showAgents) {
    return;
  }

  CGContextSetShouldAntialias(context, true);
  const CGFloat radius = std::max<CGFloat>(2.0, std::min(cellWidth, cellHeight) * 0.28);
  for (const region_bounce::Agent &agent : _simulation->agents()) {
    const CGPoint center = CGPointMake(agent.x * cellWidth, agent.y * cellHeight);
    if (agent.flash > 0.0) {
      const CGFloat ringRadius = radius * (1.7 + agent.flash * 1.8);
      CGContextSetLineWidth(context, std::max<CGFloat>(1.0, radius * 0.22));
      CGContextSetRGBStrokeColor(context, 1.0, 1.0, 1.0, agent.flash * 0.42);
      CGContextStrokeEllipseInRect(context, CGRectMake(center.x - ringRadius, center.y - ringRadius,
                                                       ringRadius * 2.0, ringRadius * 2.0));
    }
    CGContextSetShadowWithColor(context, CGSizeZero, radius * 1.4,
                                [NSColor colorWithWhite:1.0 alpha:0.45].CGColor);
    CGContextSetRGBFillColor(context, 1.0, 1.0, 0.98, 1.0);
    CGContextFillEllipseInRect(
        context, CGRectMake(center.x - radius, center.y - radius, radius * 2.0, radius * 2.0));
    CGContextSetShadowWithColor(context, CGSizeZero, 0.0, nullptr);
  }
}

@end
