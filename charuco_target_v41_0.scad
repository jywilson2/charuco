/* ========================================================================
   CH ARUCO CALIBRATION TARGET - SAFER CUTS EDITION (V41.0)
   
   [ CRITICAL FIX V41.0 ]
   1. UPDATED CUT STRATEGY:
      - Adjusted the 'calc_cuts' logic to account for dovetail tab overhang.
      - Previous Logic: 250mm bed -> 2-way split (Part height ~250mm).
        -> FAILED because tabs pushed it to ~258mm.
      - New Logic: 250mm bed -> 3-way split (Part height ~168mm).
      - 2-way split now requires >= 265mm print bed.
   
   2. BAMBU PRESET UPDATE:
      - Bambu X1/P1 (256mm) now defaults to the safer 3-way split [5, 10]
        to ensure comfortable clearance for brims/tabs.

   [ STANDARD FEATURES ]
   - Detailed Labels & Debug Output.
   - Anchored Dovetails & Reinforced Joiners.
   - Slicer Import Guide.

   ========================================================================
   [ SLICER IMPORT INSTRUCTIONS (Bambu / Prusa) ]
   1. EXPORT:
      - Select 'White Base' in Customizer -> Render (F6) -> Export STL.
      - Select 'Black Pattern' in Customizer -> Render (F6) -> Export STL.
      - (Repeat for every Part Index required).

   2. IMPORT:
      - Drag BOTH files into the slicer window AT THE SAME TIME.
      - A dialog will appear: "Load as single object with multiple parts?"
      - Click YES (or "Multi-Part Object").

   3. SETUP:
      - You will see ONE object in the list with two sub-parts.
      - Assign Filament 1 (White) to the Base.
      - Assign Filament 2 (Black) to the Pattern.
   ======================================================================== */

// --- CUSTOMIZER PARAMETERS (MUST BE TOP LEVEL) --------------------------

/* [General Settings] */
// Select connection style. 
connection_type = "Smart Dovetail"; // [Smart Dovetail, Joiner Plate]

/* [Export Settings] */
// Controls which part of the assembly is shown/rendered.
export_mode = "Preview"; // [Preview, White Base, Black Pattern, Joiner Plate]

/* [Printer Configuration] */
// Select "Custom" to define your own bed size.
printer_model = "Prusa_XL"; // [Prusa_XL, Bambu_X1, Bambu_H2D, Prusa_MK4, Custom]

/* [Custom Printer Settings] */
// Width of your print bed (X-axis) in mm.
custom_print_width = 0; 
// Depth of your print bed (Y-axis) in mm.
custom_print_depth = 0; 

/* [Render Selection] */
// Which split section of the board to render (starts at 1).
part_index = 1; 

/* [Geometry Settings] */
sq_size = 30;         // Grid Square size (mm)
marker_size = 22;     // Marker size (mm) - leaves 4mm black border
grid_size = 15;       // 15x15 Grid
border_size = 10;     // Border width (mm) around the chart

// Base thickness. 
// Default 4mm. Auto-increases if Joiner Plate is selected.
thickness = 4;        

// Depth of the black material flush surface (mm).
surface_layer = 0.6;  

/* [Label Settings] */
team_name = "5199"; 

/* [Dovetail Settings] */
// Only active if connection_type == "Smart Dovetail"
joint_len = 8;        
joint_base_w = 12;    
joint_tip_w = 16;     
// Clearance gap for fit. 0.1mm = Tight Snap.
tolerance = 0.1;      

/* [Joiner Plate Settings] */
// Only active if connection_type == "Joiner Plate"
plate_thickness = 3;  
plate_spacing = 50.8; 
plate_width = 20;     
plate_length = 60;    
screw_clearance_diam = 3.4; 
screw_head_diam = 7.0;
screw_pilot_diam = 2.0;

// --- LIBRARY IMPORT & VALIDATION ----------------------------------------

include <markers.scad>
assert(markers_loaded, "CRITICAL ERROR: 'markers.scad' is missing or outdated. Please run the Python generator script (V41+) to create the marker library.");

// --- 1. CALCULATIONS & LOGIC --------------------------------------------

total_board_w = (grid_size * sq_size) + (2 * border_size);
total_board_h = (grid_size * sq_size) + (2 * border_size);

effective_thickness = (connection_type == "Joiner Plate" && thickness <= 4) ? 9 : thickness;

label_base = str(grid_size, "x", grid_size, " Grid | ", sq_size, "mm Sq / ", marker_size, "mm Mrk | DICT_4X4_250 | ID Order: TL to BR");
full_label_text = (team_name == "") ? label_base : str(label_base, " | Team: ", team_name);

// --- CUT STRATEGY LOGIC ---
// [UPDATE V41] Thresholds bumped to account for ~8mm tab overhangs + brim.
// 265mm+ Bed -> Allows 8-square split (250mm body + tabs).
// <265mm Bed -> Forces 5-square split (160mm body + tabs).
function calc_cuts(dim) = (dim >= 265) ? [8] : [5, 10]; 

cut_config_xl    = [[8], [8]];          // 360mm bed: [8] is safe.
cut_config_bambu = [[5, 10], [5, 10]];  // 256mm bed: [5,10] is required.
cut_config_mk4   = [[5, 10], [5, 10]];  // 250mm bed: [5,10] is required.
cut_config_custom = (printer_model == "Custom") ? [calc_cuts(custom_print_width), calc_cuts(custom_print_depth)] : [[0],[0]]; 

config = (printer_model == "Prusa_MK4") ? cut_config_mk4 : 
         (printer_model == "Prusa_XL")  ? cut_config_xl :
         (printer_model == "Bambu_X1" || printer_model == "Bambu_H2D") ? cut_config_bambu :
         cut_config_custom;

cuts_x = config[0];
cuts_y = config[1];

function get_ranges(cx, cy, gs) = [
    for (y_i = [0 : len(cy)]) 
        for (x_i = [0 : len(cx)]) 
            [
                (x_i==0 ? 0 : cx[x_i-1]),
                (x_i==len(cx) ? gs : cx[x_i]),
                (y_i==0 ? 0 : cy[y_i-1]),
                (y_i==len(cy) ? gs : cy[y_i])
            ]
];

raw_parts = get_ranges(cuts_x, cuts_y, grid_size);
total_parts = len(raw_parts);

// --- 2. ERROR CHECKING --------------------------------------------------

is_custom_invalid = (printer_model == "Custom") && (custom_print_width <= 0 || custom_print_depth <= 0);
assert(!is_custom_invalid, "CRITICAL ERROR: Printer Model 'Custom' selected, but dimensions are 0.");
assert(!(connection_type == "Joiner Plate" && effective_thickness < 6), "WARNING: Joiner Plate mode requires thickness >= 6mm.");
assert(part_index > 0 && part_index <= total_parts, str("CRITICAL ERROR: Part Index ", part_index, " is out of range. Total Plates: ", total_parts));

// --- 3. CONSOLE DEBUGGING -----------------------------------------------
echo("=================================================");
echo("   CHARUCO GENERATOR - DEBUG OUTPUT (V41.0)      ");
echo("=================================================");
echo(str("[CONFIG] Connection  : ", connection_type));
echo(str("[CONFIG] Board Thick : ", effective_thickness, " mm"));
echo(str("[INFO]   Total Plates Required : ", total_parts));
echo(str("[INFO]   Cut Strategy X        : ", cuts_x));
echo(str("[INFO]   Cut Strategy Y        : ", cuts_y));

// Layout Indication
echo("-------------------------------------------------");
echo("[INFO] GRID LAYOUT MAPPING:");
echo("   - Origin (Row 0, Col 0): TOP-LEFT Corner.");
echo("   - Square (0,0): Solid Black (Even Sum).");
echo("   - First Marker (ID 0): Located at Row 0, Col 1.");
echo("   - Index Order: Left-to-Right, then Top-to-Bottom.");

// Label Content Verification
echo("-------------------------------------------------");
echo(str("[INFO]   Label Text            : ", full_label_text));

// Slicer Instructions
echo("-------------------------------------------------");
echo("[GUIDE] SLICER IMPORT INSTRUCTIONS:");
echo("   1. Export 'White Base' & 'Black Pattern' STLs.");
echo("   2. Drag BOTH files into Slicer AT THE SAME TIME.");
echo("   3. Answer YES to 'Load as single object with multiple parts?'.");
echo("   4. Assign Colors: Part 1 = White, Part 2 = Black.");
echo("-------------------------------------------------");

if (part_index <= total_parts) {
    echo(str("[INFO]   Rendering Part Index  : ", part_index));
}
echo("=================================================");

// --- 4. PART MAPPING ----------------------------------------------------

map_idx = (total_parts == 4) ? [2, 3, 0, 1] : [ for (i = [0 : total_parts-1]) i ];
valid_index = (part_index > 0 && part_index <= total_parts) ? part_index : 1;
current_part = raw_parts[map_idx[valid_index - 1]];

p_xs = current_part[0]; p_xe = current_part[1];
p_ys = current_part[2]; p_ye = current_part[3];

is_left_edge   = (p_xs == 0);
is_right_edge  = (p_xe == grid_size);
is_bottom_edge = (p_ys == 0);
is_top_edge    = (p_ye == grid_size);

has_seam_x = (!is_right_edge); 
has_seam_y = (!is_top_edge);   
has_slot_x = (!is_left_edge);  
has_slot_y = (!is_bottom_edge);

// --- 5. SMART INDEXING --------------------------------------------------
function get_dual_smart_indices(fixed_coord, range_start, range_end) = 
    let (
        len = range_end - range_start,
        t1 = range_start + floor(len / 3),
        t2 = range_start + floor(2 * len / 3),
        idx1 = ((fixed_coord + t1) % 2 == 0) ? t1 : t1 + 1,
        idx2 = ((fixed_coord + t2) % 2 == 0) ? t2 : t2 + 1
    )
    [ 
      (idx1 < range_end) ? idx1 : range_start, 
      (idx2 < range_end && idx2 != idx1) ? idx2 : (idx1 + 2 < range_end ? idx1+2 : range_start)
    ];

smart_indices_y_tab  = get_dual_smart_indices(p_xe, p_ys, p_ye); 
smart_indices_y_slot = get_dual_smart_indices(p_xs, p_ys, p_ye); 
smart_indices_x_tab  = get_dual_smart_indices(p_ye, p_xs, p_xe); 
smart_indices_x_slot = get_dual_smart_indices(p_ys, p_xs, p_xe);

if (connection_type == "Smart Dovetail") {
    if (has_seam_x) echo(str("[DEBUG] Right Tabs at Rows: ", smart_indices_y_tab));
    if (has_slot_x) echo(str("[DEBUG] Left Slots at Rows: ", smart_indices_y_slot));
}

// --- MODULES ------------------------------------------------------------

module dovetail_shape(clearance=0, cut_depth=0, height=effective_thickness+1) {
    bw = joint_base_w - 2 * clearance;
    tw = joint_tip_w - 2 * clearance;
    linear_extrude(height)
        polygon(points=[
            [-bw/2, -cut_depth], [-tw/2, joint_len], 
            [tw/2, joint_len], [bw/2, -cut_depth]
        ]);
}

module plate_geometry(is_cutout=false) {
    tol = is_cutout ? 0.2 : 0;
    hole_d = screw_clearance_diam;
    head_d = screw_head_diam;
    sink_h = (head_d - hole_d) / 2;
    th = plate_thickness;
    
    difference() {
        translate([-plate_width/2 - tol, -plate_length/2 - tol, 0])
            cube([plate_width + 2*tol, plate_length + 2*tol, th]);
        
        if (!is_cutout) {
            translate([0, plate_length/4, -1]) {
                cylinder(h=th+2, d=hole_d, $fn=20);
                translate([0, 0, th - sink_h + 1]) cylinder(h=sink_h, d1=hole_d, d2=head_d, $fn=20);
            }
            translate([0, -plate_length/4, -1]) {
                cylinder(h=th+2, d=hole_d, $fn=20);
                translate([0, 0, th - sink_h + 1]) cylinder(h=sink_h, d1=hole_d, d2=head_d, $fn=20);
            }
        }
    }
}

module joiner_pockets_and_pilots(w, h) {
    module place_pocket() {
        translate([0,0,-0.01]) plate_geometry(is_cutout=true);
        translate([0, plate_length/4, -5]) cylinder(h=10, d=screw_pilot_diam, $fn=20);
        translate([0, -plate_length/4, -5]) cylinder(h=10, d=screw_pilot_diam, $fn=20);
    }
    if (has_seam_x) for (y = [0 : plate_spacing : h]) if (y > 15 && y < h-15) 
        translate([w, y, 0]) rotate([0,0,90]) place_pocket();
    if (has_slot_x) for (y = [0 : plate_spacing : h]) if (y > 15 && y < h-15) 
        translate([0, y, 0]) rotate([0,0,90]) place_pocket();
    if (has_seam_y) for (x = [0 : plate_spacing : w]) if (x > 15 && x < w-15) 
        translate([x, h, 0]) place_pocket();
    if (has_slot_y) for (x = [0 : plate_spacing : w]) if (x > 15 && x < w-15) 
        translate([x, 0, 0]) place_pocket();
}

module reinforcement_bosses(w, h) {
    module solid_boss() { cylinder(h=effective_thickness, d=10, $fn=20); }
    if (has_seam_x) for (y = [0 : plate_spacing : h]) if (y > 15 && y < h-15) 
        translate([w, y, 0]) rotate([0,0,90]) translate([0, plate_length/4, 0]) solid_boss();
    if (has_slot_x) for (y = [0 : plate_spacing : h]) if (y > 15 && y < h-15) 
        translate([0, y, 0]) rotate([0,0,90]) translate([0, -plate_length/4, 0]) solid_boss();
    if (has_seam_y) for (x = [0 : plate_spacing : w]) if (x > 15 && x < w-15) 
        translate([x, h, 0]) translate([0, -plate_length/4, 0]) solid_boss();
    if (has_slot_y) for (x = [0 : plate_spacing : w]) if (x > 15 && x < w-15) 
        translate([x, 0, 0]) translate([0, plate_length/4, 0]) solid_boss();
}

// --- MAIN RENDER MODULE -------------------------------------------------

module render_part() {
    width_sq = p_xe - p_xs;
    height_sq = p_ye - p_ys;
    inner_w = width_sq * sq_size;
    inner_h = height_sq * sq_size;
    
    add_b_left   = is_left_edge ? border_size : 0;
    add_b_right  = is_right_edge ? border_size : 0;
    add_b_bottom = is_bottom_edge ? border_size : 0;
    add_b_top    = is_top_edge ? border_size : 0;
    
    total_w = inner_w + add_b_left + add_b_right;
    total_h = inner_h + add_b_bottom + add_b_top;
    
    // --- COMPONENT 1: WHITE BASE ---
    if (export_mode == "White Base" || export_mode == "Preview") {
        color("white") difference() {
            // A. Base
            union() {
                translate([-add_b_left, -add_b_bottom, 0]) 
                    cube([total_w, total_h, effective_thickness]);
                if (connection_type == "Joiner Plate") reinforcement_bosses(inner_w, inner_h);
                
                // Add Male Dovetail Tabs (Anchored overlap 0.2mm)
                if (connection_type == "Smart Dovetail") {
                    if (has_seam_x) {
                        for (row_idx = smart_indices_y_tab) {
                            y_rel = (row_idx - p_ys) * sq_size + sq_size/2;
                            translate([inner_w, y_rel, 0]) rotate([0, 0, -90]) dovetail_shape(clearance = 0, cut_depth = 0.2, height = effective_thickness - surface_layer);
                        }
                    }
                    if (has_seam_y) {
                        for (col_idx = smart_indices_x_tab) {
                            x_rel = (col_idx - p_xs) * sq_size + sq_size/2;
                            translate([x_rel, inner_h, 0]) dovetail_shape(clearance = 0, cut_depth = 0.2, height = effective_thickness - surface_layer);
                        }
                    }
                }
            }

            // B. Grid
            for (x = [0 : width_sq - 1]) {
                for (y = [0 : height_sq - 1]) {
                    global_x = p_xs + x;
                    global_y = p_ys + y;
                    
                    if ((global_x + global_y) % 2 == 0) { // Solid Black
                        translate([x * sq_size, y * sq_size, effective_thickness - surface_layer])
                            cube([sq_size, sq_size, surface_layer + 0.1]);
                    }
                    if ((global_x + global_y) % 2 == 1) { // Marker
                        row_from_top = (grid_size - 1) - global_y;
                        index = row_from_top * grid_size + global_x;
                        id = floor(index / 2);
                        offset = (sq_size - marker_size) / 2;
                        translate([x * sq_size + offset, y * sq_size + offset, effective_thickness - surface_layer]) {
                            difference() {
                                cube([marker_size, marker_size, surface_layer + 0.01]);
                                translate([0, 0, -0.1]) scale([marker_size/6, marker_size/6, 1]) linear_extrude(1.0) draw_marker(id);
                            }
                        }
                    }
                }
            }
            
            // C. Connections
            if (connection_type == "Joiner Plate") {
                joiner_pockets_and_pilots(inner_w, inner_h);
            }
            if (connection_type == "Smart Dovetail") {
                 if (has_slot_x) { 
                     for (row_idx = smart_indices_y_slot) {
                         y_rel = (row_idx - p_ys) * sq_size + sq_size/2;
                         translate([0, y_rel, -0.5]) rotate([0, 0, -90]) dovetail_shape(clearance = -tolerance, cut_depth = 1.0, height = effective_thickness + 1); 
                     }
                 }
                 if (has_slot_y) { 
                     for (col_idx = smart_indices_x_slot) {
                         x_rel = (col_idx - p_xs) * sq_size + sq_size/2;
                         translate([x_rel, 0, -0.5]) dovetail_shape(clearance = -tolerance, cut_depth = 1.0, height = effective_thickness + 1);
                     }
                 }
            }
            
            // D. Label (Centered in Bottom Border)
            if (is_bottom_edge && is_left_edge) { 
                 echo("[INFO] Generating Text Label on this part (Bottom-Left).");
                 translate([5, -border_size/2, effective_thickness - 0.6])
                    linear_extrude(1.0)
                    text(full_label_text, size=3.5, font="Arial:style=Bold", valign="center");
            }
        }
    }

    // --- COMPONENT 2: BLACK PATTERN ---
    if (export_mode == "Black Pattern" || export_mode == "Preview") {
        color("black") union() { 
            difference() {
                union() {
                    for (x = [0 : width_sq - 1]) {
                        for (y = [0 : height_sq - 1]) {
                            global_x = p_xs + x;
                            global_y = p_ys + y;
                            
                            if ((global_x + global_y) % 2 == 0) { // Solid Black
                                translate([x * sq_size, y * sq_size, effective_thickness - surface_layer])
                                    cube([sq_size, sq_size, surface_layer]);
                            }
                            if ((global_x + global_y) % 2 == 1) { // Marker
                                row_from_top = (grid_size - 1) - global_y;
                                index = row_from_top * grid_size + global_x;
                                id = floor(index / 2);
                                offset = (sq_size - marker_size) / 2;
                                translate([x * sq_size + offset, y * sq_size + offset, effective_thickness - surface_layer]) {
                                    difference() {
                                        cube([marker_size, marker_size, surface_layer]);
                                        translate([0, 0, -0.1]) scale([marker_size/6, marker_size/6, 1]) linear_extrude(1.0) draw_marker(id);
                                    }
                                }
                            }
                        }
                    }
                    
                    // Add Tab Caps (Mode A) to Union (Anchored 0.2mm)
                    if (connection_type == "Smart Dovetail") {
                        if (has_seam_x) {
                            for (row_idx = smart_indices_y_tab) {
                                y_rel = (row_idx - p_ys) * sq_size + sq_size/2;
                                translate([inner_w, y_rel, effective_thickness - surface_layer]) rotate([0, 0, -90]) dovetail_shape(clearance = 0, cut_depth = 0.2, height = surface_layer);
                            }
                        }
                        if (has_seam_y) {
                            for (col_idx = smart_indices_x_tab) {
                                x_rel = (col_idx - p_xs) * sq_size + sq_size/2;
                                translate([x_rel, inner_h, effective_thickness - surface_layer]) dovetail_shape(clearance = 0, cut_depth = 0.2, height = surface_layer);
                            }
                        }
                    }
                }
                
                // Subtract Slots from Black Layer (Top Opening Fix)
                if (connection_type == "Smart Dovetail") {
                     if (has_slot_x) { 
                         for (row_idx = smart_indices_y_slot) {
                             y_rel = (row_idx - p_ys) * sq_size + sq_size/2;
                             translate([0, y_rel, -0.5]) rotate([0, 0, -90]) dovetail_shape(clearance = -tolerance, cut_depth = 1.0, height = effective_thickness + 1); 
                         }
                     }
                     if (has_slot_y) { 
                         for (col_idx = smart_indices_x_slot) {
                             x_rel = (col_idx - p_xs) * sq_size + sq_size/2;
                             translate([x_rel, 0, -0.5]) dovetail_shape(clearance = -tolerance, cut_depth = 1.0, height = effective_thickness + 1);
                         }
                     }
                }
            } // End Difference
        }
    }
    
    // --- COMPONENT 3: JOINER PLATE PREVIEW ---
    if (export_mode == "Joiner Plate") {
        color("gray") plate_geometry(is_cutout=false);
    }
    if (export_mode == "Preview" && connection_type == "Joiner Plate") {
        color("gray") translate([0,0,-0.05]) {
            if (has_seam_x) for (y = [0 : plate_spacing : inner_h]) if (y > 15 && y < inner_h-15) 
                translate([inner_w, y, 0]) rotate([0,0,90]) plate_geometry();
            if (has_slot_x) for (y = [0 : plate_spacing : inner_h]) if (y > 15 && y < inner_h-15) 
                translate([0, y, 0]) rotate([0,0,90]) plate_geometry();
            if (has_seam_y) for (x = [0 : plate_spacing : inner_w]) if (x > 15 && x < inner_w-15) 
                translate([x, inner_h, 0]) plate_geometry();
            if (has_slot_y) for (x = [0 : plate_spacing : inner_w]) if (x > 15 && x < inner_w-15) 
                translate([x, 0, 0]) plate_geometry();
        }
    }
}

render_part();

