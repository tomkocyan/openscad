// Rotační objekt z překližky, třeba stínidlo lampy. Jednotky jsou milimetry.
// Profil je jedno ploché žebro. Kolem osy se zopakuje rib_count kusů.
// Žebra drží vodorovné středy: prstenec má zářezy, žebro má zevnitř zapuštění.
//
// Křivka profilu je v Customizeru ve skupině Profil. Body jdou odspodu, výšky musí růst.
// Zapni rozložení a exportuj DXF nebo SVG. Vypni ho pro složený náhled.
// Kerf, tloušťka a vůle spoje jsou v settings.scad.

include <settings.scad>

/* [Profil] */
// Kolik bodů tvoří křivku. Použijí se první N, odspodu.
profile_count = 6; // [2:1:8]

// Výška bodu 1 v mm. Body jdou odspodu a další výšky musí být větší.
profile_z_1 = 0; // [0:1:400]
// Vnější poloměr bodu 1 v mm
profile_r_1 = 52; // [10:1:200]

// Výška bodu 2 v mm
profile_z_2 = 24; // [0:1:400]
// Vnější poloměr bodu 2 v mm
profile_r_2 = 72; // [10:1:200]

// Výška bodu 3 v mm
profile_z_3 = 70; // [0:1:400]
// Vnější poloměr bodu 3 v mm
profile_r_3 = 98; // [10:1:200]

// Výška bodu 4 v mm
profile_z_4 = 120; // [0:1:400]
// Vnější poloměr bodu 4 v mm
profile_r_4 = 88; // [10:1:200]

// Výška bodu 5 v mm
profile_z_5 = 165; // [0:1:400]
// Vnější poloměr bodu 5 v mm
profile_r_5 = 60; // [10:1:200]

// Výška bodu 6 v mm
profile_z_6 = 210; // [0:1:400]
// Vnější poloměr bodu 6 v mm
profile_r_6 = 44; // [10:1:200]

// Výška bodu 7 v mm. Platí, jen když je bodů aspoň 7.
profile_z_7 = 250; // [0:1:400]
// Vnější poloměr bodu 7 v mm
profile_r_7 = 36; // [10:1:200]

// Výška bodu 8 v mm. Platí, jen když je bodů 8.
profile_z_8 = 290; // [0:1:400]
// Vnější poloměr bodu 8 v mm
profile_r_8 = 32; // [10:1:200]

// Hladký profil. Vypni, když chceš úsečky přímo mezi body.
profile_smooth = true;

// Kolik úseček má křivka mezi konci. Víc = hladší řez.
profile_steps = 48; // [8:1:120]

// Hloubka žebra od vnějšího profilu dovnitř, v mm
rib_depth = 16; // [6:1:40]

// Zakulatí horní a dolní rohy žebra. Zářezy na středy zůstanou ostré.
round_corners = false;

// Poloměr zakulacení v mm. Nejvýš polovina hloubky žebra.
corner_radius = 4; // [0:0.5:20]

/* [Rotace] */
// Počet žeber kolem osy
rib_count = 18; // [3:1:48]

/* [Středy] */
// Kolik prstenců žebra drží. Použijí se první N výšek a zapuštění.
center_count = 3; // [1:1:5]

// Výška středu na profilu, v mm
center_height_1 = 28; // [0:1:400]
center_height_2 = 110; // [0:1:400]
center_height_3 = 175; // [0:1:400]
center_height_4 = 60; // [0:1:400]
center_height_5 = 140; // [0:1:400]

// Jak hluboko prstenec zajede do žebra, měřeno od vnitřní hrany, v mm
center_notch_1 = 8; // [2:0.5:30]
center_notch_2 = 8; // [2:0.5:30]
center_notch_3 = 8; // [2:0.5:30]
center_notch_4 = 8; // [2:0.5:30]
center_notch_5 = 8; // [2:0.5:30]

// Plný kotouč až do osy. Vypnuto = věnec s dírou uprostřed.
ring_solid_1 = false;
ring_solid_2 = false;
ring_solid_3 = false;
ring_solid_4 = false;
ring_solid_5 = false;

// Radiální šířka věnce. U plného kotouče se nepoužije.
// Musí být větší než zapuštění, ať věnec drží pohromadě.
ring_width = 18; // [6:1:40]

/* [Rozložení] */
// Díly na desce. Vypni pro složený objekt.
flat_layout = false;

// Žeber vedle sebe na desce
layout_columns = 5; // [1:1:12]

/* [Hidden] */
function profile_z(i) =
    i == 0 ? profile_z_1
    : i == 1 ? profile_z_2
    : i == 2 ? profile_z_3
    : i == 3 ? profile_z_4
    : i == 4 ? profile_z_5
    : i == 5 ? profile_z_6
    : i == 6 ? profile_z_7
    : profile_z_8;

function profile_r(i) =
    i == 0 ? profile_r_1
    : i == 1 ? profile_r_2
    : i == 2 ? profile_r_3
    : i == 3 ? profile_r_4
    : i == 4 ? profile_r_5
    : i == 5 ? profile_r_6
    : i == 6 ? profile_r_7
    : profile_r_8;

// [výška, vnější poloměr] z prvních profile_count bodů.
profile = [for (i = [0:profile_count - 1]) [profile_z(i), profile_r(i)]];

function center_height(i) =
    i == 0 ? center_height_1
    : i == 1 ? center_height_2
    : i == 2 ? center_height_3
    : i == 3 ? center_height_4
    : center_height_5;

function center_notch(i) =
    i == 0 ? center_notch_1
    : i == 1 ? center_notch_2
    : i == 2 ? center_notch_3
    : i == 3 ? center_notch_4
    : center_notch_5;

function ring_solid(i) =
    i == 0 ? ring_solid_1
    : i == 1 ? ring_solid_2
    : i == 2 ? ring_solid_3
    : i == 3 ? ring_solid_4
    : ring_solid_5;

function z_min() = profile[0][0];
function z_max() = profile[len(profile) - 1][0];
function profile_height() = z_max() - z_min();

function segment_at(z) =
    let(hits = [
        for (i = [0:len(profile) - 2])
            if (z <= profile[i + 1][0] || i == len(profile) - 2) i
    ])
    hits[0];

// Catmull-Rom jen na poloměru. Výška zůstane přesně tam, kam ji zadáš.
function catmull_rom(p0, p1, p2, p3, t) =
    let(t2 = t * t, t3 = t2 * t)
    0.5 * (
        (2 * p1)
        + (-p0 + p2) * t
        + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
        + (-p0 + 3 * p1 - 3 * p2 + p3) * t3
    );

function radius_at(z) =
    let(
        zc = min(max(z, z_min()), z_max()),
        i = segment_at(zc),
        z1 = profile[i][0],
        z2 = profile[i + 1][0],
        t = (zc - z1) / max(z2 - z1, 0.001),
        p0 = profile[max(i - 1, 0)][1],
        p1 = profile[i][1],
        p2 = profile[i + 1][1],
        p3 = profile[min(i + 2, len(profile) - 1)][1]
    )
    profile_smooth ? catmull_rom(p0, p1, p2, p3, t) : (p1 + (p2 - p1) * t);

function sample_z(i) =
    z_min() + profile_height() * i / (profile_steps - 1);

function min_inner_radius() =
    min([for (i = [0:profile_steps - 1]) radius_at(sample_z(i)) - rib_depth]);

function max_outer_radius() =
    max([for (i = [0:profile_steps - 1]) radius_at(sample_z(i))]);

// Vnější poloměr prstence: vnitřní hrana žebra plus zapuštění.
function ring_outer_radius(i) =
    radius_at(center_height(i)) - rib_depth + center_notch(i);

function rib_span_x() = max_outer_radius() - min_inner_radius();
function rib_rows() = ceil(rib_count / layout_columns);
function rib_cols_used() = min(layout_columns, rib_count);

function sheet_ribs_width() =
    2 * sheet_margin
    + rib_cols_used() * rib_span_x()
    + (rib_cols_used() - 1) * part_gap;

function sheet_ribs_height() =
    2 * sheet_margin
    + rib_rows() * profile_height()
    + (rib_rows() - 1) * part_gap;

function rings_width() =
    2 * sheet_margin
    + [for (i = [0:center_count - 1]) 2 * ring_outer_radius(i)]
        * [for (i = [0:center_count - 1]) 1]
    + (center_count - 1) * part_gap;

function notch_band() = thickness + joint_clearance;

// Na konci žebra jsou dva rohy vedle sebe, větší poloměr by je srazil dohromady.
function used_corner_radius() =
    round_corners ? min(max(corner_radius, 0), rib_depth / 2 - 0.05) : 0;

function v_len(a) = sqrt(a * a);
function v_unit(a) = a / max(v_len(a), 0.001);
function v_dot(a, b) = a * b;
function ang_diff(a, b) =
    let(d = b - a)
    d > 180 ? d - 360 : d < -180 ? d + 360 : d;

// Oblouk místo jednoho konvexního rohu. Když se nevejde, poloměr se zmenší.
function corner_arc(prev, v, next, r) =
    let(
        back = v_unit(prev - v),
        fore = v_unit(next - v),
        alpha = acos(min(max(back * fore, -1), 1)),
        half = alpha / 2
    )
    (r < 0.05 || alpha < 8 || alpha > 172) ? [v]
    : let(
        t = min(r / tan(half), v_len(v - prev) * 0.45, v_len(next - v) * 0.45),
        r_use = t * tan(half),
        bis = v_unit(back + fore),
        center = v + bis * (r_use / sin(half)),
        p1 = v + back * t,
        p2 = v + fore * t,
        a0 = atan2(p1[1] - center[1], p1[0] - center[0]),
        a1 = atan2(p2[1] - center[1], p2[0] - center[0]),
        a_mid = atan2(v[1] - center[1], v[0] - center[0]),
        d0 = ang_diff(a0, a1),
        d = abs(ang_diff(a0 + d0 / 2, a_mid)) < 35 ? d0 : (d0 > 0 ? d0 - 360 : d0 + 360),
        steps = max(6, ceil(r_use))
    )
    [for (s = [0:steps]) center + r_use * [cos(a0 + d * s / steps), sin(a0 + d * s / steps)]];

function mm(n) = round(n * 10) / 10;

assert(profile_count >= 2 && profile_count <= 8, "Křivka má 2 až 8 bodů");
assert(len(profile) >= 2, "Profil potřebuje aspoň dva body");
assert(profile_steps >= 2, "Křivka profilu potřebuje aspoň dva kroky");
assert(rib_count >= 3, "Rotace potřebuje aspoň tři žebra");
assert(center_count >= 1 && center_count <= 5, "Počet středů je 1 až 5");
assert(rib_depth > 0, "Žebro musí mít kladnou hloubku");
assert(
    min([for (i = [0:len(profile) - 2]) profile[i + 1][0] - profile[i][0]]) > 0,
    "Výšky profilu musí růst"
);
assert(min_inner_radius() > 1, "Profil je moc úzký na tuhle hloubku žebra");

for (i = [0:center_count - 1]) {
    assert(center_notch(i) > 0 && center_notch(i) < rib_depth,
        str("Zapuštění středu ", i + 1, " musí být menší než hloubka žebra"));
    if (!ring_solid(i)) {
        assert(ring_width > center_notch(i),
            str("Prstenec ", i + 1, " je užší než zapuštění a rozpadl by se"));
        assert(ring_outer_radius(i) > ring_width,
            str("Prstenec ", i + 1, " je širší než jeho poloměr"));
    }
    assert(
        center_height(i) - notch_band() / 2 >= z_min()
            && center_height(i) + notch_band() / 2 <= z_max(),
        str("Střed ", i + 1, " i se zářezem musí ležet uvnitř profilu")
    );
}

for (i = [0:center_count - 2])
    assert(abs(center_height(i + 1) - center_height(i)) >= notch_band(),
        "Středy jsou moc blízko, zářezy by se proťaly");

gap_at_inner = 2 * min_inner_radius() * sin(180 / rib_count) - thickness;
if (gap_at_inner < 0.4)
    echo(str("Varování: žebra se u středu skoro dotýkají (mezera ",
        mm(gap_at_inner), " mm). Uber rib_count nebo zvětši poloměr."));

log_laser();
echo("—— výsledné rozměry ——");
echo(str("Objekt ", mm(2 * max_outer_radius()), " × ", mm(profile_height()),
    " mm (průměr × výška)"));
echo(str("Žeber: ", rib_count, ", středů: ", center_count));
echo(str("Žebro na desce ", mm(rib_span_x()), " × ", mm(profile_height()), " mm"));
if (round_corners)
    echo(str("Zakulacení rohů: ", mm(used_corner_radius()), " mm"));
if (round_corners && corner_radius > rib_depth / 2)
    echo(str("Varování: poloměr rohů je zkrácený na ", mm(used_corner_radius()),
        " mm, ať se konce žebra neslijí."));
for (i = [0:center_count - 1])
    echo(str("Střed ", i + 1, ": výška ", mm(center_height(i)),
        " mm, průměr ", mm(2 * ring_outer_radius(i)),
        " mm, zapuštění ", mm(center_notch(i)),
        " mm, ", ring_solid(i) ? "plný" : "věnec"));
if (flat_layout)
    echo(str("Deska žeber ", mm(sheet_ribs_width()), " × ", mm(sheet_ribs_height()),
        " mm, řada prstenců široká ", mm(rings_width()), " mm"));

// Zakulatí jen čtyři rohy na koncích. Zářezy na středy se nezaoblují.
function rib_points() =
    let(
        outer = [
            for (i = [0:profile_steps - 1])
                let(z = sample_z(i))
                [radius_at(z), z]
        ],
        inner = [
            for (i = [profile_steps - 1:-1:0])
                let(z = sample_z(i))
                [radius_at(z) - rib_depth, z]
        ],
        pts = concat(outer, inner),
        n = len(pts),
        n_outer = len(outer),
        r = used_corner_radius(),
        ends = [0, n_outer - 1, n_outer, n - 1]
    )
    [for (i = [0:n - 1])
        each (
            r >= 0.05 && len([for (e = ends) if (e == i) e]) > 0
                ? corner_arc(pts[(i + n - 1) % n], pts[i], pts[(i + 1) % n], r)
                : [pts[i]]
        )
    ];

module rib_2d() {
    difference() {
        polygon(rib_points());
        for (i = [0:center_count - 1])
            rib_notch(i);
    }
}

// Zářez z vnitřní hrany. Přesah 1 mm jen otevře hranu, na spoj nemá vliv.
module rib_notch(i) {
    h = center_height(i);
    half = notch_band() / 2;
    reach = radius_at(h) - rib_depth + center_notch(i);
    polygon([
        [reach - center_notch(i) - 1, h - half],
        [reach, h - half],
        [reach, h + half],
        [reach - center_notch(i) - 1, h + half]
    ]);
}

module ring_2d(i) {
    outer_r = ring_outer_radius(i);
    inner_r = outer_r - ring_width;
    slot = notch_band();
    difference() {
        circle(r = outer_r, $fn = 96);
        if (!ring_solid(i))
            circle(r = inner_r, $fn = 96);
        for (n = [0:rib_count - 1])
            rotate(n * 360 / rib_count)
                translate([outer_r - center_notch(i) / 2, 0])
                    square([center_notch(i) + 0.4, slot], center = true);
    }
}

module assembled() {
    color("#e4c79a")
        for (n = [0:rib_count - 1])
            rotate([0, 0, n * 360 / rib_count])
                rotate([90, 0, 0])
                    linear_extrude(thickness, center = true)
                        rib_2d();
    color("#c49658")
        for (i = [0:center_count - 1])
            translate([0, 0, center_height(i)])
                linear_extrude(thickness, center = true)
                    ring_2d(i);
}

module flat_sheet() {
    for (n = [0:rib_count - 1]) {
        col = n % layout_columns;
        row = floor(n / layout_columns);
        translate([
            sheet_margin + col * (rib_span_x() + part_gap) - min_inner_radius(),
            sheet_margin + row * (profile_height() + part_gap) - z_min()
        ])
            laser_cut()
                rib_2d();
    }

    ring_y = sheet_ribs_height() - sheet_margin + part_gap;
    for (i = [0:center_count - 1]) {
        place_r = ring_outer_radius(i);
        previous = i == 0 ? 0 : [for (k = [0:i - 1]) 2 * ring_outer_radius(k) + part_gap] * [for (k = [0:i - 1]) 1];
        translate([
            sheet_margin + place_r + previous,
            ring_y + place_r
        ])
            laser_cut()
                ring_2d(i);
    }
}

if (flat_layout)
    flat_sheet();
else
    assembled();
