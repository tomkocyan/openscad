// Otevřená krabička pro laserové řezání překližky. Jednotky jsou milimetry.
// Rozměry jsou vnější. Dno a čtyři stěny drží prstové spoje.
// floor_raise 0 položí dno na zem. Vyšší hodnota nechá stěny pokračovat pod dno.
// Víčko je vypnuté. Zapnuté má lem: vnější přes krabici, vnitřní dovnitř.
//
// Na desce jsou dva čelní díly, dva boky a dno. Bez vzoru jsou čela stejná a boky taky.
// Zapni rozložení a exportuj DXF nebo SVG. Vypni ho, když chceš 3D náhled.
// Červená je řez. V náhledu je gravír modrá a reliéf zelený, obojí leží na stěně.
// Do výkresu se plošný vzor dá vpravo od dílů, ať ho řez nepohltí. Posun na díl
// a vrstva gravírování jsou v logu.
//
// Kerf, tloušťka a proč víčko lepit jsou v settings.scad. Tady to neměň.

include <settings.scad>

/* [Vnější rozměry] */
// Celková šířka přes stěny, směr X, v mm
outer_width = 100; // [30:1:500]

// Celková hloubka přes stěny, směr Y, v mm
outer_depth = 80; // [30:1:500]

// Celková výška stěn, v mm. Shora je krabička otevřená.
outer_height = 50; // [15:1:400]

// Spodní hrana dna nad zemí. 0 = dno je úplně dole. Nad nulou stěny pokračují pod dno.
floor_raise = 0; // [0:1:80]

/* [Prsty] */
// Cílová šířka prstu v mm. Skutečná vyjde tak, aby jich na hraně byl lichý počet.
finger_width = 10; // [4:0.5:30]

/* [Náhled] */
// Díly rozložené na desce. Vypni pro složenou krabičku.
flat_layout = true;

/* [Díly] */
// Čelo. Vypni, co teď neladíš, ať se to zbytečně nepočítá.
show_front = true;

// Záda
show_back = true;

// Levý bok
show_left = true;

// Pravý bok
show_right = true;

// Dno
show_bottom = true;

// Víčko. Kreslí se jen když je režim víčka zapnutý.
show_lid = true;

/* [Víčko] */
// Zapne víčko.
lid_enabled = false;

// outer = lem zvenku přes stěny, inner = lem zajede dovnitř a deska sedí na hraně
lid_fit = "outer"; // [outer, inner]

// Jak hluboko lem zajede, v mm. Deska víčka je navíc o tloušťku materiálu.
lid_depth = 12; // [4:1:60]

// Vůle na každou stranu, v mm. Aby víčko šlo nasadit.
lid_clearance = 0.3; // [0:0.05:2]

// O kolik mm je otvor pro prst víčka užší než deska. 0 = stejné jako krabička.
lid_press = 0; // [0:0.01:0.2]

// Jen složený náhled. Víčko zvedne nad krabičku, ať je vidět lem. Výkres se nemění.
lid_raised = false;

/* [Vzor] */
// Vypnutý vzor se neřeže ani negravíruje.
pattern_enabled = false;

// hole = díra skrz, engrave = gravír tvaru, emboss = reliéf (vypálí se okolí)
pattern_op = "hole"; // [hole, engrave, emboss]

// circle, square, diamond, slot, nebo svg
pattern_shape = "circle"; // [circle, square, diamond, slot, svg]

// Cesta k SVG, když je tvar svg. Vůči souboru krabičky.
pattern_svg = "";

// Velikost jednoho tvaru v mm
pattern_size = 8; // [2:0.5:40]

// Okraj vzoru od prstů a od hrany stěny v mm
pattern_margin = 6; // [0:0.5:30]

// fit = jen celé tvary uvnitř okraje, clip = opakuje se a ořízne bounding boxem
pattern_clip = "fit"; // [fit, clip]

// sharp = ostré rohy, round = zaoblené. Platí pro ořez a pro plochu reliéfu.
pattern_box_corners = "sharp"; // [sharp, round]

// Poloměr zaoblení bounding boxu v mm. Platí při round.
pattern_box_radius = 4; // [0:0.5:40]

// Rozteč středů ve směru X v mm
pattern_pitch_x = 16; // [4:0.5:80]

// Rozteč středů ve směru Y v mm
pattern_pitch_y = 16; // [4:0.5:80]

// none = mřížka, horizontal = sudé řady, vertical = sudé sloupce, both = obojí, vždy o půl rozteče
pattern_stagger = "none"; // [none, horizontal, vertical, both]

// Otočení každého dalšího kusu ve stupních
pattern_rotate_step = 0; // [0:5:180]

// Počet kusů ve směru X. 0 = kolik se vejde.
pattern_count_x = 0; // [0:1:30]

// Počet kusů ve směru Y. 0 = kolik se vejde.
pattern_count_y = 0; // [0:1:30]

// Hloubka gravíru, nebo o kolik reliéf vystoupí nad vypálené okolí, v mm
pattern_depth = 0.4; // [0.1:0.1:2]

// Stěny, na které se vzor položí. Čelo a záda jsou zvenku, dno zevnitř.
pattern_front = true;
pattern_back = false;
pattern_left = false;
pattern_right = false;
pattern_bottom = false;

/* [Hidden] */

use <pattern.scad>

function inner_width() = outer_width - 2 * thickness;
function inner_depth() = outer_depth - 2 * thickness;
function inner_height() = outer_height - thickness - floor_raise;

// Svislé prsty jedou po celé stěně, když je dno vyvýšené. Jinak začínají nad dnem.
function corner_length() = floor_raise > 0 ? outer_height : inner_height();

// Vzor leží na desce nad dnem, ne na prstech.
function wall_pattern_height() = inner_height();

function wall_pattern_y() = floor_raise + thickness;

function lid_on() = lid_enabled && show_lid;

// Otvor ve víčku je o lid_press užší než deska, ať lem drží i zavěšený.
function lid_joint() = thickness - lid_press;

// Jen složený náhled. Lem zůstane nad hranou krabičky, ať je vidět vůle.
function lid_preview_lift() =
    lid_on() && lid_raised ? lid_depth + max(30, outer_height * 0.35) : 0;

function lid_wall_h() = lid_depth + thickness;

// Půdorys vnějšího víčka včetně jeho stěn.
function lid_outer_w() = outer_width + 2 * lid_clearance + 2 * thickness;
function lid_outer_d() = outer_depth + 2 * lid_clearance + 2 * thickness;

// Vnitřní lem je menší než otvor krabice o vůli na každé straně.
function skirt_w() = inner_width() - 2 * lid_clearance;
function skirt_d() = inner_depth() - 2 * lid_clearance;

// Víčko na desce začíná pod dnem, ať se s ním neslije do jednoho řezu.
function lid_sheet_x() = sheet_margin;
function lid_sheet_y() = sheet_margin + outer_height + part_gap + outer_depth + part_gap;

function lid_sheet_w() =
    let (
        outer = lid_fit == "outer",
        width = outer ? lid_outer_w() : skirt_w(),
        plate_w = outer ? width : outer_width
    )
    plate_w + 2 * (width + part_gap);

function lid_sheet_h() =
    let (
        outer = lid_fit == "outer",
        depth = outer ? lid_outer_d() : skirt_d(),
        plate_d = outer ? depth : outer_depth
    )
    max(plate_d, lid_wall_h()) + part_gap + lid_wall_h();

function show_part(face) =
    face == "front" ? show_front
    : face == "back" ? show_back
    : face == "left" ? show_left
    : face == "right" ? show_right
    : face == "bottom" ? show_bottom
    : false;

function part_pos(face) =
    let (
        front_w = outer_width,
        front_h = outer_height,
        side_w = outer_depth
    )
    face == "back" ? [sheet_margin + front_w + part_gap, sheet_margin]
    : face == "left" ? [sheet_margin + 2 * (front_w + part_gap), sheet_margin]
    : face == "right"
        ? [sheet_margin + 2 * (front_w + part_gap) + side_w + part_gap, sheet_margin]
    : face == "bottom" ? [sheet_margin, sheet_margin + front_h + part_gap]
    : [sheet_margin, sheet_margin];

function part_size(face) =
    face == "left" || face == "right" ? [outer_depth, outer_height]
    : face == "bottom" ? [outer_width, outer_depth]
    : [outer_width, outer_height];

shown_parts = [
    if (show_front) "front",
    if (show_back) "back",
    if (show_left) "left",
    if (show_right) "right",
    if (show_bottom) "bottom"
];

view_parts = len(shown_parts) > 0 ? shown_parts : ["front"];

// Lichý počet, oba konce hrany jsou stejný typ prstu a rohy se nebijí.
function segment_count(length) =
    let(count = max(3, round(length / finger_width)))
    (count % 2 == 0) ? count + 1 : count;

function segment_size(length) = length / segment_count(length);

function is_tab(index, tabs_at_ends) =
    tabs_at_ends ? (index % 2 == 0) : (index % 2 == 1);

// Prsty podél hrany. Svislé jedou po Y a trčí do +X, vodorovné po X do +Y.
// Vůle ubírá prst jen na styčné hraně. Krajní prst zůstává v rohu do plné délky.
module tabs(length, depth, vertical, tabs_at_ends) {
    count = segment_count(length);
    seg = length / count;
    inset = min(joint_clearance / 4, seg * 0.15);

    for (i = [0 : count - 1])
        if (is_tab(i, tabs_at_ends)) {
            inset_start = i == 0 ? 0 : inset;
            inset_end = i == count - 1 ? 0 : inset;
            at = i * seg + inset_start;
            span = seg - inset_start - inset_end;
            if (vertical)
                translate([0, at])
                    square([depth, span]);
            else
                translate([at, 0])
                    square([span, depth]);
        }
}

// Otvory pro prsty dna. Plná šířka segmentu, prst je užší o vůli.
module finger_slots(length, depth, vertical, tabs_at_ends) {
    count = segment_count(length);
    seg = length / count;

    for (i = [0 : count - 1])
        if (is_tab(i, tabs_at_ends)) {
            if (vertical)
                translate([0, i * seg])
                    square([depth, seg]);
            else
                translate([i * seg, 0])
                    square([seg, depth]);
        }
}

function pattern_on(face) =
    pattern_enabled && (
        (face == "front" && pattern_front)
        || (face == "back" && pattern_back)
        || (face == "left" && pattern_left)
        || (face == "right" && pattern_right)
        || (face == "bottom" && pattern_bottom)
    );

module pattern_shapes(width, height) {
    pattern_grid(
        width, height,
        shape = pattern_shape,
        svg = pattern_svg,
        size = pattern_size,
        margin = pattern_margin,
        pitch_x = pattern_pitch_x,
        pitch_y = pattern_pitch_y,
        stagger = pattern_stagger,
        rotate_step = pattern_rotate_step,
        count_x = pattern_count_x,
        count_y = pattern_count_y,
        clip = pattern_clip,
        corners = pattern_box_corners,
        corner_radius = pattern_box_radius
    );
}

// Gravír je samotný tvar. Reliéf je plocha kolem tvaru, kterou laser vyplní.
module pattern_mark(width, height) {
    if (pattern_op == "emboss" && width > 2 * pattern_margin && height > 2 * pattern_margin)
        difference() {
            pattern_bounds(width, height, pattern_margin, pattern_box_corners, pattern_box_radius);
            pattern_shapes(width, height);
        }
    else if (pattern_op != "emboss")
        pattern_shapes(width, height);
}

module pattern_holes(width, height) {
    if (pattern_op == "hole")
        pattern_shapes(width, height);
}

// Čelo a záda mají stejný obrys, dokud na jednom z nich není vzor.
module front_panel_2d(face = "front") {
    difference() {
        union() {
            if (floor_raise > 0) {
                translate([thickness, 0])
                    square([inner_width(), outer_height]);
                tabs(outer_height, thickness, true, true);
                translate([outer_width - thickness, 0])
                    tabs(outer_height, thickness, true, true);
            } else {
                translate([thickness, thickness])
                    square([inner_width(), inner_height()]);
                tabs(outer_width, thickness, false, true);
                translate([0, thickness])
                    tabs(inner_height(), thickness, true, true);
                translate([outer_width - thickness, thickness])
                    tabs(inner_height(), thickness, true, true);
            }
        }
        if (floor_raise > 0)
            translate([0, floor_raise])
                finger_slots(outer_width, thickness, false, false);
        if (pattern_on(face))
            translate([thickness, wall_pattern_y()])
                pattern_holes(inner_width(), wall_pattern_height());
    }
}

// Bok sedí mezi čely. Svislé prsty jsou doplněk čela, roh dole patří čelu.
module side_panel_2d(face = "left") {
    difference() {
        union() {
            if (floor_raise > 0) {
                translate([thickness, 0])
                    square([inner_depth(), outer_height]);
                tabs(outer_height, thickness, true, false);
                translate([outer_depth - thickness, 0])
                    tabs(outer_height, thickness, true, false);
            } else {
                translate([thickness, thickness])
                    square([inner_depth(), inner_height()]);
                translate([0, thickness])
                    tabs(inner_height(), thickness, true, false);
                translate([outer_depth - thickness, thickness])
                    tabs(inner_height(), thickness, true, false);
                translate([thickness, 0])
                    tabs(inner_depth(), thickness, false, true);
            }
        }
        if (floor_raise > 0)
            translate([thickness, floor_raise])
                finger_slots(inner_depth(), thickness, false, false);
        if (pattern_on(face))
            translate([thickness, wall_pattern_y()])
                pattern_holes(inner_depth(), wall_pattern_height());
    }
}

// Lem víčka. Spodek 2D obrysu je volná hrana, nahoře jsou prsty do desky.
// Prsty se o kousek překrývají s tělem, ať z toho je jeden obrys a ne T-spoj.
// Otvor pro desku je lid_joint, užší než tloušťka, ať víčko drží.
module lid_front_wall_2d(width, wall_h) {
    seam = 0.02;
    joint = lid_joint();
    union() {
        translate([joint, 0])
            square([width - 2 * joint, wall_h - joint]);
        translate([0, wall_h - joint - seam])
            tabs(width, joint + seam, false, true);
        tabs(wall_h, joint, true, true);
        translate([width - joint, 0])
            tabs(wall_h, joint, true, true);
    }
}

module lid_side_wall_2d(depth, wall_h) {
    joint = lid_joint();
    inner = depth - 2 * joint;
    union() {
        translate([joint, 0])
            square([inner, wall_h - joint]);
        translate([joint, wall_h - joint])
            tabs(inner, joint, false, true);
        tabs(wall_h, joint, true, false);
        translate([depth - joint, 0])
            tabs(wall_h, joint, true, false);
    }
}

// Deska vnějšího víčka. Prsty jsou doplněk lemu.
module lid_plate_outer_2d(width, depth) {
    joint = lid_joint();
    union() {
        translate([joint, joint])
            square([width - 2 * joint, depth - 2 * joint]);
        tabs(width, joint, false, false);
        translate([0, depth - joint])
            tabs(width, joint, false, false);
        translate([0, joint])
            tabs(depth - 2 * joint, joint, true, false);
        translate([width - joint, joint])
            tabs(depth - 2 * joint, joint, true, false);
    }
}

// Deska vnitřního víčka leží na horní hraně. Zářezy drží lem uvnitř otvoru.
module lid_plate_inner_2d() {
    ox = thickness + lid_clearance;
    oy = thickness + lid_clearance;
    sw = skirt_w();
    sd = skirt_d();
    joint = lid_joint();
    pad = lid_press / 2;
    difference() {
        square([outer_width, outer_depth]);
        translate([ox, oy + pad])
            finger_slots(sw, joint, false, true);
        translate([ox, oy + sd - thickness + pad])
            finger_slots(sw, joint, false, true);
        translate([ox + pad, oy + thickness])
            finger_slots(sd - 2 * thickness, joint, true, true);
        translate([ox + sw - thickness + pad, oy + thickness])
            finger_slots(sd - 2 * thickness, joint, true, true);
    }
}

// Dno má prsty tam, kde má stěna zářez. Rohy drží spodní prsty čel.
module bottom_panel_2d() {
    difference() {
        union() {
            translate([thickness, thickness])
                square([inner_width(), inner_depth()]);
            tabs(outer_width, thickness, false, false);
            translate([0, outer_depth - thickness])
                tabs(outer_width, thickness, false, false);
            translate([0, thickness])
                tabs(inner_depth(), thickness, true, false);
            translate([outer_width - thickness, thickness])
                tabs(inner_depth(), thickness, true, false);
        }
        if (pattern_on("bottom"))
            translate([thickness, thickness])
                pattern_holes(inner_width(), inner_depth());
    }
}

function shows_surface(face) = pattern_on(face) && pattern_op != "hole";

function park_block(face) =
    shows_surface(face)
        ? (face == "bottom" ? outer_depth : outer_height) + part_gap
        : 0;

// OpenSCAD při exportu sloučí překrývající se plochy. Gravír a reliéf proto
// v náhledu leží na stěně a ve výkresu vpravo od dílů.
module surface_mark(width, height, origin_y, part_x, part_y, park_x, park_y, label) {
    color(pattern_op == "emboss" ? "#1a7a3a" : "#2255cc")
        translate([thickness, origin_y])
            pattern_mark(width, height);

    if (!$preview)
        echo(str("Vzor ", label, ": posuň o ", part_x - park_x,
            " mm v X a ", part_y - park_y, " mm v Y, pak nastav vrstvu gravír"));
}

module place_on_sheet() {
    front_w = outer_width;
    front_h = outer_height;
    side_w = outer_depth;
    park_x = sheet_margin + 2 * (front_w + part_gap) + 2 * side_w + 2 * part_gap;
    y_front = sheet_margin;
    y_back = y_front + park_block("front");
    y_left = y_back + park_block("back");
    y_right = y_left + park_block("left");
    y_bottom = y_right + park_block("right");

    module cut_at(x, y) {
        translate([x, y])
            laser_cut()
                children();
    }

    module mark_at(face, width, height, origin_y, part_x, part_y, park_y, label) {
        if (show_part(face) && shows_surface(face)) {
            pos = $preview ? [part_x, part_y] : [park_x, park_y];
            translate(pos)
                surface_mark(width, height, origin_y, part_x, part_y, park_x, park_y, label);
        }
    }

    if (show_part("front"))
        cut_at(part_pos("front")[0], part_pos("front")[1])
            front_panel_2d("front");
    if (show_part("back"))
        cut_at(part_pos("back")[0], part_pos("back")[1])
            front_panel_2d("back");
    if (show_part("left"))
        cut_at(part_pos("left")[0], part_pos("left")[1])
            side_panel_2d("left");
    if (show_part("right"))
        cut_at(part_pos("right")[0], part_pos("right")[1])
            side_panel_2d("right");
    if (show_part("bottom"))
        cut_at(part_pos("bottom")[0], part_pos("bottom")[1])
            bottom_panel_2d();

    if (lid_on())
        lid_on_sheet(lid_sheet_x(), lid_sheet_y());

    mark_at("front", inner_width(), wall_pattern_height(), wall_pattern_y(),
        part_pos("front")[0], part_pos("front")[1], y_front, "čela");
    mark_at("back", inner_width(), wall_pattern_height(), wall_pattern_y(),
        part_pos("back")[0], part_pos("back")[1], y_back, "záda");
    mark_at("left", inner_depth(), wall_pattern_height(), wall_pattern_y(),
        part_pos("left")[0], part_pos("left")[1], y_left, "levého boku");
    mark_at("right", inner_depth(), wall_pattern_height(), wall_pattern_y(),
        part_pos("right")[0], part_pos("right")[1], y_right, "pravého boku");
    mark_at("bottom", inner_width(), inner_depth(), thickness,
        part_pos("bottom")[0], part_pos("bottom")[1], y_bottom, "dna");
}

module lid_on_sheet(x0, y0) {
    wall_h = lid_wall_h();
    outer = lid_fit == "outer";
    width = outer ? lid_outer_w() : skirt_w();
    depth = outer ? lid_outer_d() : skirt_d();
    plate_w = outer ? width : outer_width;
    plate_d = outer ? depth : outer_depth;

    translate([x0, y0])
        laser_cut()
            if (outer)
                lid_plate_outer_2d(width, depth);
            else
                lid_plate_inner_2d();
    translate([x0 + plate_w + part_gap, y0])
        laser_cut()
            lid_front_wall_2d(width, wall_h);
    translate([x0 + plate_w + part_gap + width + part_gap, y0])
        laser_cut()
            lid_front_wall_2d(width, wall_h);
    translate([x0, y0 + max(plate_d, wall_h) + part_gap])
        laser_cut()
            lid_side_wall_2d(depth, wall_h);
    translate([x0 + depth + part_gap, y0 + max(plate_d, wall_h) + part_gap])
        laser_cut()
            lid_side_wall_2d(depth, wall_h);
}

module panel_3d() {
    linear_extrude(thickness, convexity = 8)
        nominal_outline()
            children();
}

// Kapsa z vnější strany stěny. U dna z vnitřní plochy, ať je vzor vidět shora.
module pattern_pocket(face) {
    depth = min(pattern_depth, thickness - 0.2);
    if (face == "front")
        translate([0, depth, 0])
            rotate([90, 0, 0])
                linear_extrude(depth, convexity = 8)
                    translate([thickness, wall_pattern_y()])
                        pattern_mark(inner_width(), wall_pattern_height());
    else if (face == "back")
        translate([0, outer_depth, 0])
            rotate([90, 0, 0])
                linear_extrude(depth, convexity = 8)
                    translate([thickness, wall_pattern_y()])
                        pattern_mark(inner_width(), wall_pattern_height());
    else if (face == "left")
        rotate([90, 0, 90])
            linear_extrude(depth, convexity = 8)
                translate([thickness, wall_pattern_y()])
                    pattern_mark(inner_depth(), wall_pattern_height());
    else if (face == "right")
        translate([outer_width - depth, 0, 0])
            rotate([90, 0, 90])
                linear_extrude(depth, convexity = 8)
                    translate([thickness, wall_pattern_y()])
                        pattern_mark(inner_depth(), wall_pattern_height());
    else if (face == "bottom")
        translate([0, 0, floor_raise + thickness - depth])
            linear_extrude(depth, convexity = 8)
                translate([thickness, thickness])
                    pattern_mark(inner_width(), inner_depth());
}

module lid_assembled() {
    wall_h = lid_wall_h();
    z0 = outer_height - lid_depth;
    lift = lid_preview_lift();
    // Barvy jsou jen ve složeném náhledu. Výkres zůstává červený řez.
    translate([0, 0, lift])
        if (lid_fit == "outer") {
            color("#f4d35e")
                translate([-lid_clearance - thickness, -lid_clearance - thickness, outer_height])
                    panel_3d()
                        lid_plate_outer_2d(lid_outer_w(), lid_outer_d());
            color("#8d4f9a")
                translate([-lid_clearance - thickness, -lid_clearance, z0])
                    rotate([90, 0, 0])
                        panel_3d()
                            lid_front_wall_2d(lid_outer_w(), wall_h);
            color("#c73e6a")
                translate([-lid_clearance - thickness, outer_depth + lid_clearance + thickness, z0])
                    rotate([90, 0, 0])
                        panel_3d()
                            lid_front_wall_2d(lid_outer_w(), wall_h);
            color("#6aa84f")
                translate([-lid_clearance - thickness, -lid_clearance - thickness, z0])
                    rotate([90, 0, 90])
                        panel_3d()
                            lid_side_wall_2d(lid_outer_d(), wall_h);
            color("#5c6bc0")
                translate([outer_width + lid_clearance, -lid_clearance - thickness, z0])
                    rotate([90, 0, 90])
                        panel_3d()
                            lid_side_wall_2d(lid_outer_d(), wall_h);
        } else {
            ox = thickness + lid_clearance;
            oy = thickness + lid_clearance;
            color("#f4d35e")
                translate([0, 0, outer_height])
                    panel_3d()
                        lid_plate_inner_2d();
            color("#8d4f9a")
                translate([ox, oy + thickness, z0])
                    rotate([90, 0, 0])
                        panel_3d()
                            lid_front_wall_2d(skirt_w(), wall_h);
            color("#c73e6a")
                translate([ox, oy + skirt_d(), z0])
                    rotate([90, 0, 0])
                        panel_3d()
                            lid_front_wall_2d(skirt_w(), wall_h);
            color("#6aa84f")
                translate([ox, oy, z0])
                    rotate([90, 0, 90])
                        panel_3d()
                            lid_side_wall_2d(skirt_d(), wall_h);
            color("#5c6bc0")
                translate([ox + skirt_w() - thickness, oy, z0])
                    rotate([90, 0, 90])
                        panel_3d()
                            lid_side_wall_2d(skirt_d(), wall_h);
        }
}

module assembled_box() {
    difference() {
        union() {
            color("#f3e2c0")
                if (show_part("bottom"))
                    translate([0, 0, floor_raise])
                        panel_3d()
                            bottom_panel_2d();
            color("#e8a317")
                if (show_part("front"))
                    translate([0, thickness, 0])
                        rotate([90, 0, 0])
                            panel_3d()
                                front_panel_2d("front");
            color("#d4542c")
                if (show_part("back"))
                    translate([0, outer_depth, 0])
                        rotate([90, 0, 0])
                            panel_3d()
                                front_panel_2d("back");
            color("#2f8f7a")
                if (show_part("left"))
                    rotate([90, 0, 90])
                        panel_3d()
                            side_panel_2d("left");
            color("#3a6fbe")
                if (show_part("right"))
                    translate([outer_width - thickness, 0, 0])
                        rotate([90, 0, 90])
                            panel_3d()
                                side_panel_2d("right");
            if (lid_on())
                lid_assembled();
        }
        if (pattern_enabled && pattern_op != "hole") {
            if (show_part("front") && pattern_on("front")) pattern_pocket("front");
            if (show_part("back") && pattern_on("back")) pattern_pocket("back");
            if (show_part("left") && pattern_on("left")) pattern_pocket("left");
            if (show_part("right") && pattern_on("right")) pattern_pocket("right");
            if (show_part("bottom") && pattern_on("bottom")) pattern_pocket("bottom");
        }
    }
}

assert(outer_width > 2 * thickness, "Šířka musí být větší než dvě tloušťky stěny");
assert(outer_depth > 2 * thickness, "Hloubka musí být větší než dvě tloušťky stěny");
assert(outer_height > thickness + floor_raise, "Výška musí být větší než dno a jeho výška nad zemí");
assert(floor_raise >= 0, "Dno nemůže být pod zemí");
assert(floor_raise == 0 || floor_raise >= thickness,
    "Pod vyvýšeným dnem musí zůstat aspoň tloušťka materiálu");
assert(joint_clearance < finger_width / 2,
    "Vůle spoje musí být menší než polovina šířky prstu");
assert(finger_width >= 2, "Prst je moc úzký");
assert(!lid_enabled || lid_depth >= 4, "Lem víčka je moc nízký");
assert(!lid_enabled || lid_depth < outer_height, "Víčko je hlubší než krabička");
assert(!lid_enabled || lid_clearance >= 0, "Vůle víčka nemůže být záporná");
assert(!lid_enabled || (lid_press >= 0 && lid_press < thickness / 2),
    "Stažení víčka musí být nezáporné a menší než polovina tloušťky");
assert(!lid_enabled || lid_fit == "outer" || lid_fit == "inner",
    "Víčko je outer nebo inner");
assert(!lid_enabled || lid_fit == "outer" || (skirt_w() > 4 * thickness && skirt_d() > 4 * thickness),
    "Vnitřní víčko se do otvoru nevejde. Zmenši vůli.");
assert(!lid_enabled || lid_fit == "outer" || lid_depth < inner_height(),
    "Vnitřní lem je hlubší než prostor nad dnem");
assert(!pattern_enabled || pattern_size > 0, "Velikost vzoru musí být kladná");
assert(!pattern_enabled || pattern_op == "hole" || (pattern_depth > 0 && pattern_depth < thickness),
    "Hloubka gravíru a reliéfu musí být menší než tloušťka");

log_laser();
echo(str("Vnitřek ", inner_width(), " × ", inner_depth(), " × ", inner_height(), " mm"));
echo(str("Vnějšek ", outer_width, " × ", outer_depth, " × ", outer_height, " mm"));
echo(str(floor_raise > 0
    ? str("Dno je ", floor_raise, " mm nad zemí")
    : "Dno je v rovině se zemí"));
echo(str("Prst na čele ", segment_size(outer_width), " mm, na výšce ",
    segment_size(corner_length()), " mm, na boku ", segment_size(inner_depth()), " mm"));
if (lid_enabled)
    echo(str("Víčko ", lid_fit == "inner" ? "vnitřní" : "vnější",
        ", lem ", lid_depth, " mm, vůle ", lid_clearance, " mm na stranu, ",
        lid_press > 0 ? str("spoj o ", lid_press, " mm těsnější než krabička, ") : "",
        lid_fit == "inner"
            ? str("lem ", skirt_w(), " × ", skirt_d(), " mm")
            : str("půdorys ", lid_outer_w(), " × ", lid_outer_d(), " mm")));
if (pattern_enabled)
    echo(str("Vzor ", pattern_op, " / ", pattern_shape,
        pattern_front ? " čelo" : "",
        pattern_back ? " záda" : "",
        pattern_left ? " levý bok" : "",
        pattern_right ? " pravý bok" : "",
        pattern_bottom ? " dno" : ""));
if (len(shown_parts) == 0)
    echo("Není vybraný žádný díl");

function span_min(axis) = min([
    for (f = view_parts) part_pos(f)[axis],
    if (lid_on()) (axis == 0 ? lid_sheet_x() : lid_sheet_y())
]);
function span_max(axis) = max([
    for (f = view_parts) part_pos(f)[axis] + part_size(f)[axis],
    if (lid_on()) (axis == 0 ? lid_sheet_x() + lid_sheet_w() : lid_sheet_y() + lid_sheet_h())
]);

subset = len(shown_parts) > 0 && len(shown_parts) < 5;
sheet_span = max(span_max(0) - span_min(0), span_max(1) - span_min(1));
$vpr = flat_layout ? [0, 0, 0] : [55, 0, 25];
$vpt = !flat_layout
    ? [outer_width / 2, outer_depth / 2, outer_height / 2 + lid_preview_lift() / 2]
    : subset || lid_on()
        ? [(span_min(0) + span_max(0)) / 2, (span_min(1) + span_max(1)) / 2, 0]
        : [170, 55, 0];
$vpd = !flat_layout ? 320 + lid_preview_lift()
    : subset || lid_on() ? sheet_span * 1.8
    : 380;

if (flat_layout)
    place_on_sheet();
else
    assembled_box();
