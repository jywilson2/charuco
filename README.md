# Parametric 3D-Printable ChArUco Calibration Target

**A robust OpenSCAD toolkit for generating large-scale ChArUco calibration boards that can be split and 3D printed on standard-sized beds.**

This project features precision multi-material slicing support and modular assembly options, making it easy to create professional-grade computer vision calibration targets without a large-format printer.

## Key Features

* **Auto-Splitting:** Automatically slices large targets (e.g., 15x15 grids) into printable sections compatible with standard build volumes like the Prusa XL, Bambu X1, and Prusa MK4.
* **Modular Assembly:** Choose between two robust connection styles:
* **Smart Dovetails:** Precision puzzle-fit with anchored geometry for a flat, glue-assembled board.
* **Joiner Plates:** Reinforced screw-fastened connections using printed plates and standard M3/wood screws.


* **Multi-Material Ready:** Generates separate "White Base" and "Black Pattern" STL files with anchored geometry, ensuring perfect boolean unions in slicers.
* **Robust Geometry:** Includes reinforcement bosses for screw holes and "top-open" dovetail slots to ensure easy assembly and structural integrity.
* **Python Integration:** Includes a helper script to generate standard ArUco dictionary patterns (`markers.scad`).

## Usage Summary

1. **Generate Markers:** Run the included Python script to generate the ArUco marker library:
```bash
python generate_library.py

```


2. **Configure:** Open the `.scad` file in OpenSCAD and select your **Printer Model** and **Connection Type** in the Customizer.
3. **Export:** Select the **Part Index** you wish to print, then export the `White Base` and `Black Pattern` files separately.
4. **Print:** Import both files into your slicer as a "Multi-Part Object" to preserve alignment and assign filament colors.

