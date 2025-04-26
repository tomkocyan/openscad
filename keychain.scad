// Loading SVG file and converting it to 3D model
// Note: SVG file must be in the same directory as this SCAD file
// or you need to specify the full path to the file

// Icon parameters
icon_filename = "icons/envelope-solid.svg"; // Name of the SVG icon file
max_size = 30; // Maximum size of the image in mm

// Height parameters
extrusion_height = 2; // Height of the main extrusion in mm
rim_height = 1; // Height of the rim in mm

// Eyelet parameters
eyelet_diameter = 6; // Diameter of the keyring hole in mm
eyelet_thickness = 2; // Thickness of the eyelet in mm
eyelet_strength = 3; // Strength (thickness) of the eyelet material in mm
eyelet_smoothness = 50; // Smoothness of the eyelet (higher = smoother)

// Eyelet position parameters
eyelet_x = max_size / 2; // X position of the eyelet in mm
eyelet_y = 36; // Y position of the eyelet in mm
eyelet_z = 0; // Z position of the eyelet in mm

// Main icon with rim and eyelet
union() {
    // Solid base layer using hull (white)
    color("white") linear_extrude(height = rim_height) {
        hull() {
            resize([max_size, max_size, 0], auto=true) {
                import(icon_filename);
            }
        }
    }
    
    // Main icon (raised part - blue)
    color("blue") translate([0, 0, rim_height]) {
        linear_extrude(height = extrusion_height - rim_height) {
            resize([max_size, max_size, 0], auto=true) {
                import(icon_filename);
            }
        }
    }
    
    // Eyelet for keyring (blue)
    color("blue") translate([eyelet_x, eyelet_y, eyelet_z]) {
        difference() {
            // Outer ring
            cylinder(h=eyelet_thickness, d=eyelet_diameter + eyelet_strength*2, $fn=eyelet_smoothness);
            // Inner hole
            translate([0, 0, -0.1])
                cylinder(h=eyelet_thickness + 0.2, d=eyelet_diameter, $fn=eyelet_smoothness);
        }
    }
}

// You can modify:
// Icon parameters:
// - icon by changing the icon_filename parameter
// - maximum size by changing the max_size parameter
//
// Height parameters:
// - main height by changing the extrusion_height parameter
// - rim height by changing the rim_height parameter
//
// Eyelet parameters:
// - eyelet size by changing eyelet_diameter
// - eyelet thickness by changing eyelet_thickness
// - eyelet strength by changing eyelet_strength
// - eyelet smoothness by changing eyelet_smoothness
//
// Position parameters:
// - eyelet position by changing eyelet_x, eyelet_y, and eyelet_z
//
// Additional options:
// - add additional transformations (rotate, scale, translate) 