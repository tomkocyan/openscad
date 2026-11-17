// 5 CZK coin model

// ===== DIMENSIONS =====
COIN_DIAMETER = 23;    // mm
COIN_THICKNESS = 1.85; // mm
EDGE_WIDTH = 1;        // mm (difference between outer and inner diameter)

// ===== TEXT =====
TEXT_SIZE = 15;        // mm
TEXT_HEIGHT = 0.3;     // mm
TEXT_FONT = "Arial Rounded MT Bold";

// ===== COLORS =====
COLOR_BASE = "Silver";
COLOR_EDGE = "Black";
COLOR_TEXT = "Black";

// ===== RENDERING =====
$fn = 180; // High resolution for smooth edges

module coin() {
    // Main coin body
    color(COLOR_BASE)
    cylinder(h = COIN_THICKNESS, d = COIN_DIAMETER, center = true);
    
    // Raised edge
    color(COLOR_EDGE)
    translate([0, 0, COIN_THICKNESS/2])
    linear_extrude(height = TEXT_HEIGHT)
    difference() {
        circle(d = COIN_DIAMETER);
        circle(d = COIN_DIAMETER - (EDGE_WIDTH * 2));
    }
    
    // Add the number 5
    color(COLOR_TEXT)
    translate([0, 0, COIN_THICKNESS/2])
    linear_extrude(height = TEXT_HEIGHT)
    text("5", size = TEXT_SIZE, font = TEXT_FONT, halign = "center", valign = "center");
}

// Render the coin
coin(); 