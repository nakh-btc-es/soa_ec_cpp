#!/usr/bin/env python3
"""
Test script for the Simulink Model Test Wrapper Generator

This script tests the generator with the existing JSON file and creates
the wrapper files in a test output directory.
"""

import sys
import os
from pathlib import Path

# Add the current directory to Python path to import our generator
sys.path.append(str(Path(__file__).parent))

try:
    from generate_model_wrapper import ModelWrapperGenerator
except ImportError as e:
    print(f"❌ Could not import generator: {e}")
    print("Make sure generate_model_wrapper.py is in the same directory")
    sys.exit(1)

def test_generator():
    """Test the generator with the existing JSON file"""
    
    # Find the JSON file
    json_file = "signal_model_structure.json"
    if not Path(json_file).exists():
        print(f"❌ JSON file not found: {json_file}")
        print("Make sure signal_model_structure.json is in the current directory")
        return False
    
    # Create test output directory
    output_dir = "./test_generated"
    Path(output_dir).mkdir(exist_ok=True)
    
    try:
        print("🔍 Testing Simulink Model Test Wrapper Generator")
        print("=" * 50)
        
        print(f"📁 Input JSON: {json_file}")
        print(f"📁 Output directory: {output_dir}")
        
        # Initialize generator
        print("\\n🔧 Initializing generator...")
        generator = ModelWrapperGenerator(json_file)
        
        # Print model info
        print(f"✅ Model loaded: {generator.model_info.name} v{generator.model_info.version}")
        print(f"   📊 Inputs: {len(generator.model_info.inputs)}")
        print(f"   📊 Outputs: {len(generator.model_info.outputs)}")
        print(f"   📊 Parameters: {len(generator.model_info.parameters)}")
        print(f"   📊 States: {len(generator.model_info.states)}")
        print(f"   📊 Custom Types: {len(generator.model_info.custom_types)}")
        
        # Generate files
        print("\\n🔨 Generating wrapper files...")
        
        # Generate header file
        header_path = generator.generate_header_file(output_dir)
        print(f"   ✅ Header: {header_path}")
        
        # Verify files exist and have content
        header_size = Path(header_path).stat().st_size
        
        print(f"\\n📊 Generated file sizes:")
        print(f"   📄 {Path(header_path).name}: {header_size:,} bytes")
        
        if header_size > 0:
            print("\\n🎉 Generator test completed successfully!")
            print(f"\\n📁 Check the generated file in: {Path(output_dir).resolve()}")
            return True
        else:
            print("\\n❌ Generated file is empty!")
            return False
            
    except Exception as e:
        print(f"\\n❌ Generator test failed: {e}")
        import traceback
        print("\\nFull error details:")
        traceback.print_exc()
        return False

def show_file_previews(output_dir="./test_generated"):
    """Show preview of generated file"""
    header_file = Path(output_dir) / "model_test_wrapper.h"
    
    if header_file.exists():
        print(f"\\n📄 Preview of {header_file.name} (first 30 lines):")
        print("─" * 50)
        with open(header_file, 'r') as f:
            for i, line in enumerate(f):
                if i >= 30:
                    print("... (truncated)")
                    break
                print(line.rstrip())

def main():
    """Main test function"""
    print("🧪 SIMULINK MODEL WRAPPER GENERATOR TEST")
    print("=" * 60)
    
    # Test the generator
    success = test_generator()
    
    if success:
        # Show file previews
        show_file_previews()
        
        print("\\n" + "=" * 60)
        print("✅ TEST PASSED - Generator is working correctly!")
        print("\\n📋 Next steps:")
        print("   1. Review the generated header file in ./test_generated/")
        print("   2. Integrate with your Simulink model files")
        print("   3. Create your own test/main files using the generated header")
        print("\\n🔧 To use the generator:")
        print("   python generate_model_wrapper.py signal_model_structure.json")
        
    else:
        print("\\n" + "=" * 60)
        print("❌ TEST FAILED - Please check the error messages above")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())