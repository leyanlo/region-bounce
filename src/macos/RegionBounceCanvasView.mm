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
  NSInteger _gridColumns;
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
                 gridColumns:64
                       speed:7.0
               reseedSeconds:12.0 * 60.0
                  showAgents:YES
                     palette:0];
}

- (nullable instancetype)initWithCoder:(NSCoder *)coder {
  self = [super initWithCoder:coder];
  if (self) {
    [self applyRegions:14
           gridColumns:64
                 speed:7.0
         reseedSeconds:12.0 * 60.0
            showAgents:YES
               palette:0];
  }
  return self;
}

- (instancetype)initWithFrame:(NSRect)frame
                      regions:(NSInteger)regions
                  gridColumns:(NSInteger)gridColumns
                        speed:(double)speed
                reseedSeconds:(NSTimeInterval)reseedSeconds
                   showAgents:(BOOL)showAgents
                      palette:(NSInteger)palette {
  self = [super initWithFrame:frame];
  if (self) {
    self.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self applyRegions:regions
           gridColumns:gridColumns
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
         gridColumns:(NSInteger)gridColumns
               speed:(double)speed
       reseedSeconds:(NSTimeInterval)reseedSeconds
          showAgents:(BOOL)showAgents
             palette:(NSInteger)palette {
  _regions = std::clamp<NSInteger>(regions, 2, 30);
  _gridColumns = std::clamp<NSInteger>(gridColumns, 16, 140);
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
  const double cellSize = width / _gridColumns;
  _currentRows = std::max<NSInteger>(2, std::ceil(height / cellSize));

  Configuration configuration;
  configuration.columns = static_cast<int>(_gridColumns);
  configuration.rows = static_cast<int>(_currentRows);
  configuration.regionCount = static_cast<int>(_regions);
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
  const CGFloat cellSize = size.width / _gridColumns;
  const NSInteger desiredRows = std::max<NSInteger>(2, std::ceil(size.height / cellSize));
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

  const CGFloat cellSize = self.bounds.size.width / _simulation->columns();
  const CGFloat gridHeight = cellSize * _simulation->rows();
  const CGFloat originY = (self.bounds.size.height - gridHeight) / 2.0;
  CGContextSetShouldAntialias(context, false);

  for (int row = 0; row < _simulation->rows(); ++row) {
    for (int column = 0; column < _simulation->columns(); ++column) {
      const region_bounce::Cell &cell = _simulation->cell(column, row);
      const Color base = _simulation->colorForOwner(cell.owner);
      CGContextSetRGBFillColor(context, base.red, base.green, base.blue, 1.0);
      const CGRect cellRect =
          CGRectMake(column * cellSize, originY + row * cellSize, cellSize + 0.5, cellSize + 0.5);
      CGContextFillRect(context, cellRect);
    }
  }

  if (!_showAgents) {
    return;
  }

  CGContextSetShouldAntialias(context, true);
  const CGFloat radius = std::max<CGFloat>(2.0, cellSize * 0.28);
  for (const region_bounce::Agent &agent : _simulation->agents()) {
    const CGPoint center = CGPointMake(agent.x * cellSize, originY + agent.y * cellSize);
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
