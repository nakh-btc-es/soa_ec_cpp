# Unit Testing Setup for oMessage_Model

This directory contains unit tests for the `oMessage_Model` class generated from Simulink.

## Dependencies

The tests require the following libraries:
- **Google Test (GTest)**: Unit testing framework
- **Google Mock (GMock)**: Mocking framework for C++

### Installing Dependencies

#### Windows (vcpkg)
```powershell
vcpkg install gtest:x64-windows
vcpkg install gmock:x64-windows
```

#### Ubuntu/Debian
```bash
sudo apt-get install libgtest-dev libgmock-dev
```

#### Using Conan
```bash
conan install gtest/1.12.1@
```

## Building and Running Tests

### Using CMake
```bash
mkdir build
cd build
cmake ..
make
./oMessage_Model_Tests
```

### Using Visual Studio
1. Open the project in Visual Studio
2. Ensure vcpkg integration is enabled
3. Build the solution
4. Run tests through Test Explorer

## Test Structure

### Test Fixture: `oMessageModelTest`
- Sets up mock objects for `RecvData_InputDataInterfaceT` and `SendData_OutputDataInterfaceT`
- Provides helper methods for input/output setup and verification
- Manages object lifecycle for each test

### Test Categories

#### 1. **Basic Functionality Tests**
- Constructor initialization
- Initialize/terminate methods
- Error status management

#### 2. **Business Logic Tests**
- **Addition Logic**: When `DataA > 5.0`, result = `DataA + DataB`
- **Multiplication Logic**: When `DataA ≤ 5.0`, result = `DataA * DataB`

#### 3. **Edge Case Tests**
- Zero values
- Negative values
- Large positive values
- Boundary values (just above/below 5.0)

#### 4. **Integration Tests**
- Multiple consecutive step calls
- Receive failure scenarios
- Performance timing tests

## Test Cases Overview

| Test Case | Input DataA | Input DataB | Expected Operation | Expected Result |
|-----------|-------------|-------------|-------------------|-----------------|
| Addition (DataA > 5) | 10.0 | 3.5 | DataA + DataB | 13.5 |
| Multiplication (DataA = 5) | 5.0 | 4.0 | DataA * DataB | 20.0 |
| Multiplication (DataA < 5) | 2.5 | 6.0 | DataA * DataB | 15.0 |
| Zero values | 0.0 | 0.0 | DataA * DataB | 0.0 |
| Negative values | -3.0 | 2.0 | DataA * DataB | -6.0 |
| Boundary (just above 5) | 5.0001 | 3.0 | DataA + DataB | 8.0001 |
| Boundary (just below 5) | 4.9999 | 3.0 | DataA * DataB | 14.9997 |

## Mock Objects

### MockRecvDataInterface
- Mocks the `RecvData()` method
- Allows setting up input data for tests
- Can simulate receive failures

### MockSendDataInterface  
- Mocks the `SendData()` method
- Verifies output data correctness
- Can simulate send failures

## Helper Methods

### `SetupInputData(dataA, dataB, status)`
Configures the mock receive interface to return specified input data.

### `ExpectOutputData(expectedDataC, expectedStatus)`
Sets up expectations for the mock send interface to verify output data.

## Running Specific Tests

### Run all tests
```bash
./oMessage_Model_Tests
```

### Run specific test suite
```bash
./oMessage_Model_Tests --gtest_filter="oMessageModelTest.*"
```

### Run specific test case
```bash
./oMessage_Model_Tests --gtest_filter="oMessageModelTest.StepWithDataAGreaterThan5_PerformsAddition"
```

### Verbose output
```bash
./oMessage_Model_Tests --gtest_verbose
```

## Test Coverage

The test suite covers:
- ✅ All public methods
- ✅ Both business logic branches (addition/multiplication)
- ✅ Edge cases and boundary conditions
- ✅ Error handling scenarios
- ✅ Performance characteristics
- ✅ Integration with mock interfaces

## Continuous Integration

For CI/CD pipelines, use:
```bash
ctest --output-on-failure
```

## Adding New Tests

1. Add new test methods to the `oMessageModelTest` class
2. Use the existing helper methods for setup
3. Follow the naming convention: `MethodUnderTest_Scenario_ExpectedBehavior`
4. Include both positive and negative test cases
5. Update this documentation

## Troubleshooting

### Common Issues:

1. **Linker errors**: Ensure Google Test/Mock libraries are properly installed
2. **Mock setup failures**: Check that expectations are set before calling the method under test
3. **Floating-point comparison**: Use `EXPECT_DOUBLE_EQ` for exact comparisons or `EXPECT_NEAR` for approximate comparisons

### Debug Tips:
- Use `ASSERT_*` macros to stop on first failure
- Use `EXPECT_*` macros to continue after failures
- Add debug prints in test methods if needed
- Use GDB or Visual Studio debugger to step through tests