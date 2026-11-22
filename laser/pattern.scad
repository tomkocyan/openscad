// Rozmístí 2D tvar po obdélníku. O laseru ani o krabičce nic neví.
// Jednotky jsou milimetry. Souřadnice jdou od levého dolního rohu plochy.
//
// shape: circle, square, diamond, slot, svg
// svg: cesta k souboru, když je shape "svg". OpenSCAD ji bere vůči
// souboru, který otevíráš, ne vůči této knihovně.
// pitch je rozteč středů v mm. count 0 znamená „kolik se vejde“.
// stagger: none, horizontal, vertical, both. Posun je vždy půl rozteče.
// rotate_step otáčí každý další kus ve stupních.

module pattern_tile(shape, svg, size) {
    if (shape == "square")
        square([size, size], center = true);
    else if (shape == "slot") {
        radius = min(size * 0.28, size / 2);
        hull() {
            translate([-size / 2 + radius, 0])
                circle(r = radius);
            translate([size / 2 - radius, 0])
                circle(r = radius);
        }
    } else if (shape == "diamond")
        polygon([[0, size / 2], [size / 2, 0], [0, -size / 2], [-size / 2, 0]]);
    else if (shape == "svg" && len(svg) > 0)
        resize([size, size], auto = true)
            import(svg, center = true);
    else if (shape != "svg")
        circle(d = size);
}

// Plocha, do které se vzor vejde. round zkulatí rohy o corner_radius.
module pattern_bounds(width, height, margin = 0, corners = "sharp", corner_radius = 0) {
    $fn = 32;
    w = width - 2 * margin;
    h = height - 2 * margin;
    radius = corners == "round" ? min(max(corner_radius, 0), min(w, h) / 2) : 0;
    if (w > 0 && h > 0)
        translate([margin, margin])
            if (radius > 0)
                translate([radius, radius])
                    offset(r = radius)
                        square([max(w - 2 * radius, 0.01), max(h - 2 * radius, 0.01)]);
            else
                square([w, h]);
}

module pattern_grid(
    width,
    height,
    shape = "circle",
    svg = "",
    size = 8,
    margin = 6,
    pitch_x = 16,
    pitch_y = 16,
    stagger = "none",
    rotate_step = 0,
    count_x = 0,
    count_y = 0,
    clip = "fit",
    corners = "sharp",
    corner_radius = 0
) {
    $fn = 32;
    usable_w = width - 2 * margin;
    usable_h = height - 2 * margin;
    step_x = max(pitch_x, 0.1);
    step_y = max(pitch_y, 0.1);
    extra_x = (stagger == "horizontal" || stagger == "both") ? step_x / 2 : 0;
    extra_y = (stagger == "vertical" || stagger == "both") ? step_y / 2 : 0;
    clipping = clip == "clip";

    module cells(cols, rows, x0, y0, keep_inside) {
        if (cols > 0 && rows > 0)
            for (r = [0 : rows - 1])
                for (c = [0 : cols - 1]) {
                    shift_x = extra_x > 0 && r % 2 == 1 ? extra_x : 0;
                    shift_y = extra_y > 0 && c % 2 == 1 ? extra_y : 0;
                    x = x0 + c * step_x + shift_x;
                    y = y0 + r * step_y + shift_y;
                    if (!keep_inside
                        || (x - size / 2 >= margin - 0.01
                            && x + size / 2 <= width - margin + 0.01
                            && y - size / 2 >= margin - 0.01
                            && y + size / 2 <= height - margin + 0.01))
                        translate([x, y])
                            rotate((r * cols + c) * rotate_step)
                                pattern_tile(shape, svg, size);
                }
    }

    if (usable_w > 0 && usable_h > 0 && size > 0) {
        if (clipping) {
            // Základní mřížka (bez posunu) má střed uprostřed plochy.
            // Posun o půl rozteče je pak souměrný podle toho středu a ořez
            // sedí naproti sobě. U svislého posunu musí být sloupců lichý
            // počet, u vodorovného řad, jinak se sudé a liché řady po
            // otočení nesejdou.
            raw_cols = count_x > 0 ? count_x : ceil((usable_w + size) / step_x) + 1;
            raw_rows = count_y > 0 ? count_y : ceil((usable_h + size) / step_y) + 1;
            cols = extra_y > 0 && raw_cols % 2 == 0 ? raw_cols + 1 : raw_cols;
            rows = extra_x > 0 && raw_rows % 2 == 0 ? raw_rows + 1 : raw_rows;
            intersection() {
                cells(
                    cols, rows,
                    margin + usable_w / 2 - (cols - 1) * step_x / 2,
                    margin + usable_h / 2 - (rows - 1) * step_y / 2,
                    false
                );
                pattern_bounds(width, height, margin, corners, corner_radius);
            }
        } else if (usable_w >= size && usable_h >= size) {
            fit_cols = floor((usable_w - size - extra_x) / step_x + 1.0001);
            fit_rows = floor((usable_h - size - extra_y) / step_y + 1.0001);
            cols = count_x > 0 ? count_x : max(0, fit_cols);
            rows = count_y > 0 ? count_y : max(0, fit_rows);
            span_x = (cols - 1) * step_x + extra_x + size;
            span_y = (rows - 1) * step_y + extra_y + size;
            cells(
                cols, rows,
                margin + max(0, (usable_w - span_x) / 2) + size / 2,
                margin + max(0, (usable_h - span_y) / 2) + size / 2,
                true
            );
        }
    }
}
