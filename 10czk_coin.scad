// 10 CZK coin model

// ===== DIMENSIONS =====
COIN_DIAMETER = 24.5;  // mm
COIN_THICKNESS = 2.55; // mm
EDGE_WIDTH = 1;        // mm (difference between outer and inner diameter)

// ===== TEXT =====
TEXT_SIZE = 15;        // mm
TEXT_HEIGHT = 0.3;     // mm
TEXT_FONT = "Arial Rounded MT Bold";
TEXT_SPACING = 0.7;    // spacing between characters (1.0 is normal)
TEXT_OFFSET = -1.5;    // mm offset for better centering

// ===== RENDERING =====
$fn = 100; // High resolution for smooth edges

module coin() {
    // Main coin body
    cylinder(h = COIN_THICKNESS, d = COIN_DIAMETER, center = true);
    
    // Raised edge
    translate([0, 0, COIN_THICKNESS/2])
    linear_extrude(height = TEXT_HEIGHT)
    difference() {
        circle(d = COIN_DIAMETER);
        circle(d = COIN_DIAMETER - (EDGE_WIDTH * 2));
    }
    
    // Add the number 10
    translate([TEXT_OFFSET, 0, COIN_THICKNESS/2])
    linear_extrude(height = TEXT_HEIGHT)
    text("10", size = TEXT_SIZE, font = TEXT_FONT, spacing = TEXT_SPACING, halign = "center", valign = "center");
}

// Render the coin
coin(); 