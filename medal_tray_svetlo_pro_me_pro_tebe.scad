// Přepravní přihrádky na medaile z překližky. Jednotky jsou milimetry.
// Medaile stojí na hraně, na výšku. Přihrádka je mělčí než medaile,
// takže nahoře trčí a bere se za ni.
//
// Půdorys přihrádky: šířka medaile × tloušťka překližky, obojí s vůlí.
// Sloupce jdou po šířce (8 cm), řádky po tloušťce (3 mm).
//
// Optimalizace pro trysku 0,4 mm:
// - tloušťky stěn i dna jsou násobky 0,4 mm, slicer je složí z celých perimetrů
// - štěrbina na tloušťku vychází také na násobek 0,4 mm
// - dno tiskni vrstvou 0,2 mm (při 1,6 mm je to 8 vrstev) nebo 0,16 mm
// - model sedí dnem na podložce a nepotřebuje podpěry
// - zaoblení je 2D offset, ne minkowski, ať je náhled i render svižný
//
// Vůle je na každou stranu. Vnitřek přihrádky = medaile + 2 × vůle.

/* [Medaile] */
// Šířka medaile ve směru X, když stojí na hraně
medal_width = 45; // [10:0.5:300]

// Výška medaile. Nad stěnou z ní trčí část, za kterou se bere
medal_height = 66; // [10:0.5:300]

// Tloušťka překližky. Medaile stojí na této hraně
medal_thickness = 3.1; // [0.4:0.1:30]

// Kruhová medaile v náhledu. Přihrádku nemění, do STL se neexportuje.
round_medal = true;

/* [Vůle] */
// Vůle na každou stranu po šířce
clearance_width = 1; // [0:0.1:5]

// Vůle na každou stranu po tloušťce. 0,5 mm dá štěrbinu 4,0 mm
clearance_thickness = 0.5; // [0:0.1:3]

/* [Mřížka] */
// Počet medailí vedle sebe po šířce (směr X)
columns = 2; // [1:1:8]

// Počet medailí vedle sebe po tloušťce (směr Y)
rows = 20; // [1:1:24]

/* [Stěny] */
// Tloušťka vnější stěny, násobek průměru trysky
outer_wall = 2.0; // [0.4:0.4:4]

// Tloušťka vnitřní příčky, násobek průměru trysky
inner_wall = 1.2; // [0.4:0.4:4]

// Tloušťka dna, násobek průměru trysky
floor_thickness = 1.6; // [0.4:0.4:4]

// Vnitřní hloubka přihrádky bez dna. Menší než výška medaile, ať nahoře trčí.
compartment_depth = 50; // [10:1:150]

// Zaoblení vnějších rohů
outer_corner_radius = 2.0; // [0:0.2:10]

// Zaoblení rohů štěrbiny. U tenké mezery ho nech malé, ať medaile nedrhne.
inner_corner_radius = 0.4; // [0:0.2:4]

// Zkosení ústí, ať medaile zapadne. Drž ho pod polovinou vnitřní stěny.
mouth_chamfer = 0.4; // [0:0.1:2]

/* [Výřez na prst] */
// U medailí na výšku není potřeba, nahoře vyčnívají. Nech vypnuté.
enable_finger_notch = false;

// Šířka výřezu. Musí zůstat menší než šířka medaile, jinak by vypadla.
finger_notch_width = 20; // [0:1:40]

// Jak hluboko kapsa zajede pod medaili. 0 = jen výřez ve stěně.
finger_pocket_depth = 16; // [0:1:40]

/* [Tisk] */
// Průměr trysky. Geometrii nemění, jen kontroluje násobky tlouštěk.
nozzle_diameter = 0.4; // [0.2:0.05:1.2]

// Průhledná medaile v náhledu. Do STL se neexportuje.
show_medal_preview = true;

/* [Hidden] */

// --- odvozené rozměry -------------------------------------------------------

function column_count() = max(1, round(columns));
function row_count() = max(1, round(rows));

function cell_size_x() = medal_width + 2 * clearance_width;
function cell_size_y() = medal_thickness + 2 * clearance_thickness;

function outer_size_x() =
    2 * outer_wall
    + column_count() * cell_size_x()
    + (column_count() - 1) * inner_wall;

function outer_size_y() =
    2 * outer_wall
    + row_count() * cell_size_y()
    + (row_count() - 1) * inner_wall;

function total_height() = floor_thickness + compartment_depth;

function stick_out() = medal_height - compartment_depth;

// Střed přihrádky. Mřížka je vystředěná, dno leží na Z = 0.
function cell_x(col) =
    -outer_size_x() / 2
    + outer_wall
    + col * (cell_size_x() + inner_wall)
    + cell_size_x() / 2;

function cell_y(row) =
    -outer_size_y() / 2
    + outer_wall
    + row * (cell_size_y() + inner_wall)
    + cell_size_y() / 2;

// Kapsa nesmí proříznout přihrádku napůl, když je výřez z obou stran.
function pocket_depth() =
    max(0, min(finger_pocket_depth, cell_size_y() / 2 - 1));

// Výřez musí být užší než medaile v obou směrech, jinak by při převozu vypadla.
function finger_notch_active() =
    enable_finger_notch
    && finger_notch_width >= nozzle_diameter
    && finger_notch_width + nozzle_diameter < medal_width
    && pocket_depth() < medal_thickness;

function multiple_error(value, step) =
    abs(value - round(value / step) * step);

function nearest_multiple(value, step) =
    round(value / step) * step;

// Na setiny milimetru, ať se v logu neobjevují dlouhé floaty.
function mm(n) = round(n * 100) / 100;

// --- kontrola parametrů -----------------------------------------------------

assert(medal_width > 0 && medal_height > 0, "Rozměr medaile musí být kladný.");
assert(medal_thickness > 0, "Tloušťka medaile musí být kladná.");
assert(compartment_depth > 0, "Hloubka přihrádky musí být kladná.");
assert(floor_thickness > 0, "Dno musí mít kladnou tloušťku.");
assert(outer_wall > 0 && inner_wall > 0, "Stěny musí mít kladnou tloušťku.");
assert(nozzle_diameter > 0, "Průměr trysky musí být kladný.");
assert(mouth_chamfer >= 0, "Zkosení ústí nemůže být záporné.");
assert(cell_size_x() > 1 && cell_size_y() > 1,
    "Přihrádka vyšla příliš malá. Zvětši medaili nebo vůli.");

module warn_multiple(value, step, name) {
    if (multiple_error(value, step) > 0.02)
        echo(str("Varování: ", name, " ", value, " mm není násobek ", step,
            " mm. Nejbližší vhodná tloušťka je ", nearest_multiple(value, step), " mm."));
}

warn_multiple(outer_wall, nozzle_diameter, "vnější stěna");
warn_multiple(inner_wall, nozzle_diameter, "vnitřní stěna");
warn_multiple(floor_thickness, nozzle_diameter, "dno");

if (outer_wall + 0.001 < nozzle_diameter || inner_wall + 0.001 < nozzle_diameter)
    echo("Varování: stěna je tenčí než tryska a nepůjde spolehlivě vytisknout.");

if (inner_corner_radius > min(clearance_width, clearance_thickness) * 3 + 0.001)
    echo("Varování: zaoblení rohů štěrbiny je velké vůči vůli. Medaile může v rozích drhnout.");

if (mouth_chamfer * 2 > inner_wall + 0.001)
    echo("Varování: zkosení ústí sebere celou horní hranu vnitřní stěny. Zmenši mouth_chamfer.");

if (enable_finger_notch && finger_notch_width > 0 && !finger_notch_active())
    echo("Výřezy na prst jsou vypnuté: otvor by byl dost velký na to, aby medaile propadla. Zmenši šířku výřezu nebo hloubku kapsy.");

if (finger_notch_active() && finger_pocket_depth > pocket_depth() + 0.01)
    echo(str("Kapsa pod medaili je zkrácená na ", pocket_depth(),
        " mm, ať výřezy z obou stran neproříznou dno napůl."));

if (stick_out() < 8)
    echo("Varování: nad hranou trčí méně než 8 mm. Zmenši compartment_depth, ať jde medaile uchopit.");

if (outer_size_x() > 220 || outer_size_y() > 220)
    echo("Varování: půdorys je větší než 220 mm. Zkontroluj, jestli se vejde na podložku.");

echo("—— výsledné rozměry ——");
echo(str("Krabička ", mm(outer_size_x()), " × ", mm(outer_size_y()), " × ", mm(total_height()), " mm"));
echo(str("  šířka X: ", mm(outer_size_x()), " mm"));
echo(str("  hloubka Y: ", mm(outer_size_y()), " mm"));
echo(str("  výška Z: ", mm(total_height()), " mm"));
echo(str("Štěrbina ", mm(cell_size_x()), " × ", mm(cell_size_y()), " × ", mm(compartment_depth), " mm"));
echo(str("  šířka: ", mm(cell_size_x()), " mm"));
echo(str("  tloušťka: ", mm(cell_size_y()), " mm"));
echo(str("  hloubka: ", mm(compartment_depth), " mm"));
echo(str("Medailí: ", column_count() * row_count()));
echo(str("Nad hranou trčí: ", mm(stick_out()), " mm"));

// --- geometrie --------------------------------------------------------------

// Obdélník se zaoblenými rohy o zadaném vnějším rozměru.
// Nejdřív se zmenší o poloměr, pak se offsetem vrátí zpět a rohy se zakulatí.
module rounded_rect(size, radius) {
    r = max(0, min(radius, min(size.x, size.y) / 2 - 0.05));
    if (r < 0.05)
        square(size, center = true);
    else
        offset(r = r, $fn = 32)
            offset(delta = -r)
                square(size, center = true);
}

module compartments_2d() {
    for (col = [0:column_count() - 1], row = [0:row_count() - 1])
        translate([cell_x(col), cell_y(row)])
            rounded_rect([cell_size_x(), cell_size_y()], inner_corner_radius);
}

// Zkosené ústí: dole sedí na světlosti štěrbiny, nahoře je o chamfer širší.
module mouth_chamfers() {
    if (mouth_chamfer > 0.05)
        for (col = [0:column_count() - 1], row = [0:row_count() - 1])
            hull() {
                translate([cell_x(col), cell_y(row), total_height() - mouth_chamfer])
                    linear_extrude(0.01)
                        rounded_rect([cell_size_x(), cell_size_y()], inner_corner_radius);
                translate([cell_x(col), cell_y(row), total_height() + 0.01])
                    linear_extrude(0.01)
                        rounded_rect(
                            [cell_size_x() + 2 * mouth_chamfer, cell_size_y() + 2 * mouth_chamfer],
                            inner_corner_radius + mouth_chamfer);
            }
}

// side -1 je stěna na záporném Y, side +1 na kladném Y.
// U vnitřní příčky přesah 0,02 mm jen čistě ořeže stěnu, na tisk nemá vliv.
module finger_notch_solid(col, row, side) {
    y_center = cell_y(row);
    half = cell_size_y() / 2;
    y_edge = y_center + side * half;
    is_outer = (side < 0 && row == 0) || (side > 0 && row == row_count() - 1);
    wall = is_outer ? outer_wall : inner_wall;
    pocket = pocket_depth();
    eps = 0.02;
    notch_w = min(finger_notch_width, cell_size_x() - 2 * nozzle_diameter);

    y0 = (side < 0) ? y_edge - wall - eps : y_edge - pocket;
    y1 = (side < 0) ? y_edge + pocket : y_edge + wall + eps;

    translate([cell_x(col), (y0 + y1) / 2, total_height() / 2])
        cube([notch_w, y1 - y0, total_height() + 0.04], center = true);
}

module finger_notches() {
    last = row_count() - 1;
    for (col = [0:column_count() - 1], row = [0:last]) {
        if (row == 0 || row != last)
            finger_notch_solid(col, row, -1);
        if (row == last)
            finger_notch_solid(col, row, 1);
    }
}

module tray() {
    difference() {
        linear_extrude(total_height())
            rounded_rect([outer_size_x(), outer_size_y()], outer_corner_radius);

        // Dutina začíná nad dnem a je o kousek vyšší, ať je horní hrana čistě otevřená.
        translate([0, 0, floor_thickness])
            linear_extrude(compartment_depth + 0.02)
                compartments_2d();

        mouth_chamfers();

        if (finger_notch_active())
            finger_notches();
    }
}

// Medaile stojí na hraně: tloušťka je ve směru Y, výška ve směru Z.
module medal_preview(col, row) {
    translate([cell_x(col), cell_y(row), floor_thickness]) {
        if (round_medal)
            translate([0, 0, medal_height / 2])
                rotate([90, 0, 0])
                    scale([medal_width, medal_height, medal_thickness])
                        cylinder(h = 1, d = 1, center = true, $fn = 64);
        else
            translate([-medal_width / 2, -medal_thickness / 2, 0])
                cube([medal_width, medal_thickness, medal_height]);
    }
}

color("#d5d8dc")
    tray();

// Procenta znamenají jen náhled: při renderu (F6) i v STL medaile zmizí.
if (show_medal_preview)
    for (col = [0:column_count() - 1], row = [0:row_count() - 1])
        %color("#c4a574")
            medal_preview(col, row);
