cmake_minimum_required(VERSION 3.21)

project(RegionBounce VERSION 1.0.0 LANGUAGES CXX OBJCXX)

if(NOT APPLE)
  message(FATAL_ERROR "RegionBounce builds only on macOS")
endif()

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
if(NOT CMAKE_OSX_DEPLOYMENT_TARGET)
  set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum macOS version" FORCE)
endif()

option(REGION_BOUNCE_UNIVERSAL "Build arm64 and x86_64 binaries" ON)
if(REGION_BOUNCE_UNIVERSAL AND NOT CMAKE_OSX_ARCHITECTURES)
  set(CMAKE_OSX_ARCHITECTURES "arm64;x86_64" CACHE STRING "macOS architectures" FORCE)
endif()

find_library(COCOA_FRAMEWORK Cocoa REQUIRED)
find_library(SCREENSAVER_FRAMEWORK ScreenSaver REQUIRED)

add_library(region_bounce_simulation STATIC
  src/simulation/RegionSimulation.cpp
)
target_include_directories(region_bounce_simulation PUBLIC src/simulation)
target_compile_options(region_bounce_simulation PRIVATE -Wall -Wextra -Wpedantic)

add_library(region_bounce_canvas STATIC
  src/macos/RegionBounceCanvasView.mm
)
target_include_directories(region_bounce_canvas PUBLIC src/macos)
target_compile_options(region_bounce_canvas PRIVATE -fobjc-arc -Wall -Wextra)
target_link_libraries(region_bounce_canvas PUBLIC region_bounce_simulation ${COCOA_FRAMEWORK})

add_library(RegionBounceSaver MODULE
  src/macos/RegionBounceSaverView.mm
)
target_compile_options(RegionBounceSaver PRIVATE -fobjc-arc -Wall -Wextra)
target_link_libraries(RegionBounceSaver PRIVATE region_bounce_canvas ${SCREENSAVER_FRAMEWORK} ${COCOA_FRAMEWORK})
set_target_properties(RegionBounceSaver PROPERTIES
  BUNDLE TRUE
  BUNDLE_EXTENSION saver
  PREFIX ""
  OUTPUT_NAME "RegionBounce"
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/macos/ScreenSaver-Info.plist.in"
)

add_executable(RegionBounceApp MACOSX_BUNDLE
  src/macos/main.mm
  src/macos/RegionBounceAppDelegate.mm
)
target_compile_options(RegionBounceApp PRIVATE -fobjc-arc -Wall -Wextra)
target_link_libraries(RegionBounceApp PRIVATE region_bounce_canvas ${COCOA_FRAMEWORK})
set_target_properties(RegionBounceApp PROPERTIES
  OUTPUT_NAME "RegionBounce"
  MACOSX_BUNDLE_BUNDLE_NAME "RegionBounce"
  MACOSX_BUNDLE_GUI_IDENTIFIER "com.leyanlo.RegionBounce"
  MACOSX_BUNDLE_SHORT_VERSION_STRING "${PROJECT_VERSION}"
  MACOSX_BUNDLE_BUNDLE_VERSION "1"
  MACOSX_BUNDLE_INFO_PLIST "${CMAKE_CURRENT_SOURCE_DIR}/macos/App-Info.plist.in"
)

enable_testing()

add_executable(RegionSimulationTests tests/RegionSimulationTests.cpp)
target_compile_options(RegionSimulationTests PRIVATE -Wall -Wextra -Wpedantic)
target_link_libraries(RegionSimulationTests PRIVATE region_bounce_simulation)
add_test(NAME RegionSimulationTests COMMAND RegionSimulationTests)

add_executable(SaverBundleSmoke tests/SaverBundleSmoke.mm)
target_compile_options(SaverBundleSmoke PRIVATE -fobjc-arc -Wall -Wextra)
target_link_libraries(SaverBundleSmoke PRIVATE ${SCREENSAVER_FRAMEWORK} ${COCOA_FRAMEWORK})
add_test(
  NAME SaverBundleSmoke
  COMMAND SaverBundleSmoke "$<TARGET_BUNDLE_DIR:RegionBounceSaver>"
)
