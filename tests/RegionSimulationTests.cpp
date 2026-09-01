#include "RegionSimulation.hpp"

#include <cmath>
#include <cstdlib>
#include <iostream>
#include <queue>
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
  configuration.regionCount = 12;
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

void testStartingRegionsAreConnected() {
  region_bounce::Simulation simulation(baseConfiguration(), 7890);
  const int columns = simulation.columns();
  const int rows = simulation.rows();
  std::vector<int> population(static_cast<std::size_t>(simulation.regionCount()), 0);
  for (const auto &cell : simulation.cells()) {
    expect(cell.owner >= 0 && cell.owner < simulation.regionCount(),
           "every cell has a valid owner");
    ++population[static_cast<std::size_t>(cell.owner)];
  }

  for (int owner = 0; owner < simulation.regionCount(); ++owner) {
    expect(population[static_cast<std::size_t>(owner)] > 0, "every requested region exists");
    std::vector<bool> visited(static_cast<std::size_t>(columns * rows), false);
    std::queue<std::pair<int, int>> pending;
    bool found = false;
    for (int row = 0; row < rows && !found; ++row) {
      for (int column = 0; column < columns; ++column) {
        if (simulation.cell(column, row).owner == owner) {
          pending.push({column, row});
          visited[static_cast<std::size_t>(row * columns + column)] = true;
          found = true;
          break;
        }
      }
    }

    int reached = 0;
    while (!pending.empty()) {
      const auto [column, row] = pending.front();
      pending.pop();
      ++reached;
      constexpr int delta[4][2] = {{-1, 0}, {1, 0}, {0, -1}, {0, 1}};
      for (const auto &direction : delta) {
        const int nextColumn = column + direction[0];
        const int nextRow = row + direction[1];
        if (nextColumn < 0 || nextRow < 0 || nextColumn >= columns || nextRow >= rows) {
          continue;
        }
        const std::size_t index = static_cast<std::size_t>(nextRow * columns + nextColumn);
        if (!visited[index] && simulation.cell(nextColumn, nextRow).owner == owner) {
          visited[index] = true;
          pending.push({nextColumn, nextRow});
        }
      }
    }
    expect(reached == population[static_cast<std::size_t>(owner)],
           "each starting territory is one connected region");
  }
}

void testEachRegionStartsWithOneAgent() {
  region_bounce::Simulation simulation(baseConfiguration(), 24680);
  expect(simulation.agents().size() == static_cast<std::size_t>(simulation.regionCount()),
         "the simulation creates exactly one agent per region");
  std::vector<int> agentsByRegion(static_cast<std::size_t>(simulation.regionCount()), 0);
  for (const auto &agent : simulation.agents()) {
    ++agentsByRegion[static_cast<std::size_t>(agent.owner)];
    const int column = static_cast<int>(std::floor(agent.x));
    const int row = static_cast<int>(std::floor(agent.y));
    expect(simulation.cell(column, row).owner == agent.owner,
           "each agent starts inside its own region");
  }
  for (const int count : agentsByRegion) {
    expect(count == 1, "each region starts with exactly one agent");
  }
}

void testFirstImpactConvertsBoundaryCell() {
  region_bounce::Simulation simulation(baseConfiguration(), 42);
  const int original = simulation.cell(0, 0).owner;
  const int attacker = (original + 1) % simulation.regionCount();
  expect(simulation.applyImpact(0, 0, attacker), "the first impact converts a foreign cell");
  expect(simulation.cell(0, 0).owner == attacker, "conversion changes ownership");
  expect(simulation.statistics().conversions == 1, "conversion is counted once");
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
    expect(agent.owner >= 0 && agent.owner < simulation.regionCount(), "agent keeps a valid owner");
  }
  expect(simulation.statistics().collisions > 0, "the simulation produces collisions");
  expect(simulation.statistics().conversions > 0, "the simulation evolves territory ownership");
}

} // namespace

int main() {
  testDeterministicWorlds();
  testStartingRegionsAreConnected();
  testEachRegionStartsWithOneAgent();
  testFirstImpactConvertsBoundaryCell();
  testAgentsStayInsideTheGrid();
  if (failures == 0) {
    std::cout << "All RegionSimulation tests passed\n";
    return EXIT_SUCCESS;
  }
  std::cerr << failures << " assertion(s) failed\n";
  return EXIT_FAILURE;
}
