cmake_minimum_required(VERSION 3.16)
project(oMessage_Model_Tests)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(GTest REQUIRED)
find_package(GMock REQUIRED)

# Include directories
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_CURRENT_SOURCE_DIR}/..
    ${GTEST_INCLUDE_DIRS}
    ${GMOCK_INCLUDE_DIRS}
)

# Add the source files from the main project
set(MAIN_SOURCES
    ../oMessage_Model_ert_rtw/oMessage_Model.cpp
    # Add other source files as needed
)

# Create test executable
add_executable(oMessage_Model_Tests
    test_oMessage_Model.cpp
    ${MAIN_SOURCES}
)

# Link libraries
target_link_libraries(oMessage_Model_Tests
    ${GTEST_LIBRARIES}
    ${GMOCK_LIBRARIES}
    pthread  # Required for Google Test on Linux
)

# Compiler-specific flags
if(MSVC)
    target_compile_options(oMessage_Model_Tests PRIVATE /W4)
else()
    target_compile_options(oMessage_Model_Tests PRIVATE -Wall -Wextra -Wpedantic)
endif()

# Add test discovery
include(GoogleTest)
gtest_discover_tests(oMessage_Model_Tests)

# Custom target to run tests
add_custom_target(run_tests
    COMMAND oMessage_Model_Tests
    DEPENDS oMessage_Model_Tests
    COMMENT "Running unit tests"
)