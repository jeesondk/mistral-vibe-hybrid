#!/usr/bin/env python3
"""
Loader script for Vibe extensions
This script patches Vibe before it starts to add custom commands
"""

import os
import sys
import subprocess

# First, try to import Vibe to see if we're in the right environment
try:
    import vibe
    VIBE_AVAILABLE = True
except ImportError:
    VIBE_AVAILABLE = False

if not VIBE_AVAILABLE:
    # Try to run with the correct Python environment
    vibe_path = subprocess.run(
        ["which", "vibe"], 
        capture_output=True, 
        text=True
    ).stdout.strip()
    
    if vibe_path:
        # Run this script again with the correct Python
        python_path = subprocess.run(
            ["readlink", "-f", vibe_path], 
            capture_output=True, 
            text=True
        ).stdout.strip().replace("/bin/vibe", "/bin/python3")
        
        if os.path.exists(python_path):
            # Re-execute with correct Python
            subprocess.run([python_path, __file__] + sys.argv[1:])
            sys.exit(0)
    
    print("❌ Vibe not found. Please ensure Vibe is installed and in PATH.")
    sys.exit(1)

# Add the current directory to Python path so we can import our extension
script_dir = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, script_dir)

# Apply the patches
try:
    import vibe_custom_commands
    vibe_custom_commands.patch_vibe()
except Exception as e:
    print(f"⚠️  Could not load Vibe extensions: {e}")
    print("   Custom commands will not be available")

# Now import and run the original Vibe
from vibe.cli.entrypoint import main

if __name__ == "__main__":
    # Set environment variable so Vibe knows about our project root
    os.environ['VIBE_PROJECT_ROOT'] = script_dir
    main()
