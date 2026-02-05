"""
===============================================================================
CHARUCO MARKER LIBRARY GENERATOR (V37.0)
===============================================================================
Purpose: 
    Generates an OpenSCAD library file ('markers.scad') containing 113 unique 
    ChArUco marker geometries. This is required for the main .scad script.

Usage:
    1. Install opencv-python:  pip install opencv-python
    2. Run this script:        python generate_library.py
    3. Output:                 Creates 'markers.scad' in the same directory.

[DEBUG LOGGING]
    - The script will output its progress to the console.
    - It verifies the file path before writing.
===============================================================================
"""

import cv2
import cv2.aruco as aruco
import os

# --- CONFIGURATION -----------------------------------------------------------
# The Dictionary MUST match the physical layout of your board.
# Using DICT_4X4_250 standard for ChArUco.
DICT = aruco.getPredefinedDictionary(aruco.DICT_4X4_250)
SCAD_LIB_FILE = "markers.scad"
MARKER_COUNT = 113

# --- MAIN GENERATION LOOP ----------------------------------------------------
print(f"[INFO] Initializing generation of {MARKER_COUNT} markers...")
print(f"[INFO] Target Output: {os.path.abspath(SCAD_LIB_FILE)}")

try:
    with open(SCAD_LIB_FILE, "w") as f:
        # Header Documentation
        f.write("// ==================================================\n")
        f.write("// GENERATED CHARUCO MARKER LIBRARY\n")
        f.write(f"// Dictionary:   DICT_4X4_250\n")
        f.write(f"// Count:        {MARKER_COUNT} Markers\n")
        f.write("// ==================================================\n\n")
        
        # VALIDATION FLAG (Used by main script to confirm file exists)
        f.write("markers_loaded = true;\n\n")
        
        f.write("module draw_marker(id) {\n")
        
        for i in range(MARKER_COUNT):
            # Generate 6x6 pixel image (4x4 marker + 1px border)
            img = aruco.generateImageMarker(DICT, i, 6)
            
            f.write(f"    if (id == {i}) {{\n")
            
            # We generate geometry ONLY for WHITE pixels.
            # In ChArUco, the marker bits are white holes inside a black square.
            for y in range(6):
                for x in range(6):
                    # Check for white pixel (value > 128)
                    if img[y, x] > 128: 
                        # OpenSCAD Y is inverted relative to Image Y (Top-Down vs Bottom-Up)
                        f.write(f"        translate([{x}, {5-y}, 0]) square([1, 1]);\n")
            
            f.write("    }\n")
            
        f.write("}\n")
    print(f"[SUCCESS] Library generated successfully at '{SCAD_LIB_FILE}'.")
    print("[NEXT STEP] Open the .scad file in OpenSCAD.")

except Exception as e:
    print(f"[ERROR] Failed to generate library: {e}")

