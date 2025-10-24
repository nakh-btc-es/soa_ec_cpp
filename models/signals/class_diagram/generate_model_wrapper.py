#!/usr/bin/env python3
"""
Simulink Model Test Wrapper Code Generator
==========================================

This script reads a JSON model structure file and generates:
1. model_test_wrapper.h - Header file with declarations and global variables

The generator creates a complete C/C++ interface for testing Simulink-generated 
models with global variable access and function declarations.

Usage:
    python generate_model_wrapper.py <json_file> [output_dir]

Example:
    python generate_model_wrapper.py signal_model_structure.json ./output/
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Any, Optional
from dataclasses import dataclass
from datetime import datetime

@dataclass
class SignalInfo:
    """Structure to hold signal information from JSON"""
    name: str
    data_type: str
    classification: str
    dimensions: str
    description: str
    default_value: Any
    setter_method: Optional[str] = None
    getter_method: Optional[str] = None
    simulink_port: Optional[str] = None

@dataclass
class ModelInfo:
    """Structure to hold complete model information"""
    name: str
    version: str
    namespace: str
    description: str
    inputs: List[SignalInfo]
    outputs: List[SignalInfo]
    parameters: List[SignalInfo]
    states: List[SignalInfo]
    custom_types: Dict[str, Any]

class CodeTemplate:
    """Code generation templates"""
    
    @staticmethod
    def header_file_template() -> str:
        return '''//
// Test wrapper header for {model_name} Simulink model
//
// This header provides declarations for global variables and functions
// to test and integrate the Simulink-generated model class.
//
// Generated for model: {model_name} v{version}
// Generated on: {timestamp}
// Generator: Simulink Model Test Wrapper Code Generator
//

#ifndef MODEL_TEST_WRAPPER_H
#define MODEL_TEST_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

{custom_type_definitions}

//=============================================================================
// GLOBAL INPUT VARIABLES (external write access)
//=============================================================================

{input_declarations}

//=============================================================================
// GLOBAL OUTPUT VARIABLES (external read access)
//=============================================================================

{output_declarations}

//=============================================================================
// GLOBAL PARAMETER VARIABLES (external write access)
//=============================================================================

{parameter_declarations}

//=============================================================================
// GLOBAL STATE VARIABLES (external read access for monitoring)
//=============================================================================

{state_declarations}

//=============================================================================
// MODEL LIFECYCLE FUNCTIONS
//=============================================================================

#ifdef __cplusplus
extern "C" {{
#endif

/**
 * @brief Initialize the model instance and set default parameters
 * @return true if initialization successful, false otherwise
 */
bool model_initialize();

/**
 * @brief Terminate the model and cleanup resources
 */
void model_terminate();

/**
 * @brief Execute one time step of the model
 * 
 * This function:
 * 1. Transfers global input variables to model inputs
 * 2. Executes the model step function  
 * 3. Transfers model outputs to global output variables
 * 4. Updates global state variables for monitoring
 * 
 * @return true if step executed successfully, false otherwise
 */
bool model_step();

/**
 * @brief Update model parameters from global parameter variables
 * @return true if parameters updated successfully, false otherwise
 */
bool model_update_parameters();

//=============================================================================
// UTILITY AND DEBUG FUNCTIONS
//=============================================================================

void model_print_inputs();
void model_print_outputs();
void model_print_states();
void model_print_parameters();
void model_print_status();
bool model_test_step_response();

//=============================================================================
// C INTERFACE (for external integration)
//=============================================================================

bool c_model_initialize();
void c_model_terminate();
bool c_model_step();
bool c_model_update_parameters();
void c_model_print_status();

#ifdef __cplusplus
}}
#endif

{usage_examples}

#endif // MODEL_TEST_WRAPPER_H'''



class ModelWrapperGenerator:
    """Main generator class for creating model wrapper code"""
    
    def __init__(self, json_file_path: str):
        """Initialize generator with JSON model description"""
        self.json_file = Path(json_file_path)
        self.model_info = self._parse_json_file()
        
    def _parse_json_file(self) -> ModelInfo:
        """Parse JSON file and extract model information"""
        try:
            with open(self.json_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
        except (FileNotFoundError, json.JSONDecodeError) as e:
            raise ValueError(f"Error reading JSON file: {e}")
        
        # Extract model information
        model_info_data = data.get('model_info', {})
        model_name = model_info_data.get('name', 'unknown_model')
        model_version = model_info_data.get('version', '1.0')
        model_namespace = model_info_data.get('namespace', '')
        
        # Parse inputs
        inputs = self._parse_signals(data.get('inputs', {}), 'input')
        
        # Parse outputs  
        outputs = self._parse_signals(data.get('outputs', {}), 'output')
        
        # Parse parameters
        parameters = self._parse_parameters(data.get('parameters', {}))
        
        # Parse state variables
        states = self._parse_states(data.get('local_variables', {}))
        
        # Parse custom types
        custom_types = data.get('custom_types', {})
        
        return ModelInfo(
            name=model_name,
            version=model_version,
            namespace=model_namespace,
            description=f"Signal processing class with unit delays and parameter scaling",
            inputs=inputs,
            outputs=outputs,
            parameters=parameters,
            states=states,
            custom_types=custom_types
        )
    
    def _parse_signals(self, signals_data: Dict, signal_type: str) -> List[SignalInfo]:
        """Parse input or output signals from JSON"""
        signals = []
        signals_list = signals_data.get('signals', [])
        
        for signal in signals_list:
            signal_info = signal.get('signal_info', {})
            
            signals.append(SignalInfo(
                name=signal.get('name', ''),
                data_type=self._get_c_type(signal_info),
                classification=signal_info.get('classification', 'scalar'),
                dimensions=signal_info.get('dimensions', '1x1'),
                description=signal.get('description', ''),
                default_value=signal.get('default_value'),
                setter_method=signal.get('setter_method') if signal_type == 'input' else None,
                getter_method=signal.get('getter_method') if signal_type == 'output' else None,
                simulink_port=signal.get('simulink_port')
            ))
        
        return signals
    
    def _parse_parameters(self, params_data: Dict) -> List[SignalInfo]:
        """Parse parameters from JSON"""
        parameters = []
        params_list = params_data.get('parameters', [])
        
        for param in params_list:
            signal_info = param.get('signal_info', {})
            
            parameters.append(SignalInfo(
                name=param.get('name', ''),
                data_type=self._get_c_type(signal_info),
                classification=signal_info.get('classification', 'scalar'),
                dimensions=signal_info.get('dimensions', '1x1'),
                description=param.get('description', ''),
                default_value=param.get('default_value'),
                simulink_port=param.get('simulink_reference')
            ))
        
        return parameters
    
    def _parse_states(self, states_data: Dict) -> List[SignalInfo]:
        """Parse state variables from JSON"""
        states = []
        state_vars = states_data.get('state_variables', [])
        
        for state in state_vars:
            signal_info = state.get('signal_info', {})
            
            states.append(SignalInfo(
                name=state.get('name', ''),
                data_type=self._get_c_type(signal_info),
                classification=signal_info.get('classification', 'scalar'),
                dimensions=signal_info.get('dimensions', '1x1'),
                description=state.get('description', ''),
                default_value=state.get('default_value'),
                simulink_port=state.get('simulink_block')
            ))
        
        return states
    
    def _get_c_type(self, signal_info: Dict) -> str:
        """Convert signal info to C type declaration"""
        data_type = signal_info.get('data_type', 'float')
        classification = signal_info.get('classification', 'scalar')
        element_count = signal_info.get('element_count', 1)
        
        if classification == 'array' and element_count > 1:
            return f"{data_type}[{element_count}]"
        elif classification == 'bus':
            return signal_info.get('bus_type', 'myBus')
        else:
            return data_type
    
    def generate_header_file(self, output_dir: str = ".") -> str:
        """Generate the model_test_wrapper.h file"""
        output_path = Path(output_dir) / "model_test_wrapper.h"
        
        # Generate custom type definitions
        custom_types = self._generate_custom_types()
        
        # Generate variable declarations
        input_decls = self._generate_variable_declarations(self.model_info.inputs, "Input")
        output_decls = self._generate_variable_declarations(self.model_info.outputs, "Output")
        param_decls = self._generate_variable_declarations(self.model_info.parameters, "Parameter")
        state_decls = self._generate_variable_declarations(self.model_info.states, "State")
        
        # Generate usage examples
        usage_examples = self._generate_usage_examples()
        
        # Fill template
        header_content = CodeTemplate.header_file_template().format(
            model_name=self.model_info.name,
            version=self.model_info.version,
            timestamp=datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
            custom_type_definitions=custom_types,
            input_declarations=input_decls,
            output_declarations=output_decls,
            parameter_declarations=param_decls,
            state_declarations=state_decls,
            usage_examples=usage_examples
        )
        
        # Write file
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write(header_content)
        
        return str(output_path)
    

    
    def _generate_custom_types(self) -> str:
        """Generate custom type definitions"""
        custom_types = []
        
        for type_name, type_info in self.model_info.custom_types.items():
            fields = type_info.get('fields', [])
            
            custom_types.append(f"// {type_info.get('description', 'Custom type definition')}")
            custom_types.append(f"#ifndef DEFINED_TYPEDEF_FOR_{type_name}_")
            custom_types.append(f"#define DEFINED_TYPEDEF_FOR_{type_name}_")
            custom_types.append(f"struct {type_name}")
            custom_types.append("{")
            
            for field in fields:
                field_type = field.get('type', 'float')
                field_name = field.get('name', 'unknown')
                field_desc = field.get('description', '')
                
                if field_desc:
                    custom_types.append(f"  {field_type} {field_name}; // {field_desc}")
                else:
                    custom_types.append(f"  {field_type} {field_name};")
            
            custom_types.append("};")
            custom_types.append("#endif")
            custom_types.append("")
        
        return "\\n".join(custom_types)
    
    def _generate_variable_declarations(self, signals: List[SignalInfo], category: str) -> str:
        """Generate variable declarations for signals"""
        if not signals:
            return f"// No {category.lower()} variables defined"
        
        declarations = []
        
        for signal in signals:
            # Generate comment with description
            if signal.description:
                declarations.append(f"// {signal.description}")
            
            # Determine default value string
            default_str = self._format_default_value(signal.default_value, signal.data_type)
            
            # Generate declaration
            if signal.classification == 'array':
                declarations.append(f"extern {signal.data_type} g_{signal.name};")
            else:
                declarations.append(f"extern {signal.data_type} g_{signal.name};")
            
            declarations.append("")  # Empty line for readability
        
        return "\\n".join(declarations)
    
    def _format_default_value(self, default_value: Any, data_type: str) -> str:
        """Format default value for C initialization"""
        if default_value is None:
            if 'int' in data_type:
                return "0"
            elif 'float' in data_type:
                return "0.0f"
            else:
                return "{}"
        
        if isinstance(default_value, list):
            if 'float' in data_type:
                return "{" + ", ".join(f"{v}f" for v in default_value) + "}"
            else:
                return "{" + ", ".join(str(v) for v in default_value) + "}"
        
        if isinstance(default_value, dict):
            # For bus types
            values = [f"{v}f" if isinstance(v, float) else str(v) for v in default_value.values()]
            return "{" + ", ".join(values) + "}"
        
        if isinstance(default_value, float):
            return f"{default_value}f"
        
        return str(default_value)
    
    def _generate_usage_examples(self) -> str:
        """Generate usage examples section"""
        examples = [
            "/*",
            "",
            "BASIC USAGE EXAMPLE:",
            "===================",
            "",
            "#include \\"model_test_wrapper.h\\"",
            "",
            "int main() {",
            "    // Initialize the model",
            "    if (!model_initialize()) {",
            "        return -1;",
            "    }",
            "    "
        ]
        
        # Add input setting examples
        scalar_inputs = [s for s in self.model_info.inputs if s.classification == 'scalar']
        array_inputs = [s for s in self.model_info.inputs if s.classification == 'array']
        bus_inputs = [s for s in self.model_info.inputs if s.classification == 'bus']
        
        if scalar_inputs:
            examples.append("    // Set scalar inputs")
            for signal in scalar_inputs[:3]:  # Limit to first 3 for brevity
                examples.append(f"    g_{signal.name} = 1.5f;")
        
        if array_inputs:
            examples.append("    // Set array inputs")
            for signal in array_inputs[:2]:  # Limit to first 2
                examples.append(f"    g_{signal.name}[0] = 2.0f;")
                examples.append(f"    g_{signal.name}[1] = 3.0f;")
        
        if bus_inputs:
            examples.append("    // Set bus inputs")
            for signal in bus_inputs[:1]:  # Limit to first 1
                examples.append(f"    g_{signal.name}.FlptSig1 = 4.0f;")
                examples.append(f"    g_{signal.name}.FlptSig2 = 5.0f;")
        
        examples.extend([
            "    ",
            "    // Execute model step",
            "    if (!model_step()) {",
            "        model_terminate();",
            "        return -1;",
            "    }",
            "    "
        ])
        
        # Add output reading examples
        scalar_outputs = [s for s in self.model_info.outputs if s.classification == 'scalar']
        if scalar_outputs:
            examples.append("    // Read outputs")
            signal = scalar_outputs[0]
            examples.append(f"    printf(\\"Scalar Output: %f\\\\n\\", g_{signal.name});")
        
        examples.extend([
            "    ",
            "    // Print complete status",
            "    model_print_status();",
            "    ",
            "    // Cleanup",
            "    model_terminate();",
            "    return 0;",
            "}",
            "",
            "*/",
            ""
        ])
        
        return "\\n".join(examples)
    

    

    

    

    


def main():
    """Main function to run the generator"""
    if len(sys.argv) < 2:
        print("Usage: python generate_model_wrapper.py <json_file> [output_dir]")
        print("Example: python generate_model_wrapper.py signal_model_structure.json ./output/")
        return 1
    
    json_file = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "."
    
    # Create output directory if it doesn't exist
    Path(output_dir).mkdir(parents=True, exist_ok=True)
    
    try:
        print(f"🔍 Parsing JSON file: {json_file}")
        generator = ModelWrapperGenerator(json_file)
        
        print(f"📋 Model: {generator.model_info.name} v{generator.model_info.version}")
        print(f"📊 Inputs: {len(generator.model_info.inputs)}")
        print(f"📊 Outputs: {len(generator.model_info.outputs)}")
        print(f"📊 States: {len(generator.model_info.states)}")
        print(f"📊 Custom Types: {len(generator.model_info.custom_types)}")
        
        print("\\n🔨 Generating header file...")
        
        # Generate header file
        header_path = generator.generate_header_file(output_dir)
        print(f"✅ Generated: {header_path}")
        
        print(f"\\n🎉 Code generation completed successfully!")
        print(f"📁 Output directory: {Path(output_dir).resolve()}")
        
        return 0
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1

if __name__ == "__main__":
    exit(main())