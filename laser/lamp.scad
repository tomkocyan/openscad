// Rotační objekt z překližky, třeba stínidlo lampy. Jednotky jsou milimetry.
// Profil je jedno ploché žebro. Kolem osy se zopakuje rib_count kusů.
// rib_angle 0 je kolmo k obvodu, světlo jde rovnou ven. Natočení průhled zacloní.
// Žebra drží vodorovné středy: prstenec má zářezy, žebro má zevnitř zapuštění.
//
// Profil i středy se upravují tady v souboru, ne v Customizeru.
// Profil je [výška, poloměr] odspodu, výšky musí růst. Způsob křivky je v Customizeru.
// Střed je [výška, zapuštění, plný]. Žebro má čtyři kulaté rohy, dva nahoře a dva dole.
// Zapni rozložení a exportuj DXF nebo SVG. Vypni ho pro složený náhled.
// Kerf a tloušťka jsou v settings.scad. Tady to neměň.

include <settings.scad>

/* [Profil] */
// usecky = lomené úsečky. interpolace = hladce skrz body.
// spline = kubický spline skrz body, může překmitnout. monotonni = skrz body bez překmitu.
// aproximace = B-spline, vnitřními body neprojde.
profile_curve = "interpolace"; // [usecky, interpolace, spline, monotonni, aproximace]

// Kolik úseček má křivka mezi konci. Víc = hladší řez.
profile_steps = 48; // [8:1:120]

// Hloubka žebra od vnějšího profilu dovnitř, v mm
rib_depth = 16; // [6:1:40]

// Čtyři kulaté rohy: dva nahoře, dva dole. Zářezy na středy zůstanou ostré.
round_corners = true;

// Poloměr těch čtyř rohů v mm. Nejvýš polovina hloubky žebra.
corner_radius = 4; // [0:0.5:20]

/* [Rotace] */
// Počet žeber kolem osy
rib_count = 18; // [3:1:48]

// Natočení žeber ve stupních. 0 je kolmo, kladné je po směru hodin.
// Lamely se točí kolem vnitřní hrany, ať mezi nimi není přímý průhled ven.
rib_angle = 0; // [-75:1:75]

/* [Středy] */
// Radiální šířka věnce. U plného kotouče se nepoužije.
// Musí být větší než zapuštění, ať věnec drží pohromadě.
ring_width = 18; // [6:1:40]

/* [Rozložení] */
// Co kreslit: zebra, rafky, nebo oboji.
show_parts = "oboji"; // [zebra, rafky, oboji]

// Díly na desce. Vypni pro složený objekt.
// Žebro je tam jen jedno, jsou všechna stejná. Ráfky jsou všechny, liší se.
flat_layout = false;

/* [Hidden] */
// [výška, vnější poloměr] odspodu. Customizer seznamy přepisuje, proto je profil skrytý.
profile = [
    [0, 50],
    [20, 70],
    [100, 98],
    [120, 88]
];

// [výška, zapuštění, plný kotouč]. Výška v mm odspodu, zapuštění od vnitřní hrany.
// true = plný kotouč až do osy, false = věnec s dírou.
centers = [
    [28, 8, true],
    [110, 8, false]
];

center_count = len(centers);

function center_height(i) = centers[i][0];
function center_notch(i) = centers[i][1];
function ring_solid(i) = centers[i][2];

function z_min() = profile[0][0];
function z_max() = profile[len(profile) - 1][0];
function profile_height() = z_max() - z_min();

function segment_at(z) =
    let(hits = [
        for (i = [0:len(profile) - 2])
            if (z <= profile[i + 1][0] || i == len(profile) - 2) i
    ])
    hits[0];

function catmull_rom(p0, p1, p2, p3, t) =
    let(t2 = t * t, t3 = t2 * t)
    0.5 * (
        (2 * p1)
        + (-p0 + p2) * t
        + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t2
        + (-p0 + 3 * p1 - 3 * p2 + p3) * t3
    );

function catmull_slope(p0, p1, p2, p3, t) =
    let(t2 = t * t)
    0.5 * (
        (-p0 + p2)
        + 2 * (2 * p0 - 5 * p1 + 4 * p2 - p3) * t
        + 3 * (-p0 + 3 * p1 - 3 * p2 + p3) * t2
    );

function sp_h(i) = profile[i + 1][0] - profile[i][0];
function sp_y(i) = profile[i][1];
function spline_m() = len(profile) - 2;
function sp_b(k) = 2 * (sp_h(k) + sp_h(k + 1));
function sp_c(k) = sp_h(k + 1);
function sp_rhs(k) =
    6 * ((sp_y(k + 2) - sp_y(k + 1)) / sp_h(k + 1)
        - (sp_y(k + 1) - sp_y(k)) / sp_h(k));

function sp_forward(k, cp, dp) =
    k >= spline_m() ? [cp, dp]
    : let(
        denom = sp_b(k) - (k == 0 ? 0 : sp_h(k) * cp[k - 1]),
        cpk = k == spline_m() - 1 ? 0 : sp_c(k) / denom,
        dpk = (sp_rhs(k) - (k == 0 ? 0 : sp_h(k) * dp[k - 1])) / denom
    )
    sp_forward(k + 1, concat(cp, [cpk]), concat(dp, [dpk]));

function sp_back(k, cp, dp, next) =
    k < 0 ? []
    : let(mk = dp[k] - cp[k] * next)
    concat(sp_back(k - 1, cp, dp, mk), [mk]);

function spline_moments() =
    len(profile) < 3 ? [for (i = [0:len(profile) - 1]) 0]
    : let(fd = sp_forward(0, [], []))
    concat([0], sp_back(spline_m() - 1, fd[0], fd[1], 0), [0]);

function spline_coeff(z) =
    let(
        i = segment_at(z),
        h = sp_h(i),
        M = spline_moments(),
        M0 = M[i],
        M1 = M[i + 1],
        y0 = sp_y(i),
        y1 = sp_y(i + 1)
    )
    [
        y0,
        (y1 - y0) / h - h * (2 * M0 + M1) / 6,
        M0 / 2,
        (M1 - M0) / (6 * h),
        z - profile[i][0]
    ];

function mono_h(i) = profile[i + 1][0] - profile[i][0];
function mono_delta(i) = (profile[i + 1][1] - profile[i][1]) / mono_h(i);

function mono_end(d0, d1, h0, h1) =
    let(m = ((2 * h0 + h1) * d0 - h0 * d1) / (h0 + h1))
    d0 == 0 ? 0
    : m * d0 <= 0 ? 0
    : (d0 * d1 <= 0 && abs(m) > abs(3 * d0)) ? 3 * d0
    : m;

function mono_interior(i) =
    let(d0 = mono_delta(i - 1), d1 = mono_delta(i))
    d0 * d1 <= 0 ? 0
    : let(
        h0 = mono_h(i - 1),
        h1 = mono_h(i),
        w1 = 2 * h1 + h0,
        w2 = h1 + 2 * h0
    )
    (w1 + w2) / (w1 / d0 + w2 / d1);

function mono_slopes() =
    let(n = len(profile))
    n < 3 ? [mono_delta(0), mono_delta(0)]
    : [for (i = [0:n - 1])
        i == 0 ? mono_end(mono_delta(0), mono_delta(1), mono_h(0), mono_h(1))
        : i == n - 1 ? mono_end(mono_delta(n - 2), mono_delta(n - 3), mono_h(n - 2), mono_h(n - 3))
        : mono_interior(i)];

function bs_knot(j) =
    let(n = len(profile))
    j <= 3 ? 0 : j >= n ? 1 : (j - 3) / (n - 3);

function bs_span(u, j) =
    j >= len(profile) - 1 ? len(profile) - 1
    : (bs_knot(j) <= u && u < bs_knot(j + 1)) ? j
    : bs_span(u, j + 1);

function bs_alpha(u, j, s, r) =
    let(den = bs_knot(j + 1 + s - r) - bs_knot(j - 3 + s))
    den == 0 ? 0 : (u - bs_knot(j - 3 + s)) / den;

function bezier_at(u) =
    let(
        s = 1 - u,
        b0 = s * s * s,
        b1 = 3 * s * s * u,
        b2 = 3 * s * u * u,
        b3 = u * u * u
    )
    b0 * profile[0] + b1 * profile[1] + b2 * profile[2] + b3 * profile[3];

function bspline_at(u) =
    u <= 0 ? profile[0]
    : u >= 1 ? profile[len(profile) - 1]
    : len(profile) == 4 ? bezier_at(u)
    : let(
        j = bs_span(u, 3),
        p0 = profile[j - 3],
        p1 = profile[j - 2],
        p2 = profile[j - 1],
        p3 = profile[j],
        a1 = bs_alpha(u, j, 1, 1),
        a2 = bs_alpha(u, j, 2, 1),
        a3 = bs_alpha(u, j, 3, 1),
        d1 = (1 - a1) * p0 + a1 * p1,
        d2 = (1 - a2) * p1 + a2 * p2,
        d3 = (1 - a3) * p2 + a3 * p3,
        b2 = bs_alpha(u, j, 2, 2),
        b3 = bs_alpha(u, j, 3, 2),
        e2 = (1 - b2) * d1 + b2 * d2,
        e3 = (1 - b3) * d2 + b3 * d3,
        c3 = bs_alpha(u, j, 3, 3)
    )
    (1 - c3) * e2 + c3 * e3;

function bs_find(z, lo, hi, n) =
    n <= 0 ? (lo + hi) / 2
    : let(mid = (lo + hi) / 2)
    bspline_at(mid)[0] < z ? bs_find(z, mid, hi, n - 1) : bs_find(z, lo, mid, n - 1);

function curve_name() =
    profile_curve == "usecky" || profile_curve == "interpolace"
        || profile_curve == "spline" || profile_curve == "monotonni"
        || profile_curve == "aproximace"
        ? (profile_curve == "aproximace" && len(profile) < 4 ? "interpolace" : profile_curve)
        : "interpolace";

function radius_at(z) =
    let(
        zc = min(max(z, z_min()), z_max()),
        i = segment_at(zc),
        z1 = profile[i][0],
        span = max(profile[i + 1][0] - z1, 0.001),
        t = (zc - z1) / span,
        mode = curve_name()
    )
    mode == "usecky" ? profile[i][1] + (profile[i + 1][1] - profile[i][1]) * t
    : mode == "spline" ? let(c = spline_coeff(zc))
        c[0] + c[1] * c[4] + c[2] * c[4] * c[4] + c[3] * c[4] * c[4] * c[4]
    : mode == "monotonni" ? let(
            h = span,
            t2 = t * t,
            t3 = t2 * t,
            m = mono_slopes()
        )
        profile[i][1] * (2 * t3 - 3 * t2 + 1)
            + m[i] * h * (t3 - 2 * t2 + t)
            + profile[i + 1][1] * (-2 * t3 + 3 * t2)
            + m[i + 1] * h * (t3 - t2)
    : mode == "aproximace" ? bspline_at(bs_find(zc, 0, 1, 20))[1]
    : let(
        p0 = profile[max(i - 1, 0)][1],
        p1 = profile[i][1],
        p2 = profile[i + 1][1],
        p3 = profile[min(i + 2, len(profile) - 1)][1]
    )
    catmull_rom(p0, p1, p2, p3, t);

// Sklon dr/dz. Kladný znamená, že se profil směrem nahoru rozšiřuje.
function radius_deriv(z) =
    let(
        zc = min(max(z, z_min()), z_max()),
        i = segment_at(zc),
        span = max(profile[i + 1][0] - profile[i][0], 0.001),
        t = (zc - profile[i][0]) / span,
        mode = curve_name()
    )
    mode == "usecky" ? (profile[i + 1][1] - profile[i][1]) / span
    : mode == "spline" ? let(c = spline_coeff(zc))
        c[1] + 2 * c[2] * c[4] + 3 * c[3] * c[4] * c[4]
    : mode == "monotonni" ? let(
            h = span,
            t2 = t * t,
            m = mono_slopes(),
            dh00 = 6 * t2 - 6 * t,
            dh10 = 3 * t2 - 4 * t + 1,
            dh01 = -6 * t2 + 6 * t,
            dh11 = 3 * t2 - 2 * t
        )
        (
            dh00 * profile[i][1]
            + dh10 * h * m[i]
            + dh01 * profile[i + 1][1]
            + dh11 * h * m[i + 1]
        ) / h
    : mode == "aproximace" ? let(
            u = bs_find(zc, 0, 1, 20),
            u0 = max(u - 0.002, 0),
            u1 = min(u + 0.002, 1),
            p0 = bspline_at(u0),
            p1 = bspline_at(u1)
        )
        (p1[1] - p0[1]) / max(p1[0] - p0[0], 0.001)
    : let(
        p0 = profile[max(i - 1, 0)][1],
        p1 = profile[i][1],
        p2 = profile[i + 1][1],
        p3 = profile[min(i + 2, len(profile) - 1)][1]
    )
    catmull_slope(p0, p1, p2, p3, t) / span;

function tangent_up(z) = v_unit([radius_deriv(z), 1]);

function sample_z(i) =
    z_min() + profile_height() * i / (profile_steps - 1);

function min_inner_radius() =
    min([for (i = [0:profile_steps - 1]) radius_at(sample_z(i)) - rib_depth]);

function max_outer_radius() =
    max([for (i = [0:profile_steps - 1]) radius_at(sample_z(i))]);

// Profilová souřadnice dna zářezu, než se žebro natočí.
function notch_x(i) =
    radius_at(center_height(i)) - rib_depth + center_notch(i);

// Vnější poloměr prstence. Po natočení leží na skutečné poloze dna zářezu.
function ring_outer_radius(i) = rib_radial(notch_x(i));

function rib_span_x() = max_outer_radius() - min_inner_radius();

// Svislá osa, kolem které se žebro naklopí. Vnitřní hrana zůstane na místě.
function rib_pivot_x() = min_inner_radius();

function rib_point_xy(x) =
    let(dx = x - rib_pivot_x())
    [rib_pivot_x() + dx * cos(rib_angle), dx * sin(rib_angle)];

function rib_radial(x) =
    let(p = rib_point_xy(x))
    sqrt(p * p);

function max_swung_radius() =
    max([for (i = [0:profile_steps - 1]) rib_radial(radius_at(sample_z(i)))]);
function sheet_ribs_width() = 2 * sheet_margin + rib_span_x();

function sheet_ribs_height() = 2 * sheet_margin + profile_height();

function rings_width() =
    2 * sheet_margin
    + [for (i = [0:center_count - 1]) 2 * ring_outer_radius(i)]
        * [for (i = [0:center_count - 1]) 1]
    + (center_count - 1) * part_gap;

function notch_band() = thickness + joint_clearance;

// Dva rohy na jednom konci se nesmí potkat. Když je zadaný poloměr moc velký, zmenší se.
function corners_fit(r) =
    r < 0.05 ? true
    : let(
        bo = corner_fillet(0, r),
        bi = corner_fillet(1, r),
        to = corner_fillet(2, r),
        ti = corner_fillet(3, r)
    )
    bo[1][0] - bi[1][0] > 0.2 && to[1][0] - ti[1][0] > 0.2;

function fit_corner_radius(lo, hi, n) =
    n <= 0 ? lo
    : let(mid = (lo + hi) / 2)
    corners_fit(mid)
        ? fit_corner_radius(mid, hi, n - 1)
        : fit_corner_radius(lo, mid, n - 1);

function used_corner_radius() =
    let(want = round_corners ? min(max(corner_radius, 0), rib_depth / 2 - 0.05) : 0)
    want < 0.05 ? 0
    : corners_fit(want) ? want
    : fit_corner_radius(0, want, 10);

function v_len(a) = sqrt(a * a);
function v_unit(a) = a / max(v_len(a), 0.001);
function v_dot(a, b) = a * b;
function ang_diff(a, b) =
    let(d = b - a)
    d > 180 ? d - 360 : d < -180 ? d + 360 : d;

function mm(n) = round(n * 10) / 10;

assert(len(profile) >= 2, "Profil potřebuje aspoň dva body");
assert(profile_steps >= 2, "Křivka profilu potřebuje aspoň dva kroky");
assert(rib_count >= 3, "Rotace potřebuje aspoň tři žebra");
assert(center_count >= 1, "Je potřeba aspoň jeden střed");
assert(rib_depth > 0, "Žebro musí mít kladnou hloubku");
assert(
    min([for (i = [0:len(profile) - 2]) profile[i + 1][0] - profile[i][0]]) > 0,
    "Výšky profilu musí růst"
);
assert(min_inner_radius() > 1, "Profil je moc úzký na tuhle hloubku žebra");

corner_r = used_corner_radius();

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
        center_height(i) - notch_band() / 2 >= z_min() + corner_r
            && center_height(i) + notch_band() / 2 <= z_max() - corner_r,
        str("Střed ", i + 1, " i se zářezem musí ležet mezi kulatými rohy")
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
echo(str("Objekt ", mm(2 * max_swung_radius()), " × ", mm(profile_height()),
    " mm (průměr × výška)"));
echo(str("Křivka profilu: ", curve_name()));
echo(str("Žeber: ", rib_count, ", natočení: ", rib_angle, " °, středů: ", center_count));
echo(str("Žebro na desce ", mm(rib_span_x()), " × ", mm(profile_height()), " mm"));
if (round_corners)
    echo(str("Zakulacení rohů: ", mm(corner_r), " mm"));
if (round_corners && corner_radius > corner_r + 0.05)
    echo(str("Varování: poloměr rohů je zkrácený na ", mm(corner_r),
        " mm, ať se rohy na konci žebra neslijí."));
for (i = [0:center_count - 1])
    echo(str("Střed ", i + 1, ": výška ", mm(center_height(i)),
        " mm, průměr ", mm(2 * ring_outer_radius(i)),
        " mm, zapuštění ", mm(center_notch(i)),
        " mm, ", ring_solid(i) ? "plný" : "věnec"));
if (flat_layout)
    echo(str("Deska žeber ", mm(sheet_ribs_width()), " × ", mm(sheet_ribs_height()),
        " mm, řada prstenců široká ", mm(rings_width()), " mm"));

function drop_near(points) =
    [for (i = [0:len(points) - 1])
        if (i == 0 ? true : v_len(points[i] - points[i - 1]) > 0.02)
            points[i]];

// which: 0 dolní vnější, 1 dolní vnitřní, 2 horní vnější, 3 horní vnitřní.
// Hledá výšku, kde má kružnice poloměru r tečnu k profilu i k rovnému konci.
function solve_corner_z(r, lo, hi, which, n) =
    n <= 0 ? (lo + hi) / 2
    : let(
        mid = (lo + hi) / 2,
        tx = tangent_up(mid)[0],
        err = which == 0 ? (mid - z_min()) - r * (1 - tx)
            : which == 1 ? (mid - z_min()) - r * (1 + tx)
            : which == 2 ? (z_max() - mid) - r * (1 + tx)
            : (z_max() - mid) - r * (1 - tx)
    )
    which < 2
        ? (err < 0
            ? solve_corner_z(r, mid, hi, which, n - 1)
            : solve_corner_z(r, lo, mid, which, n - 1))
        : (err < 0
            ? solve_corner_z(r, lo, mid, which, n - 1)
            : solve_corner_z(r, mid, hi, which, n - 1));

// [střed kružnice, bod na rovném konci, bod na profilu, ostrý roh]
function corner_fillet(which, r) =
    let(
        z_lo = which < 2 ? z_min() : (z_min() + z_max()) / 2,
        z_hi = which < 2 ? (z_min() + z_max()) / 2 : z_max(),
        zc = solve_corner_z(r, z_lo, z_hi, which, 16),
        T = tangent_up(zc),
        outer = which == 0 || which == 2,
        N = outer ? [-T[1], T[0]] : [T[1], -T[0]],
        P = [radius_at(zc) - (outer ? 0 : rib_depth), zc],
        center = P + N * r,
        cap_y = which < 2 ? z_min() : z_max(),
        sharp_z = which < 2 ? z_min() : z_max(),
        sharp = [radius_at(sharp_z) - (outer ? 0 : rib_depth), sharp_z]
    )
    [center, [center[0], cap_y], P, sharp];

// Kratší oblouk, ten blíž k ostrému rohu.
function fillet_arc(center, rad, start, end, prefer) =
    let(
        a0 = atan2(start[1] - center[1], start[0] - center[0]),
        a1 = atan2(end[1] - center[1], end[0] - center[0]),
        d = ang_diff(a0, a1),
        alt = d > 0 ? d - 360 : d + 360,
        mid1 = center + rad * [cos(a0 + d / 2), sin(a0 + d / 2)],
        mid2 = center + rad * [cos(a0 + alt / 2), sin(a0 + alt / 2)],
        use = v_len(mid1 - prefer) <= v_len(mid2 - prefer) ? d : alt,
        steps = max(8, ceil(rad * 2))
    )
    concat(
        [start],
        [for (s = [1:steps - 1])
            center + rad * [cos(a0 + use * s / steps), sin(a0 + use * s / steps)]],
        [end]
    );

function edge_samples(z0, z1, x_offset) =
    [for (i = [0:profile_steps - 1])
        let(z = z0 + (z1 - z0) * i / (profile_steps - 1))
        [radius_at(z) + x_offset, z]];

// Hladká křivka profilu a čtyři kulaté rohy. Zářezy na středy se nezaoblují.
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
        r = corner_r
    )
    r < 0.05 ? concat(outer, inner)
    : let(
        bo = corner_fillet(0, r),
        bi = corner_fillet(1, r),
        to = corner_fillet(2, r),
        ti = corner_fillet(3, r)
    )
    drop_near(concat(
        fillet_arc(bo[0], r, bo[1], bo[2], bo[3]),
        edge_samples(bo[2][1], to[2][1], 0),
        fillet_arc(to[0], r, to[2], to[1], to[3]),
        fillet_arc(ti[0], r, ti[1], ti[2], ti[3]),
        edge_samples(ti[2][1], bi[2][1], -rib_depth),
        fillet_arc(bi[0], r, bi[2], bi[1], bi[3])
    ));

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

// Zářez sleduje sklon žebra. Dlouhý je jen jako zapuštění a otevře obvod.
module ring_slot(i) {
    x0 = notch_x(i) - center_notch(i) - 0.2;
    x1 = notch_x(i) + 0.2;
    p0 = rib_point_xy(x0);
    p1 = rib_point_xy(x1);
    dir = p1 - p0;
    perp = [-dir[1], dir[0]] / max(sqrt(dir * dir), 0.001) * notch_band() / 2;
    polygon([
        p0 + perp,
        p1 + perp,
        p1 - perp,
        p0 - perp
    ]);
}

module ring_2d(i) {
    outer_r = ring_outer_radius(i);
    inner_r = outer_r - ring_width;
    difference() {
        circle(r = outer_r, $fn = 96);
        if (!ring_solid(i))
            circle(r = inner_r, $fn = 96);
        for (n = [0:rib_count - 1])
            rotate(n * 360 / rib_count)
                ring_slot(i);
    }
}

function show_ribs() = show_parts != "rafky";
function show_rings() = show_parts != "zebra";

module assembled() {
    if (show_ribs())
        color("#e4c79a")
            for (n = [0:rib_count - 1])
                rotate([0, 0, n * 360 / rib_count])
                    translate([rib_pivot_x(), 0, 0])
                        rotate([0, 0, rib_angle])
                            translate([-rib_pivot_x(), 0, 0])
                                rotate([90, 0, 0])
                                    linear_extrude(thickness, center = true)
                                        rib_2d();
    if (show_rings())
        color("#c49658")
            for (i = [0:center_count - 1])
                translate([0, 0, center_height(i)])
                    linear_extrude(thickness, center = true)
                        ring_2d(i);
}

module flat_sheet() {
    if (show_ribs())
        translate([
            sheet_margin - min_inner_radius(),
            sheet_margin - z_min()
        ])
            laser_cut()
                rib_2d();

    ring_y = show_ribs()
        ? sheet_ribs_height() - sheet_margin + part_gap
        : sheet_margin;
    if (show_rings())
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
