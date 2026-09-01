#pragma once

#include <cstdint>
#include <random>
#include <vector>

namespace region_bounce {

struct Color {
  double red;
  double green;
  double blue;
};

struct Cell {
  int owner = -1;
};

struct Agent {
  double x = 0.0;
  double y = 0.0;
  double velocityX = 0.0;
  double velocityY = 0.0;
  int owner = 0;
  double flash = 0.0;
};

struct Configuration {
  int columns = 20;
  int rows = 14;
  int mapColorCount = 12;
  double speed = 7.0;
  int palette = 0;
};

struct Statistics {
  std::uint64_t collisions = 0;
  std::uint64_t conversions = 0;
};

class Simulation {
public:
  explicit Simulation(Configuration configuration, std::uint64_t seed = 0);

  void reset(std::uint64_t seed = 0);
  void advance(double elapsedSeconds);
  bool applyImpact(int column, int row, int attacker);

  [[nodiscard]] int columns() const { return configuration_.columns; }
  [[nodiscard]] int rows() const { return configuration_.rows; }
  [[nodiscard]] int mapColorCount() const { return configuration_.mapColorCount; }
  [[nodiscard]] std::uint64_t seed() const { return seed_; }
  [[nodiscard]] const Cell &cell(int column, int row) const;
  [[nodiscard]] const std::vector<Cell> &cells() const { return cells_; }
  [[nodiscard]] const std::vector<Agent> &agents() const { return agents_; }
  [[nodiscard]] Color colorForOwner(int owner) const;
  [[nodiscard]] const Statistics &statistics() const { return statistics_; }

private:
  [[nodiscard]] int indexFor(int column, int row) const;
  [[nodiscard]] bool isInside(int column, int row) const;
  [[nodiscard]] Cell *cellAtPoint(double x, double y);
  void initializeMap();
  void initializeAgents();
  void advanceSubstep(double elapsedSeconds);
  void collide(Agent &agent, Cell &cell);
  [[nodiscard]] double randomUnit();

  Configuration configuration_;
  std::uint64_t seed_ = 0;
  std::mt19937_64 random_;
  std::vector<Cell> cells_;
  std::vector<Agent> agents_;
  Statistics statistics_;
};

} // namespace region_bounce
