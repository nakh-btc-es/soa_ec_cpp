import os
import shutil
import subprocess
import sys
import argparse

def check_dependency(tool_name):
    """Check if a tool is installed and return its path or None."""
    return shutil.which(tool_name)

def generate_doxygen_config(source_dir, output_dir, graphviz_path="", project_name="MyProject"):
    doxyfile_content = f"""
    PROJECT_NAME           = "{project_name}"
    INPUT                  = "{source_dir}"
    OUTPUT_DIRECTORY       = "{output_dir}"
    RECURSIVE              = YES
    GENERATE_HTML          = YES
    GENERATE_LATEX         = NO
    HAVE_DOT               = YES
    DOT_PATH               = "{graphviz_path}"
    CLASS_DIAGRAMS         = YES
    CLASS_GRAPH            = YES
    COLLABORATION_GRAPH    = YES
    GROUP_GRAPHS           = YES
    INCLUDE_GRAPH          = YES
    INCLUDED_BY_GRAPH      = YES
    CALL_GRAPH             = YES
    CALLER_GRAPH           = YES
    GRAPHICAL_HIERARCHY    = YES
    DIRECTORY_GRAPH        = YES
    DOT_IMAGE_FORMAT       = svg
    INTERACTIVE_SVG        = YES
    DOT_GRAPH_MAX_NODES    = 50
    MAX_DOT_GRAPH_DEPTH    = 0
    GENERATE_TREEVIEW      = YES
    DISABLE_INDEX          = NO
    GENERATE_TAGFILE       = "{project_name}.tag"
    EXTRACT_ALL            = YES
    EXTRACT_PRIVATE        = YES
    EXTRACT_STATIC         = YES
    SOURCE_BROWSER         = YES
    INLINE_SOURCES         = NO
    STRIP_CODE_COMMENTS    = YES
    REFERENCED_BY_RELATION = YES
    REFERENCES_RELATION    = YES
    REFERENCES_LINK_SOURCE = YES
    USE_MDFILE_AS_MAINPAGE = README.md
    HTML_DYNAMIC_SECTIONS  = YES
    GENERATE_DOCSET        = NO
    DOCSET_FEEDNAME        = "Doxygen generated docs"
    DOCSET_BUNDLE_ID       = org.doxygen.Project
    DOCSET_PUBLISHER_ID    = org.doxygen.Publisher
    DOCSET_PUBLISHER_NAME  = Publisher
    """
    config_path = os.path.join(output_dir, "Doxyfile")
    os.makedirs(output_dir, exist_ok=True)
    with open(config_path, "w") as f:
        f.write(doxyfile_content)
    return config_path

def run_doxygen(config_path):
    subprocess.run(["doxygen", config_path], check=True)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate documentation with Doxygen")
    parser.add_argument("source_folder", help="Path to C++ source code folder")
    parser.add_argument("-o", "--output", default="./docs", help="Output directory for documentation (default: ./docs)")
    parser.add_argument("-n", "--name", default="MyProject", help="Project name (default: MyProject)")
    
    args = parser.parse_args()

    # Check dependencies
    doxygen_path = check_dependency("doxygen")
    dot_path = check_dependency("dot")

    if not doxygen_path:
        sys.exit("Error: Doxygen is not installed. Please install it first.")
    if not dot_path:
        sys.exit("Error: Graphviz (dot) is not installed. Please install it first.")

    # Generate config and run
    config_file = generate_doxygen_config(args.source_folder, args.output, 
                                        graphviz_path=os.path.dirname(dot_path), 
                                        project_name=args.name)
    print(f"Doxygen config generated at: {config_file}")

    print("Running Doxygen...")
    run_doxygen(config_file)
    print(f"Documentation generated successfully in: {args.output}/html")
