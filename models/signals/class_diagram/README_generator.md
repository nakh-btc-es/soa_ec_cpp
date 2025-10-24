# Simulink Model Test Wrapper Generator

This Python script automatically generates C++ test wrapper code for Simulink-generated models by reading a JSON model structure file.

## 🎯 Purpose

The generator creates a complete C/C++ interface for testing Simulink models with:
- Global variable access to all model inputs, outputs, parameters, and states
- Comprehensive test scenarios and examples
- Both C++ and C interfaces for maximum compatibility
- Automatic code generation from JSON model descriptions

## 📁 Generated Files

### 1. `model_test_wrapper.h`
- **Global variable declarations** for all model signals
- **Function prototypes** for model lifecycle and testing
- **Custom type definitions** (bus structures, etc.)
- **Usage examples** and documentation
- **C interface** declarations for external integration

### 2. `test_example.cpp`
- **Complete test suite** with multiple scenarios
- **Basic usage examples** showing input/output operations
- **Parameter modification** testing with runtime changes
- **Continuous simulation** with time-varying inputs
- **Bus signal testing** for complex data types (if applicable)
- **Error handling** and comprehensive logging

## 🚀 Usage

### Command Line
```bash
# Basic usage
python generate_model_wrapper.py signal_model_structure.json

# With custom output directory
python generate_model_wrapper.py signal_model_structure.json ./generated_code/
```

### Python Script Usage
```python
from generate_model_wrapper import ModelWrapperGenerator

# Initialize generator
generator = ModelWrapperGenerator("signal_model_structure.json")

# Generate files
header_path = generator.generate_header_file("./output/")
test_path = generator.generate_test_example_file("./output/")

print(f"Generated: {header_path}")
print(f"Generated: {test_path}")
```

## 📋 JSON Input Format

The generator expects a JSON file with this structure:

```json
{
  "model_info": {
    "name": "signal_dvPrivate_acMethod",
    "version": "1.20",
    "namespace": "btc_soa",
    "simulink_coder_version": "24.2 (R2024b)"
  },
  "inputs": {
    "signals": [
      {
        "name": "InScalar_dvPrivate_amMethod",
        "signal_info": {
          "classification": "scalar",
          "data_type": "float",
          "dimensions": "1x1"
        },
        "setter_method": "setInScalar_dvPrivate_amMethod(float)",
        "default_value": 0.0,
        "description": "Scalar input signal"
      }
    ]
  },
  "outputs": { /* Similar structure for outputs */ },
  "parameters": { /* Similar structure for parameters */ },
  "local_variables": { /* State variables structure */ },
  "custom_types": {
    "myBus": {
      "description": "Bus structure for grouped signals",
      "fields": [
        {"name": "FlptSig1", "type": "float"},
        {"name": "FlptSig2", "type": "float"}
      ]
    }
  }
}
```

## 🔧 Key Features

### Smart Type Handling
- **Automatic C type conversion** from JSON signal info
- **Array handling** with proper dimensions
- **Custom struct support** for bus signals
- **Default value generation** for all data types

### Code Generation Features
- **Template-based generation** for consistent code structure
- **Comprehensive error handling** in generated code
- **Multiple test scenarios** automatically created
- **Cross-platform compatibility** (Windows/Linux/macOS)

### Generated Test Scenarios

#### 1. Basic Usage Example
```cpp
void example_basic_usage() {
    model_initialize();
    
    // Set inputs via global variables
    g_InScalar_dvPrivate_amMethod = 1.5f;
    g_InArray_dvPrivate_amMethod[0] = 2.0f;
    
    // Execute model
    model_step();
    
    // Read outputs
    printf("Output: %f\n", g_OutScalar_dvPrivate_amMethod);
    
    model_terminate();
}
```

#### 2. Parameter Modification Example
- Runtime parameter changes
- Before/after comparison
- Verification of parameter effects

#### 3. Continuous Simulation Example
- Multi-step execution with time-varying inputs
- Sinusoidal input generation
- State evolution monitoring

#### 4. Bus Signal Testing Example (if applicable)
- Complex data structure handling
- Pass-through verification
- Bus signal integrity checking

## 📊 Generator Architecture

### Class Structure

#### `SignalInfo` (DataClass)
- Holds individual signal information
- Type, classification, dimensions, default values
- Method names for getters/setters

#### `ModelInfo` (DataClass)
- Complete model description
- Lists of inputs, outputs, parameters, states
- Custom type definitions

#### `ModelWrapperGenerator` (Main Class)
- **JSON parsing** with comprehensive error handling
- **Code template management** with flexible formatting
- **File generation** with automatic directory creation
- **Type conversion** from JSON to C/C++

#### `CodeTemplate` (Static Class)
- **Template definitions** for header and implementation files
- **Placeholder management** for dynamic content insertion
- **Formatting utilities** for consistent code style

### Generation Process

1. **JSON Parsing Phase**
   - Load and validate JSON structure
   - Extract model metadata, signals, parameters
   - Build internal data structures

2. **Code Generation Phase**
   - Generate custom type definitions
   - Create global variable declarations
   - Build function implementations
   - Generate comprehensive test examples

3. **File Output Phase**
   - Write header file with declarations
   - Write test file with examples
   - Create build instructions and documentation

## 🛠️ Customization

### Adding New Test Scenarios
```python
def _generate_custom_example(self) -> str:
    """Generate custom test scenario"""
    func_lines = [
        "void example_custom_scenario()",
        "{",
        "    // Your custom test code here",
        "}"
    ]
    return "\\n".join(func_lines)
```

### Custom Type Handling
```python
def _handle_custom_type(self, type_info: Dict) -> str:
    """Handle custom signal types"""
    # Add custom logic for specific types
    return generated_code
```

### Template Modification
```python
# Modify CodeTemplate class to add new templates
@staticmethod
def custom_template() -> str:
    return '''
    // Your custom template here
    {placeholder_content}
    '''
```

## 📋 Requirements

- **Python 3.7+** with standard library
- **JSON input file** with proper model structure
- **Write permissions** for output directory

## 🎯 Output Integration

The generated files can be integrated with:

### CMake Build System
```cmake
# Include generated wrapper
include_directories(${CMAKE_CURRENT_SOURCE_DIR}/generated)

# Link with Simulink model
target_link_libraries(your_target PRIVATE model_wrapper simulink_model)
```

### Direct Compilation
```bash
# Compile with your Simulink model
g++ -std=c++14 -I./generated -I./simulink_model \\
    test_example.cpp model_test_wrapper.cpp \\
    simulink_model.cpp -o model_test
```

### C Integration
```c
#include "model_test_wrapper.h"

int main() {
    c_model_initialize();
    g_InScalar_dvPrivate_amMethod = 1.0f;
    c_model_step();
    printf("Output: %f\\n", g_OutScalar_dvPrivate_amMethod);
    c_model_terminate();
}
```

## 🔍 Debugging and Troubleshooting

### Common Issues

1. **JSON Format Errors**
   - Validate JSON structure with online tools
   - Check for missing required fields
   - Ensure proper data type specifications

2. **Type Conversion Issues**
   - Verify signal classifications (scalar/array/bus)
   - Check custom type definitions
   - Ensure proper default value formats

3. **Generated Code Compilation**
   - Include all required header files
   - Link with Simulink-generated object files
   - Check compiler compatibility (C++14+ required)

### Debugging Features
- **Comprehensive error messages** with context
- **JSON validation** with helpful error reporting
- **Generated code validation** with syntax checking
- **Verbose logging** for troubleshooting

This generator provides a complete solution for creating test wrappers for Simulink models, enabling easy integration, testing, and validation of generated C++ code.