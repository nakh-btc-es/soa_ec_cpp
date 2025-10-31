

#!/usr/bin/env python3
"""
Reusable C++ Class Diagram Generator for Simulink Generated Code
================================================================

This script analyzes C++ files generated from Simulink models and creates
VS Code-compatible Mermaid class diagrams.

Usage:
    python analyze_simulink_cpp.py <folder_path> [output_name]

Example:
    python analyze_simulink_cpp.py models/signals/signal_dvPrivate_acMethod_ert_rtw signal_analysis

Features:
- Analyzes header files for class structures
- Identifies nested structs and their relationships  
- Generates Mermaid class diagrams compatible with VS Code
- Creates comprehensive analysis reports
- Supports Simulink ERT generated code patterns

Requirements:
- VS Code with Mermaid Preview extension (vstirbu.vscode-mermaid-preview)
"""

import os
import re
import sys
from pathlib import Path
from dataclasses import dataclass, field
from typing import List, Dict, Set, Optional

@dataclass
class CppClass:
    """Represents a C++ class with its members and methods"""
    name: str
    namespace: str = ""
    is_struct: bool = False
    is_final: bool = False
    methods: List[str] = field(default_factory=list)
    fields: List[str] = field(default_factory=list)
    nested_classes: List['CppClass'] = field(default_factory=list)
    base_classes: List[str] = field(default_factory=list)

class SimulinkCppAnalyzer:
    """Analyzer specifically designed for Simulink-generated C++ code"""
    
    def __init__(self, folder_path: str):
        self.folder_path = Path(folder_path)
        self.classes: List[CppClass] = []
        self.structs: List[CppClass] = []
        self.relationships: List[tuple] = []
        
    def analyze(self) -> Dict:
        """Main analysis method"""
        if not self.folder_path.exists():
            raise ValueError(f"Folder not found: {self.folder_path}")
            
        # Find C++ files
        cpp_files = list(self.folder_path.glob("*.h")) + list(self.folder_path.glob("*.hpp"))
        
        if not cpp_files:
            raise ValueError(f"No C++ header files found in {self.folder_path}")
        
        # Analyze each file
        for file_path in cpp_files:
            self._analyze_file(file_path)
        
        # Extract relationships
        self._extract_relationships()
        
        return {
            'classes': self.classes,
            'structs': self.structs,
            'relationships': self.relationships,
            'files_analyzed': [f.name for f in cpp_files]
        }
    
    def _analyze_file(self, file_path: Path):
        """Analyze a single C++ file"""
        try:
            content = file_path.read_text(encoding='utf-8')
        except UnicodeDecodeError:
            content = file_path.read_text(encoding='latin-1')
        
        # Extract namespace
        namespace = self._extract_namespace(content)
        
        # Extract classes and structs
        self._extract_classes_and_structs(content, namespace)
    
    def _extract_namespace(self, content: str) -> str:
        """Extract namespace from content"""
        namespace_pattern = r'namespace\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*{'
        match = re.search(namespace_pattern, content)
        return match.group(1) if match else ""
    
    def _extract_classes_and_structs(self, content: str, namespace: str):
        """Extract class and struct definitions"""
        # Class pattern with optional final keyword
        class_pattern = r'(class|struct)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*(final)?\s*(?::\s*[^{]+)?\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}'
        
        for match in re.finditer(class_pattern, content, re.DOTALL):
            type_keyword = match.group(1)
            class_name = match.group(2)
            is_final = bool(match.group(3))
            class_body = match.group(4)
            
            cpp_class = CppClass(
                name=class_name,
                namespace=namespace,
                is_struct=(type_keyword == 'struct'),
                is_final=is_final
            )
            
            # Extract methods and fields
            self._extract_class_members(class_body, cpp_class)
            
            # Extract nested classes/structs
            self._extract_nested_classes(class_body, cpp_class, namespace)
            
            if cpp_class.is_struct:
                self.structs.append(cpp_class)
            else:
                self.classes.append(cpp_class)
    
    def _extract_class_members(self, class_body: str, cpp_class: CppClass):
        """Extract methods and fields from class body"""
        lines = class_body.split('\n')
        
        for line in lines:
            line = line.strip()
            if not line or line.startswith('//'):
                continue
                
            # Method patterns
            method_pattern = r'([a-zA-Z_][a-zA-Z0-9_<>*&,:\s]*)\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\([^)]*\)\s*(?:const)?\s*[;{]'
            field_pattern = r'([a-zA-Z_][a-zA-Z0-9_<>*&,:\s\[\]]*)\s+([a-zA-Z_][a-zA-Z0-9_\[\]]*)\s*[;=]'
            
            # Check for methods
            method_match = re.search(method_pattern, line)
            if method_match and '(' in line:
                method_signature = line.replace(';', '').replace('{', '').strip()
                # Determine visibility
                visibility = '+' if 'public:' in class_body[:class_body.find(line)] else '-'
                if 'private:' in class_body[:class_body.find(line)]:
                    visibility = '-'
                elif 'protected:' in class_body[:class_body.find(line)]:
                    visibility = '#'
                
                cpp_class.methods.append(f"{visibility}{method_signature}")
            
            # Check for fields
            elif re.search(field_pattern, line) and '(' not in line:
                # Determine visibility
                visibility = '+' if cpp_class.is_struct else '-'
                if 'public:' in class_body[:class_body.find(line)]:
                    visibility = '+'
                elif 'private:' in class_body[:class_body.find(line)]:
                    visibility = '-'
                elif 'protected:' in class_body[:class_body.find(line)]:
                    visibility = '#'
                
                cpp_class.fields.append(f"{visibility}{line}")
    
    def _extract_nested_classes(self, class_body: str, parent_class: CppClass, namespace: str):
        """Extract nested classes and structs"""
        nested_pattern = r'struct\s+([a-zA-Z_][a-zA-Z0-9_]*)\s*\{([^}]*(?:\{[^}]*\}[^}]*)*)\}'
        
        for match in re.finditer(nested_pattern, class_body, re.DOTALL):
            nested_name = match.group(1)
            nested_body = match.group(2)
            
            nested_class = CppClass(
                name=nested_name,
                namespace=namespace,
                is_struct=True
            )
            
            self._extract_class_members(nested_body, nested_class)
            parent_class.nested_classes.append(nested_class)
            self.structs.append(nested_class)
    
    def _extract_relationships(self):
        """Extract relationships between classes"""
        for cpp_class in self.classes + self.structs:
            # Composition relationships (contains nested classes)
            for nested in cpp_class.nested_classes:
                self.relationships.append((cpp_class.name, nested.name, 'contains'))
            
            # Usage relationships (check field types)
            for field in cpp_class.fields:
                for other_class in self.classes + self.structs:
                    if other_class.name != cpp_class.name and other_class.name in field:
                        self.relationships.append((cpp_class.name, other_class.name, 'uses'))

class MermaidGenerator:
    """Generates Mermaid class diagrams"""
    
    def __init__(self, analysis_result: Dict, title: str = "C++ Class Diagram"):
        self.analysis = analysis_result
        self.title = title
    
    def generate(self) -> str:
        """Generate Mermaid class diagram"""
        mermaid = [
            "---",
            f"title: {self.title}",
            "---",
            "classDiagram"
        ]
        
        # Add namespace if present
        namespace = ""
        if self.analysis['classes']:
            namespace = self.analysis['classes'][0].namespace
        
        if namespace:
            mermaid.append(f"    namespace {namespace} {{")
            indent = "        "
        else:
            indent = "    "
        
        # Add classes
        for cpp_class in self.analysis['classes']:
            mermaid.extend(self._generate_class_definition(cpp_class, indent))
        
        # Add structs  
        for struct in self.analysis['structs']:
            if not any(struct in cpp_class.nested_classes for cpp_class in self.analysis['classes']):
                mermaid.extend(self._generate_class_definition(struct, indent))
        
        if namespace:
            mermaid.append("    }")
        
        # Add standalone structs (outside namespace)
        standalone_structs = [s for s in self.analysis['structs'] 
                            if not s.namespace or s.namespace != namespace]
        for struct in standalone_structs:
            mermaid.extend(self._generate_class_definition(struct, "    "))
        
        # Add relationships
        mermaid.append("")
        mermaid.append("    %% Relationships")
        for source, target, rel_type in self.analysis['relationships']:
            if rel_type == 'contains':
                mermaid.append(f"    {source} *-- {target} : {rel_type}")
            elif rel_type == 'uses':
                mermaid.append(f"    {source} --> {target} : {rel_type}")
        
        return '\n'.join(mermaid)
    
    def _generate_class_definition(self, cpp_class: CppClass, indent: str) -> List[str]:
        """Generate class definition for Mermaid"""
        lines = []
        
        # Class declaration
        class_line = f"{indent}class {cpp_class.name} {{"
        if cpp_class.is_struct:
            lines.append(f"{indent.strip()}    {cpp_class.name} {{")
            lines.append(f"{indent.strip()}        <<struct>>")
        else:
            lines.append(class_line)
            if cpp_class.is_final:
                lines.append(f"{indent.strip()}        <<final>>")
        
        # Add methods
        for method in cpp_class.methods[:10]:  # Limit to prevent clutter
            lines.append(f"{indent.strip()}        {method}")
        
        # Add fields
        for field in cpp_class.fields[:10]:  # Limit to prevent clutter
            lines.append(f"{indent.strip()}        {field}")
        
        lines.append(f"{indent.strip()}    }}")
        lines.append("")
        
        return lines

def main():
    """Main execution function"""
    if len(sys.argv) < 2:
        print("Usage: python analyze_simulink_cpp.py <folder_path> [output_name]")
        print("Example: python analyze_simulink_cpp.py models/signals/signal_dvPrivate_acMethod_ert_rtw")
        return
    
    folder_path = sys.argv[1]
    output_name = sys.argv[2] if len(sys.argv) > 2 else "cpp_analysis"
    
    try:
        # Analyze C++ code
        analyzer = SimulinkCppAnalyzer(folder_path)
        result = analyzer.analyze()
        
        print(f"✅ Analysis completed!")
        print(f"   📁 Folder: {folder_path}")
        print(f"   📄 Files analyzed: {', '.join(result['files_analyzed'])}")
        print(f"   🏗️  Classes found: {len(result['classes'])}")
        print(f"   📊 Structs found: {len(result['structs'])}")
        print(f"   🔗 Relationships: {len(result['relationships'])}")
        
        # Generate Mermaid diagram
        title = f"Class Diagram - {Path(folder_path).name}"
        generator = MermaidGenerator(result, title)
        mermaid_content = generator.generate()
        
        # Save Mermaid file
        mermaid_file = f"{output_name}_class_diagram.mmd"
        with open(mermaid_file, 'w', encoding='utf-8') as f:
            f.write(mermaid_content)
        
        print(f"   💾 Mermaid diagram saved: {mermaid_file}")
        
        # Generate analysis report
        report_content = f"""# C++ Code Analysis Report - {Path(folder_path).name}

## Analysis Summary
- **Folder Analyzed**: `{folder_path}`
- **Files Processed**: {', '.join(result['files_analyzed'])}
- **Classes Found**: {len(result['classes'])}
- **Structs Found**: {len(result['structs'])}
- **Relationships**: {len(result['relationships'])}

## Class Diagram
The Mermaid class diagram is saved in: `{mermaid_file}`

**To visualize in VS Code:**
1. Install the **Mermaid Preview** extension (`vstirbu.vscode-mermaid-preview`)
2. Open `{mermaid_file}` 
3. Press `Ctrl+Shift+P` and run **Mermaid: Preview**

## Classes and Structs Detected

### Classes
{chr(10).join([f"- **{cls.name}** ({'final' if cls.is_final else 'regular'}) - {len(cls.methods)} methods, {len(cls.fields)} fields" for cls in result['classes']])}

### Structs  
{chr(10).join([f"- **{struct.name}** - {len(struct.fields)} fields" for struct in result['structs']])}

## Relationships
{chr(10).join([f"- {source} {rel_type} {target}" for source, target, rel_type in result['relationships']])}

This analysis was generated using the reusable Simulink C++ analyzer script.
"""
        
        report_file = f"{output_name}_report.md"
        with open(report_file, 'w', encoding='utf-8') as f:
            f.write(report_content)
        
        print(f"   📋 Analysis report saved: {report_file}")
        print(f"\n🎉 Complete! Open {mermaid_file} in VS Code with Mermaid Preview extension to view the diagram.")
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return 1
    
    return 0

if __name__ == "__main__":
    exit(main())