// Otevřená krabička pro laserové řezání překližky. Jednotky jsou milimetry.
// Rozměry jsou vnější. Dno a čtyři stěny drží prstové spoje, víčko není.
//
// Na desce jsou dva stejné čelní díly, dva stejné boky a jedno dno.
// Zapni rozložení a exportuj DXF nebo SVG. Vypni ho, když chceš 3D náhled.
//
// Kerf je šířka vypálené spáry. Obrys se o polovinu kerfu rozšíří, takže
// hotový díl má rozměr zadaný výše. Vůle je to, oč je zářez širší než prst.

/* [Vnější rozměry] */
// Celková šířka přes stěny, směr X
outer_width = 100; // [30:1:500]

// Celková hloubka přes stěny, směr Y
outer_depth = 80; // [30:1:500]

// Celková výška včetně dna. Shora je krabička otevřená.
outer_height = 50; // [15:1:400]

/* [Materiál a laser] */
// Tloušťka překližky
thickness = 3; // [1:0.1:8]

// Šířka řezu laseru. 0 vypne kompenzaci. Změř ji na zkušebním čtverci.
kerf = 0.15; // [0:0.01:0.4]

// O kolik je zářez širší než prst. 0 je těsný spoj po kompenzaci kerfu.
joint_clearance = 0.1; // [0:0.01:0.4]

/* [Prsty] */
// Cílová šířka prstu. Skutečná vyjde tak, aby jich na hraně byl lichý počet.
finger_width = 10; // [4:0.5:30]

/* [Rozložení na desce] */
// Mezera mezi hotovými obrysy. Řez do ní sahá polovinou kerfu z každé strany.
part_gap = 8; // [2:1:30]

// Okraj od počátku souřadnic k hotovému obrysu
sheet_margin = 5; // [0:1:30]

/* [Náhled] */
// Díly rozložené na desce. Vypni pro složenou krabičku.
flat_layout = true;

/* [Hidden] */

function inner_width() = outer_width - 2 * thickness;
function inner_depth() = outer_depth - 2 * thickness;
function inner_height() = outer_height - thickness;

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

// Čelo i záda jsou stejný díl. Prsty na bocích i na spodní hraně, nahoře rovně.
module front_panel_2d() {
    union() {
        translate([thickness, thickness])
            square([inner_width(), inner_height()]);
        tabs(outer_width, thickness, false, true);
        translate([0, thickness])
            tabs(inner_height(), thickness, true, true);
        translate([outer_width - thickness, thickness])
            tabs(inner_height(), thickness, true, true);
    }
}

// Bok sedí mezi čely. Svislé prsty jsou doplněk čela, roh dole patří čelu.
module side_panel_2d() {
    union() {
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

// Dno má prsty tam, kde má stěna zářez. Rohy drží spodní prsty čel.
module bottom_panel_2d() {
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
}

// Slije sousedící obdélníky do jednoho obrysu, ať laser neřeže vnitřní hrany.
module nominal_outline() {
    offset(delta = 0.001)
        offset(delta = -0.001)
            children();
}

// Hotový obrys posune o polovinu kerfu ven. Řez středem čáry pak sedí na rozměr.
module cut_outline() {
    offset(delta = kerf / 2)
        nominal_outline()
            children();
}

module place_on_sheet() {
    front_w = outer_width;
    front_h = outer_height;
    side_w = outer_depth;

    translate([sheet_margin, sheet_margin])
        cut_outline()
            front_panel_2d();
    translate([sheet_margin + front_w + part_gap, sheet_margin])
        cut_outline()
            front_panel_2d();
    translate([sheet_margin + 2 * (front_w + part_gap), sheet_margin])
        cut_outline()
            side_panel_2d();
    translate([sheet_margin + 2 * (front_w + part_gap) + side_w + part_gap, sheet_margin])
        cut_outline()
            side_panel_2d();
    translate([sheet_margin, sheet_margin + front_h + part_gap])
        cut_outline()
            bottom_panel_2d();
}

module panel_3d() {
    linear_extrude(thickness, convexity = 4)
        nominal_outline()
            children();
}

module assembled_box() {
    color("#e4c79a")
        panel_3d()
            bottom_panel_2d();

    color("#d2ae78") {
        translate([0, thickness, 0])
            rotate([90, 0, 0])
                panel_3d()
                    front_panel_2d();
        translate([0, outer_depth, 0])
            rotate([90, 0, 0])
                panel_3d()
                    front_panel_2d();
    }

    color("#c49658") {
        rotate([90, 0, 90])
            panel_3d()
                side_panel_2d();
        translate([outer_width - thickness, 0, 0])
            rotate([90, 0, 90])
                panel_3d()
                    side_panel_2d();
    }
}

assert(outer_width > 2 * thickness, "Šířka musí být větší než dvě tloušťky stěny");
assert(outer_depth > 2 * thickness, "Hloubka musí být větší než dvě tloušťky stěny");
assert(outer_height > thickness, "Výška musí být větší než tloušťka dna");
assert(thickness > 0, "Tloušťka materiálu musí být kladná");
assert(kerf >= 0 && kerf < thickness, "Kerf musí být nezáporný a menší než tloušťka");
assert(joint_clearance >= 0 && joint_clearance < finger_width / 2,
    "Vůle spoje musí být menší než polovina šířky prstu");
assert(finger_width >= 2, "Prst je moc úzký");
assert(part_gap > kerf, "Mezera mezi díly musí být větší než kerf");

echo(str("Vnitřek ", inner_width(), " × ", inner_depth(), " × ", inner_height(), " mm"));
echo(str("Vnějšek ", outer_width, " × ", outer_depth, " × ", outer_height, " mm"));
echo(str("Prst na čele ", segment_size(outer_width), " mm, na výšce ",
    segment_size(inner_height()), " mm, na boku ", segment_size(inner_depth()), " mm"));

$vpr = flat_layout ? [0, 0, 0] : [55, 0, 25];
$vpt = flat_layout
    ? [170, 55, 0]
    : [outer_width / 2, outer_depth / 2, outer_height / 2];
$vpd = flat_layout ? 380 : 320;

if (flat_layout)
    color("#e10600")
        place_on_sheet();
else
    assembled_box();
