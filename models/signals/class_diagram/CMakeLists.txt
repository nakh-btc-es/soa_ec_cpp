# CMakeLists.txt for signal_dvPrivate_acMethod model test wrapper
#
# This builds the Simulink-generated model with the test wrapper
# and example application.

cmake_minimum_required(VERSION 3.15)

project(signal_model_test 
    VERSION 1.20
    DESCRIPTION "Test wrapper for signal_dvPrivate_acMethod Simulink model"
    LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Compiler-specific options
if(MSVC)
    add_compile_options(/W4)
    add_definitions(-D_CRT_SECURE_NO_WARNINGS)
else()
    add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Build configuration
if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

message(STATUS "Build type: ${CMAKE_BUILD_TYPE}")

# Include directories
set(SIMULINK_MODEL_DIR "../signal_dvPrivate_acMethod_ert_rtw")

include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}
    ${SIMULINK_MODEL_DIR}
)

# Source files
set(MODEL_SOURCES
    ${SIMULINK_MODEL_DIR}/signal_dvPrivate_acMethod.cpp
    ${SIMULINK_MODEL_DIR}/signal_dvPrivate_acMethod_data.cpp
)

set(WRAPPER_SOURCES
    model_test_wrapper.cpp
)

set(EXAMPLE_SOURCES
    test_example.cpp
)

# Check if Simulink model files exist
foreach(src_file ${MODEL_SOURCES})
    if(NOT EXISTS ${src_file})
        message(FATAL_ERROR "Simulink model source file not found: ${src_file}")
    endif()
endforeach()

# Create model library
add_library(signal_model STATIC ${MODEL_SOURCES})
target_include_directories(signal_model PUBLIC ${SIMULINK_MODEL_DIR})

# Create test wrapper library
add_library(model_wrapper STATIC ${WRAPPER_SOURCES})
target_link_libraries(model_wrapper PUBLIC signal_model)
target_include_directories(model_wrapper PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

# Create test executable
add_executable(model_test ${EXAMPLE_SOURCES})
target_link_libraries(model_test PRIVATE model_wrapper signal_model)

# Create simple C test executable (for C interface testing)
add_executable(model_test_c 
    ${CMAKE_CURRENT_SOURCE_DIR}/test_c_interface.c
)
target_link_libraries(model_test_c PRIVATE model_wrapper signal_model)

# Install targets
install(TARGETS signal_model model_wrapper model_test
    LIBRARY DESTINATION lib
    ARCHIVE DESTINATION lib
    RUNTIME DESTINATION bin
)

install(FILES 
    model_test_wrapper.h
    ${SIMULINK_MODEL_DIR}/signal_dvPrivate_acMethod.h
    DESTINATION include
)

# Custom targets for convenience
add_custom_target(run_test
    COMMAND model_test
    DEPENDS model_test
    COMMENT "Running model test example"
    VERBATIM
)

add_custom_target(run_c_test
    COMMAND model_test_c
    DEPENDS model_test_c
    COMMENT "Running C interface test"
    VERBATIM
)

# Print build information
message(STATUS "")
message(STATUS "=== Build Configuration ===")
message(STATUS "Project: ${PROJECT_NAME} v${PROJECT_VERSION}")
message(STATUS "Description: ${PROJECT_DESCRIPTION}")
message(STATUS "C++ Standard: C++${CMAKE_CXX_STANDARD}")
message(STATUS "Build Type: ${CMAKE_BUILD_TYPE}")
message(STATUS "Simulink Model Directory: ${SIMULINK_MODEL_DIR}")
message(STATUS "")
message(STATUS "=== Build Targets ===")
message(STATUS "Libraries:")
message(STATUS "  - signal_model (Simulink generated code)")
message(STATUS "  - model_wrapper (Test wrapper)")
message(STATUS "")
message(STATUS "Executables:")
message(STATUS "  - model_test (C++ test example)")
message(STATUS "  - model_test_c (C interface test)")
message(STATUS "")
message(STATUS "=== Usage ===")
message(STATUS "Build: cmake --build . --config ${CMAKE_BUILD_TYPE}")
message(STATUS "Run C++ test: cmake --build . --target run_test")
message(STATUS "Run C test: cmake --build . --target run_c_test")
message(STATUS "")