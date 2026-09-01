#include "RegionSimulation.hpp"

#include <algorithm>
#include <array>
#include <chrono>
#include <cmath>
#include <limits>
#include <numeric>
#include <stdexcept>

namespace region_bounce {
namespace {

constexpr double kAgentRadius = 0.28;
constexpr double kMaximumSubstep = 1.0 / 120.0;
constexpr double kPi = 3.14159265358979323846;

using Palette = std::array<Color, 12>;

constexpr std::array<Palette, 4> kPalettes = {{
    {{{0.55, 0.45, 0.40},
      {0.42, 0.56, 0.42},
      {0.43, 0.50, 0.62},
      {0.82, 0.90, 0.81},
      {0.82, 0.69, 0.65},
      {0.44, 0.69, 0.40},
      {0.39, 0.53, 0.68},
      {0.71, 0.43, 0.36},
      {0.77, 0.82, 0.87},
      {0.42, 0.35, 0.33},
      {0.60, 0.76, 0.55},
      {0.54, 0.67, 0.59}}},
    {{{0.91, 0.55, 0.48},
      {0.98, 0.74, 0.48},
      {0.98, 0.87, 0.57},
      {0.56, 0.78, 0.67},
      {0.42, 0.68, 0.72},
      {0.47, 0.55, 0.74},
      {0.68, 0.53, 0.75},
      {0.86, 0.61, 0.72},
      {0.98, 0.78, 0.72},
      {0.73, 0.83, 0.65},
      {0.55, 0.75, 0.84},
      {0.82, 0.72, 0.88}}},
    {{{0.06, 0.20, 0.27},
      {0.08, 0.31, 0.38},
      {0.10, 0.43, 0.48},
      {0.17, 0.55, 0.57},
      {0.32, 0.66, 0.63},
      {0.52, 0.76, 0.69},
      {0.72, 0.85, 0.78},
      {0.21, 0.39, 0.53},
      {0.30, 0.50, 0.64},
      {0.43, 0.61, 0.72},
      {0.58, 0.73, 0.80},
      {0.76, 0.84, 0.86}}},
    {{{0.08, 0.09, 0.10},
      {0.16, 0.17, 0.18},
      {0.24, 0.25, 0.26},
      {0.32, 0.33, 0.34},
      {0.40, 0.41, 0.42},
      {0.48, 0.49, 0.50},
      {0.56, 0.57, 0.58},
      {0.64, 0.65, 0.66},
      {0.72, 0.73, 0.74},
      {0.80, 0.81, 0.82},
      {0.88, 0.89, 0.90},
      {0.95, 0.95, 0.94}}},
}};

std::uint64_t makeSeed() {
  const auto now = std::chrono::high_resolution_clock::now().time_since_epoch().count();
  std::random_device device;
  return static_cast<std::uint64_t>(now) ^ (static_cast<std::uint64_t>(device()) << 32U) ^ device();
}

} // namespace

Simulation::Simulation(Configuration configuration, std::uint64_t seed)
    : configuration_(configuration) {
  if (configuration_.columns < 2 || configuration_.rows < 2) {
    throw std::invalid_argument("The grid must be at least 2 by 2");
  }
  const int cellCount = configuration_.columns * configuration_.rows;
  configuration_.regionCount = std::clamp(configuration_.regionCount, 1, cellCount);
  configuration_.speed = std::clamp(configuration_.speed, 0.2, 80.0);
  configuration_.palette =
      std::clamp(configuration_.palette, 0, static_cast<int>(kPalettes.size()) - 1);
  reset(seed);
}

void Simulation::reset(std::uint64_t seed) {
  seed_ = seed == 0 ? makeSeed() : seed;
  random_.seed(seed_);
  statistics_ = {};
  initializeRegions();
  initializeAgents();
}

int Simulation::indexFor(int column, int row) const {
  return row * configuration_.columns + column;
}

bool Simulation::isInside(int column, int row) const {
  return column >= 0 && row >= 0 && column < configuration_.columns && row < configuration_.rows;
}

const Cell &Simulation::cell(int column, int row) const {
  if (!isInside(column, row)) {
    throw std::out_of_range("Cell coordinates are outside the grid");
  }
  return cells_[static_cast<std::size_t>(indexFor(column, row))];
}

Cell *Simulation::cellAtPoint(double x, double y) {
  const int column = static_cast<int>(std::floor(x));
  const int row = static_cast<int>(std::floor(y));
  if (!isInside(column, row)) {
    return nullptr;
  }
  return &cells_[static_cast<std::size_t>(indexFor(column, row))];
}

double Simulation::randomUnit() {
  return std::generate_canonical<double, std::numeric_limits<double>::digits>(random_);
}

void Simulation::initializeRegions() {
  const int cellCount = configuration_.columns * configuration_.rows;
  cells_.assign(static_cast<std::size_t>(cellCount), Cell{});

  std::vector<int> locations(static_cast<std::size_t>(cellCount));
  std::iota(locations.begin(), locations.end(), 0);
  std::shuffle(locations.begin(), locations.end(), random_);

  std::vector<int> frontier;
  frontier.reserve(static_cast<std::size_t>(cellCount));
  for (int region = 0; region < configuration_.regionCount; ++region) {
    const int index = locations[static_cast<std::size_t>(region)];
    cells_[static_cast<std::size_t>(index)].owner = region;
    frontier.push_back(index);
  }

  int assigned = configuration_.regionCount;
  constexpr std::array<std::pair<int, int>, 4> directions = {std::pair{-1, 0}, std::pair{1, 0},
                                                             std::pair{0, -1}, std::pair{0, 1}};

  while (assigned < cellCount && !frontier.empty()) {
    const std::size_t frontierOffset = static_cast<std::size_t>(randomUnit() * frontier.size());
    const std::size_t safeOffset = std::min(frontierOffset, frontier.size() - 1);
    const int sourceIndex = frontier[safeOffset];
    const int sourceColumn = sourceIndex % configuration_.columns;
    const int sourceRow = sourceIndex / configuration_.columns;

    std::array<int, 4> order = {0, 1, 2, 3};
    std::shuffle(order.begin(), order.end(), random_);
    bool expanded = false;
    for (const int directionIndex : order) {
      const auto [deltaColumn, deltaRow] = directions[static_cast<std::size_t>(directionIndex)];
      const int column = sourceColumn + deltaColumn;
      const int row = sourceRow + deltaRow;
      if (!isInside(column, row)) {
        continue;
      }
      Cell &destination = cells_[static_cast<std::size_t>(indexFor(column, row))];
      if (destination.owner != -1) {
        continue;
      }
      destination.owner = cells_[static_cast<std::size_t>(sourceIndex)].owner;
      frontier.push_back(indexFor(column, row));
      ++assigned;
      expanded = true;
      break;
    }

    if (!expanded) {
      frontier[safeOffset] = frontier.back();
      frontier.pop_back();
    }
  }
}

void Simulation::initializeAgents() {
  agents_.clear();
  agents_.reserve(static_cast<std::size_t>(configuration_.regionCount));

  std::vector<std::vector<int>> cellsByRegion(static_cast<std::size_t>(configuration_.regionCount));
  for (int index = 0; index < static_cast<int>(cells_.size()); ++index) {
    const int owner = cells_[static_cast<std::size_t>(index)].owner;
    cellsByRegion[static_cast<std::size_t>(owner)].push_back(index);
  }

  for (int region = 0; region < configuration_.regionCount; ++region) {
    const std::vector<int> &regionCells = cellsByRegion[static_cast<std::size_t>(region)];
    const std::size_t offset = std::min(static_cast<std::size_t>(randomUnit() * regionCells.size()),
                                        regionCells.size() - 1);
    const int cellIndex = regionCells[offset];
    const int column = cellIndex % configuration_.columns;
    const int row = cellIndex / configuration_.columns;
    double angle = randomUnit() * 2.0 * kPi;
    while (std::abs(std::cos(angle)) < 0.32 || std::abs(std::sin(angle)) < 0.32) {
      angle = randomUnit() * 2.0 * kPi;
    }

    Agent agent;
    agent.x = std::clamp(column + 0.28 + randomUnit() * 0.44, kAgentRadius,
                         configuration_.columns - kAgentRadius);
    agent.y = std::clamp(row + 0.28 + randomUnit() * 0.44, kAgentRadius,
                         configuration_.rows - kAgentRadius);
    agent.velocityX = std::cos(angle) * configuration_.speed;
    agent.velocityY = std::sin(angle) * configuration_.speed;
    agent.owner = region;
    agents_.push_back(agent);
  }
}

bool Simulation::applyImpact(int column, int row, int attacker) {
  if (!isInside(column, row) || attacker < 0 || attacker >= configuration_.regionCount) {
    return false;
  }

  Cell &target = cells_[static_cast<std::size_t>(indexFor(column, row))];
  if (target.owner == attacker) {
    return false;
  }
  target.owner = attacker;
  ++statistics_.conversions;
  return true;
}

void Simulation::collide(Agent &agent, Cell &cell) {
  ++statistics_.collisions;
  agent.flash = 1.0;
  const int index = static_cast<int>(&cell - cells_.data());
  const int column = index % configuration_.columns;
  const int row = index / configuration_.columns;
  applyImpact(column, row, agent.owner);
}

void Simulation::advance(double elapsedSeconds) {
  double remaining = std::clamp(elapsedSeconds, 0.0, 0.1);
  while (remaining > 0.0) {
    const double substep = std::min(remaining, kMaximumSubstep);
    advanceSubstep(substep);
    remaining -= substep;
  }
}

void Simulation::advanceSubstep(double elapsedSeconds) {
  for (Agent &agent : agents_) {
    agent.flash = std::max(0.0, agent.flash - elapsedSeconds * 3.5);

    double nextX = agent.x + agent.velocityX * elapsedSeconds;
    if (nextX - kAgentRadius < 0.0 || nextX + kAgentRadius >= configuration_.columns) {
      agent.velocityX = -agent.velocityX;
      nextX = std::clamp(nextX, kAgentRadius, configuration_.columns - kAgentRadius - 0.001);
      ++statistics_.collisions;
      agent.flash = 1.0;
    } else {
      const double probeX = nextX + std::copysign(kAgentRadius, agent.velocityX);
      Cell *target = cellAtPoint(probeX, agent.y);
      if (target != nullptr && target->owner != agent.owner) {
        collide(agent, *target);
        agent.velocityX = -agent.velocityX;
        nextX = agent.x;
      }
    }
    agent.x = nextX;

    double nextY = agent.y + agent.velocityY * elapsedSeconds;
    if (nextY - kAgentRadius < 0.0 || nextY + kAgentRadius >= configuration_.rows) {
      agent.velocityY = -agent.velocityY;
      nextY = std::clamp(nextY, kAgentRadius, configuration_.rows - kAgentRadius - 0.001);
      ++statistics_.collisions;
      agent.flash = 1.0;
    } else {
      const double probeY = nextY + std::copysign(kAgentRadius, agent.velocityY);
      Cell *target = cellAtPoint(agent.x, probeY);
      if (target != nullptr && target->owner != agent.owner) {
        collide(agent, *target);
        agent.velocityY = -agent.velocityY;
        nextY = agent.y;
      }
    }
    agent.y = nextY;
  }
}

Color Simulation::colorForOwner(int owner) const {
  const Palette &palette = kPalettes[static_cast<std::size_t>(configuration_.palette)];
  const int safeOwner = owner < 0 ? 0 : owner;
  Color color = palette[static_cast<std::size_t>(safeOwner) % palette.size()];
  const int variation = safeOwner / static_cast<int>(palette.size());
  if (variation == 1) {
    constexpr double kLighten = 0.16;
    color.red += (1.0 - color.red) * kLighten;
    color.green += (1.0 - color.green) * kLighten;
    color.blue += (1.0 - color.blue) * kLighten;
  } else if (variation >= 2) {
    constexpr double kDarken = 0.78;
    color.red *= kDarken;
    color.green *= kDarken;
    color.blue *= kDarken;
  }
  return color;
}

} // namespace region_bounce
