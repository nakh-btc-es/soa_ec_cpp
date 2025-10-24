# C++ Class Diagram Generator Agent

An intelligent agent that analyzes C++ code in a specified folder and generates professional Mermaid class diagrams, then exports them as PNG files.

## Features

- 🔍 **Comprehensive C++ Analysis**: Parses header (.h, .hpp) and source (.cpp, .cxx) files
- 📊 **Detailed Class Diagrams**: Extracts classes, methods, fields, visibility, inheritance, and namespaces
- 🎨 **Mermaid Integration**: Generates clean, professional Mermaid class diagrams
- 🖼️ **PNG Export**: Automatically exports diagrams to high-quality PNG images
- 🗂️ **Recursive Folder Analysis**: Analyzes entire directory structures
- 🏷️ **Namespace Support**: Properly handles C++ namespaces
- 🔗 **Inheritance Visualization**: Shows class inheritance relationships
- ⚙️ **Member Details**: Displays methods, fields, visibility (public/private/protected), static members, and more

## Prerequisites

### Required Software

1. **Python 3.7+**
   - Download from: https://python.org/
   - Ensure Python is added to your PATH

2. **Node.js**
   - Download from: https://nodejs.org/
   - Required for Mermaid CLI

### Installation

1. **Clone or download this repository**
   ```bash
   git clone <repository-url>
   cd soa_ec_cpp
   ```

2. **Install Python dependencies** (optional, mostly built-in modules)
   ```bash
   pip install -r requirements.txt
   ```

3. **The Mermaid CLI will be installed automatically** when you first run the script
   - Or install manually: `npm install -g @mermaid-js/mermaid-cli`

## Usage

### Method 1: Using the Batch Script (Windows)

```batch
# Basic usage
generate_class_diagram.bat models\signals

# With custom output path
generate_class_diagram.bat models\signals my_diagram.png
```

### Method 2: Using Python Directly

```bash
# Basic usage
python cpp_class_diagram_generator.py models/signals

# With custom output path
python cpp_class_diagram_generator.py models/signals -o my_diagram.png

# With verbose logging
python cpp_class_diagram_generator.py models/signals -v

# Show help
python cpp_class_diagram_generator.py --help
```

### Command Line Options

- `folder` - Path to folder containing C++ code (required)
- `-o, --output` - Output path for PNG diagram (default: `folder/class_diagram.png`)
- `-v, --verbose` - Enable verbose logging
- `-h, --help` - Show help message

## Example Usage with the Signals Folder

```bash
# Analyze the signals folder
python cpp_class_diagram_generator.py models/signals

# This will generate:
# - models/signals/class_diagram.png (PNG image)
# - models/signals/class_diagram.mmd (Mermaid source)
```

## Output Files

The agent generates two files:

1. **`class_diagram.png`** - The final class diagram as a PNG image
2. **`class_diagram.mmd`** - The Mermaid source code for the diagram

## Supported C++ Features

### Class Analysis
- ✅ Classes and structs
- ✅ Public, private, protected members
- ✅ Methods and fields
- ✅ Static members
- ✅ Virtual methods
- ✅ Const methods
- ✅ Method parameters and return types
- ✅ Inheritance relationships
- ✅ Namespaces
- ✅ Nested classes (basic support)

### File Types
- ✅ `.cpp`, `.cxx`, `.cc`, `.c++` (source files)
- ✅ `.h`, `.hpp`, `.hxx`, `.h++` (header files)

## Example Output

For the signals folder containing `signal_dvPrivate_acMethod` class, the agent will generate a diagram showing:

```mermaid
classDiagram
class btc_soa_signal_dvPrivate_acMethod {
    +ExtU rtU
    +ExtY rtY
    -P rtP {static}
    +setInScalar_dvPrivate_amMethod(float): void
    +setInArray_dvPrivate_amMethod(float[]): void
    +setInBus_dvPrivate_amMethod(myBus): void
    +getOutScalar_dvPrivate_amMethod(): float
    +getOutArray_dvPrivate_amMethod(): float*
    +getOutBus_dvPrivate_amMethod(): myBus
    +step(): void
    +initialize(): void {static}
    +signal_dvPrivate_acMethod()
    +~signal_dvPrivate_acMethod()
}

class myBus {
    +FlptSig1: float
    +FlptSig2: float
}
```

## Troubleshooting

### Common Issues

1. **"Node.js is not installed"**
   - Install Node.js from https://nodejs.org/
   - Restart your terminal/command prompt

2. **"Failed to install Mermaid CLI"**
   - Run manually: `npm install -g @mermaid-js/mermaid-cli`
   - On some systems, you might need administrator/sudo privileges

3. **"No C++ classes found"**
   - Ensure the folder contains `.cpp`, `.h`, or similar C++ files
   - Check that the files contain valid C++ class definitions
   - Use `-v` flag for verbose logging to see what files are being processed

4. **PNG generation fails**
   - Ensure Mermaid CLI is properly installed: `mmdc --version`
   - Check the generated `.mmd` file for syntax errors
   - Try running the Mermaid CLI manually: `mmdc -i diagram.mmd -o diagram.png`

### Debugging

Use the verbose flag to see detailed processing information:
```bash
python cpp_class_diagram_generator.py models/signals -v
```

This will show:
- Which files are being parsed
- How many classes were found
- Class names and namespaces
- Mermaid generation progress
- Export status

## Architecture

The agent consists of four main components:

1. **CppParser** - Parses C++ files using regex patterns to extract class information
2. **MermaidGenerator** - Converts parsed class data into Mermaid diagram syntax
3. **DiagramExporter** - Exports Mermaid diagrams to PNG using the Mermaid CLI
4. **CppClassDiagramAgent** - Orchestrates the entire process

## Extending the Agent

The agent is designed to be extensible. You can:

- Add support for additional C++ features by extending the regex patterns in `CppParser`
- Customize diagram appearance by modifying `MermaidGenerator`
- Add support for other output formats by extending `DiagramExporter`
- Add new analysis features in the main `CppClassDiagramAgent` class

## Contributing

Feel free to submit issues and pull requests to improve the agent's C++ parsing capabilities and diagram generation features.

## License

This project is open source. See the license file for details.