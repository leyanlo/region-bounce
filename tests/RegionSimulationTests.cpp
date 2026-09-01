#include "RegionSimulation.hpp"

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <string>
#include <vector>

namespace {

int failures = 0;

void expect(bool condition, const std::string &message) {
  if (!condition) {
    std::cerr << "FAIL: " << message << '\n';
    ++failures;
  }
}

region_bounce::Configuration baseConfiguration() {
  region_bounce::Configuration configuration;
  configuration.columns = 36;
  configuration.rows = 24;
  configuration.mapColorCount = 12;
  configuration.speed = 8.0;
  return configuration;
}

void testDeterministicWorlds() {
  region_bounce::Simulation first(baseConfiguration(), 123456);
  region_bounce::Simulation second(baseConfiguration(), 123456);
  expect(first.cells().size() == second.cells().size(), "matching seeds have matching grid sizes");
  for (std::size_t index = 0; index < first.cells().size(); ++index) {
    expect(first.cells()[index].owner == second.cells()[index].owner,
           "matching seeds generate the same territories");
  }
  expect(first.agents().size() == second.agents().size(),
         "matching seeds have matching agent counts");
  for (std::size_t index = 0; index < first.agents().size(); ++index) {
    const auto &left = first.agents()[index];
    const auto &right = second.agents()[index];
    expect(left.owner == right.owner && left.x == right.x && left.y == right.y,
           "matching seeds generate the same agents");
  }
}

void testStartingMapIsRandomized() {
  region_bounce::Simulation simulation(baseConfiguration(), 7890);
  std::vector<int> population(static_cast<std::size_t>(simulation.mapColorCount()), 0);
  for (const auto &cell : simulation.cells()) {
    expect(cell.owner >= 0 && cell.owner < simulation.mapColorCount(),
           "every cell has a valid owner");
    ++population[static_cast<std::size_t>(cell.owner)];
  }
  for (const int count : population) {
    expect(count > 0, "every requested starting color appears on the map");
  }

  int horizontalTransitions = 0;
  for (int row = 0; row < simulation.rows(); ++row) {
    for (int column = 1; column < simulation.columns(); ++column) {
      horizontalTransitions +=
          simulation.cell(column - 1, row).owner != simulation.cell(column, row).owner;
    }
  }
  expect(horizontalTransitions > simulation.columns() * simulation.rows() / 2,
         "the starting map is randomized cell by cell");
}

void testExactlyThreeDistinctBalls() {
  region_bounce::Simulation simulation(baseConfiguration(), 24680);
  expect(simulation.agents().size() == 3, "the simulation creates exactly three balls");
  std::vector<int> ballsByColor(static_cast<std::size_t>(simulation.mapColorCount()), 0);
  for (const auto &agent : simulation.agents()) {
    ++ballsByColor[static_cast<std::size_t>(agent.owner)];
    const int column = static_cast<int>(std::floor(agent.x));
    const int row = static_cast<int>(std::floor(agent.y));
    expect(simulation.cell(column, row).owner == agent.owner,
           "each ball starts on a pixel of its own color");
  }
  int activeColors = 0;
  for (const int count : ballsByColor) {
    expect(count <= 1, "the three balls carry distinct colors");
    activeColors += count > 0;
  }
  expect(activeColors == 3, "exactly three starting colors are active");
}

void testFirstImpactConvertsBoundaryCell() {
  region_bounce::Simulation simulation(baseConfiguration(), 42);
  const int original = simulation.cell(0, 0).owner;
  const int attacker = (original + 1) % simulation.mapColorCount();
  expect(simulation.applyImpact(0, 0, attacker), "the first impact converts a foreign cell");
  expect(simulation.cell(0, 0).owner == attacker, "conversion changes ownership");
  expect(simulation.statistics().conversions == 1, "conversion is counted once");
}

void testThreeBallColorsTakeOverTheMap() {
  auto configuration = baseConfiguration();
  configuration.columns = 20;
  configuration.rows = 14;
  for (const std::uint64_t seed : {1ULL, 7ULL, 42ULL, 13579ULL, 98765ULL}) {
    region_bounce::Simulation simulation(configuration, seed);
    std::vector<bool> activeColors(static_cast<std::size_t>(simulation.mapColorCount()), false);
    for (const auto &agent : simulation.agents()) {
      activeColors[static_cast<std::size_t>(agent.owner)] = true;
    }

    bool takeoverComplete = false;
    for (int frame = 0; frame < 240000 && !takeoverComplete; ++frame) {
      simulation.advance(1.0 / 120.0);
      if (frame % 120 != 0) {
        continue;
      }
      takeoverComplete = true;
      for (const auto &cell : simulation.cells()) {
        if (!activeColors[static_cast<std::size_t>(cell.owner)]) {
          takeoverComplete = false;
          break;
        }
      }
    }
    expect(takeoverComplete, "the three ball colors take over for seed " + std::to_string(seed));
  }
}

void testAgentsStayInsideTheGrid() {
  region_bounce::Simulation simulation(baseConfiguration(), 98765);
  for (int frame = 0; frame < 2400; ++frame) {
    simulation.advance(1.0 / 120.0);
  }
  for (const auto &agent : simulation.agents()) {
    expect(std::isfinite(agent.x) && std::isfinite(agent.y), "agent coordinates remain finite");
    expect(agent.x >= 0.0 && agent.x < simulation.columns(),
           "agent remains within horizontal bounds");
    expect(agent.y >= 0.0 && agent.y < simulation.rows(), "agent remains within vertical bounds");
    expect(agent.owner >= 0 && agent.owner < simulation.mapColorCount(),
           "agent keeps a valid owner");
  }
  expect(simulation.statistics().collisions > 0, "the simulation produces collisions");
  expect(simulation.statistics().conversions > 0, "the simulation evolves territory ownership");
}

} // namespace

int main() {
  testDeterministicWorlds();
  testStartingMapIsRandomized();
  testExactlyThreeDistinctBalls();
  testFirstImpactConvertsBoundaryCell();
  testThreeBallColorsTakeOverTheMap();
  testAgentsStayInsideTheGrid();
  if (failures == 0) {
    std::cout << "All RegionSimulation tests passed\n";
    return EXIT_SUCCESS;
  }
  std::cerr << failures << " assertion(s) failed\n";
  return EXIT_FAILURE;
}
