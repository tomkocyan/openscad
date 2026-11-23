// Rotační objekt z překližky, třeba stínidlo lampy. Jednotky jsou milimetry.
// Profil je jedno ploché žebro. Kolem osy se zopakuje rib_count kusů.
// rib_angle 0 je kolmo k obvodu, světlo jde rovnou ven. Natočení průhled zacloní.
// Žebra drží vodorovné středy. O díru se dělí napůl: vnitřní půlka na žebru,
// vnější na prstenci. Šířka zářezu je tloušťka desky, ať do sebe zaklesnou.
//
// Profil i středy se upravují tady v souboru, ne v Customizeru.
// Profil je [výška, poloměr] odspodu, výšky musí růst. Způsob křivky je v Customizeru.
// Střed je [výška, zapuštění, plný, šířka]. Šířka je ring_width, číslo jen když se liší.
// Žebro má čtyři kulaté rohy, dva nahoře a dva dole.
// Zapni rozložení a exportuj DXF nebo SVG. Vypni ho pro složený náhled.
// Kerf a tloušťka jsou v settings.scad. Tady to neměň.

include <settings.scad>

/* [Profil] */
// usecky = lomené úsečky. interpolace = hladce skrz body.
// spline = kubický spline skrz body, může překmitnout. monotonni = skrz body bez překmitu.
// aproximace = B-spline, vnitřními body neprojde.
profile_curve = "aproximace"; // [usecky, interpolace, spline, monotonni, aproximace]

// Kolik úseček má křivka mezi konci. Víc = hladší řez.
profile_steps = 48; // [8:1:120]

// Hloubka žebra v mm. Jestli po poloměru nebo kolmo na profil, volí se pod tím.
rib_depth = 20; // [6:1:40]

// vodorovne = stejný úbytek poloměru. kolmo = stejná šířka napříč pásem.
rib_measure = "kolmo"; // [vodorovne, kolmo]

// Čtyři kulaté rohy: dva nahoře, dva dole. Zářezy na středy zůstanou ostré.
round_corners = true;

// Poloměr těch čtyř rohů v mm. Nejvýš polovina hloubky žebra.
corner_radius = 6; // [0:0.5:20]

// Rohy profilu, které nejsou na konci žebra. U úseček se zakulatí obě hrany.
round_bends = false;

// Poloměr těch rohů v mm. Hladká křivka lomy nemá, tam se neprojeví.
bend_radius = 8; // [0:0.5:40]

/* [Rotace] */
// Počet žeber kolem osy
rib_count = 18; // [3:1:48]

// Natočení žeber ve stupních. 0 je kolmo, kladné je po směru hodin.
// Lamely se točí kolem vnitřní hrany, ať mezi nimi není přímý průhled ven.
rib_angle = 0; // [-75:1:75]

/* [Rozložení] */
// Co kreslit: zebra, rafky, nebo oboji.
show_parts = "oboji"; // [zebra, rafky, oboji]

// Díly na desce. Vypni pro složený objekt.
// Žebro je tam jen jedno, jsou všechna stejná. Ráfky jsou všechny, liší se.
flat_layout = false;

// Křížek 10 mm ve středu každého kruhu na desce. Vypni, když značky nechceš.
mark_centers = true;

/* [Hidden] */
// [výška, vnější poloměr] odspodu. Customizer seznamy přepisuje, proto je profil skrytý.
profile = [
    [0, 50],
    [20, 70],
    [50, 100],
    [80, 60],
    [150, 50],

];

// Šířka věnce v mm. U plného kotouče se nepoužije.
// V poli ji nech jako ring_width a číslo napiš jen tam, kde má být jiná.
ring_width = 18;
centers = [
    [20, 14, true, ring_width],
    [30, 14, false, ring_width],
    [100, 14, false, ring_width]
];

center_count = len(centers);

function center_height(i) = centers[i][0];
function center_notch(i) = centers[i][1];
function ring_solid(i) = centers[i][2];
function ring_width_of(i) = centers[i][3];

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

function rib_kolmo() = rib_measure == "kolmo";

// Vnitřní hrana. Vodorovně je to profil minus hloubka.
// Kolmo je offset celé křivky o hloubku žebra.
function inner_x(z) =
    rib_kolmo() ? band_x(inner_band, z) : radius_at(z) - rib_depth;

function inner_tangent(z) =
    rib_kolmo() ? band_tan(inner_band, z) : tangent_up(z);

function sample_z(i) =
    z_min() + profile_height() * i / (profile_steps - 1);

function min_inner_radius() =
    rib_kolmo()
        ? min([for (p = inner_band) p[0]])
        : min([for (i = [0:profile_steps - 1]) radius_at(sample_z(i)) - rib_depth]);

function max_outer_radius() =
    max([for (i = [0:profile_steps - 1]) radius_at(sample_z(i))]);

// Vnější konec zapuštění, než se žebro natočí. Prstenec sem dosahuje.
function notch_x(i) = inner_x(center_height(i)) + center_notch(i);

// Půlka, kde se zářez žebra potká se zářezem prstence.
function notch_mid_x(i) = notch_x(i) - center_notch(i) / 2;

// Vnější poloměr prstence. Po natočení leží na vnějším konci zapuštění.
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

function profile_xy() =
    [for (i = [0:len(profile) - 1]) [profile[i][1], profile[i][0]]];

// Oblouk místo ostrého lomu. Když se na úsečku nevejde, zmenší se.
function bend_arc(prev, here, next) =
    let(
        d1 = v_unit(here - prev),
        d2 = v_unit(next - here),
        dot = min(1, max(-1, d1 * d2)),
        delta = acos(dot),
        room = min(v_len(here - prev), v_len(next - here)) * 0.45,
        back = min(bend_radius * tan(min(delta, 160) / 2), room)
    )
    delta < 8 || back < 0.3 ? [here]
    : let(
        p0 = here - d1 * back,
        p1 = here + d2 * back,
        turn = d1[0] * d2[1] - d1[1] * d2[0],
        n = turn >= 0 ? [-d1[1], d1[0]] : [d1[1], -d1[0]],
        rad = back / tan(delta / 2),
        center = p0 + n * rad
    )
    fillet_arc(center, rad, p0, p1, here);

function fillet_poly(pts) =
    let(n = len(pts))
    n < 3 ? pts
    : concat(
        [pts[0]],
        [for (i = [1:n - 2]) each bend_arc(pts[i - 1], pts[i], pts[i + 1])],
        [pts[n - 1]]
    );

function bends_on() = round_bends && bend_radius > 0.05 && curve_name() == "usecky";

function outer_pts() =
    curve_name() == "usecky"
        ? (bends_on() ? fillet_poly(profile_xy()) : profile_xy())
        : [for (i = [0:profile_steps - 1]) [radius_at(sample_z(i)), sample_z(i)]];

function seg_tan(a, b) = v_unit(b - a);
function seg_inward(t) = [-t[1], t[0]];

// Konec rovnoběžky oříznutý vodorovným koncem žebra.
function cap_point(a, b, z_cap, dist) =
    let(
        t = seg_tan(a, b),
        p = a + seg_inward(t) * dist,
        s = (z_cap - p[1]) / (abs(t[1]) < 0.001 ? 1 : t[1])
    )
    [p[0] + t[0] * s, z_cap];

// Ostrý vnitřní roh. Úsečky se lomí na obou stranách stejně.
function miter_point(prev, here, next, dist) =
    let(
        n0 = seg_inward(seg_tan(prev, here)),
        n1 = seg_inward(seg_tan(here, next)),
        sum = n0 + n1,
        bis = v_unit(sum),
        denom = bis * n0
    )
    v_len(sum) < 0.2 || denom < 0.2
        ? here + n0 * dist
        : here + bis * min(dist / denom, dist * 4);

function miter_band() =
    let(o = profile_xy(), n = len(o), d = rib_depth)
    concat(
        [cap_point(o[0], o[1], z_min(), d)],
        [for (i = [1:n - 2]) miter_point(o[i - 1], o[i], o[i + 1], d)],
        [cap_point(o[n - 2], o[n - 1], z_max(), d)]
    );

// Nejlevější bod kružnice o poloměru hloubky žebra. Mimo výšku kružnice nic.
function cover_left(c, z) =
    let(dy = z - c[1], h2 = rib_depth * rib_depth - dy * dy)
    h2 <= 0 ? 1e9 : c[0] - sqrt(h2);

// Offset křivky: v dané výšce nejlevější bod, který je od profilu přesně o hloubku.
function envelope_x(z, pts) = min([for (c = pts) cover_left(c, z)]);

function band_hit(pts, z, i) =
    i >= len(pts) - 2 ? i
    : z <= pts[i + 1][1] ? i
    : band_hit(pts, z, i + 1);

function band_x(pts, z) =
    let(
        i = band_hit(pts, z, 0),
        a = pts[i],
        b = pts[min(i + 1, len(pts) - 1)],
        dz = b[1] - a[1],
        t = abs(dz) < 0.001 ? 0 : (z - a[1]) / dz
    )
    a[0] + (b[0] - a[0]) * t;

function band_tan(pts, z) =
    let(
        i = band_hit(pts, z, 0),
        d = pts[min(i + 1, len(pts) - 1)] - pts[i],
        u = v_unit(d)
    )
    u[1] < 0 ? -u : u;
function v_dot(a, b) = a * b;
function ang_diff(a, b) =
    let(d = b - a)
    d > 180 ? d - 360 : d < -180 ? d + 360 : d;

function mm(n) = round(n * 10) / 10;

// Husté vzorky křivky, ať offset v ohybu nevyjde jako úsečka.
offset_count = max(profile_steps, ceil(profile_height()));
offset_pts = [
    for (i = [0:offset_count])
        let(z = z_min() + profile_height() * i / offset_count)
        [radius_at(z), z]
];
// Úsečky mají ostrý offset. Hladká křivka má obloukový, ať vnitřek nezůstane lomený.
inner_band = !rib_kolmo() ? []
    : curve_name() == "usecky"
        ? (bends_on() ? fillet_poly(miter_band()) : miter_band())
        : [for (p = offset_pts) [envelope_x(p[1], offset_pts), p[1]]];

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
        assert(ring_width_of(i) > center_notch(i) / 2,
            str("Prstenec ", i + 1, " je užší než polovina zapuštění a rozpadl by se"));
        assert(ring_outer_radius(i) > ring_width_of(i),
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
echo(str("Žebro na desce ", mm(rib_span_x()), " × ", mm(profile_height()),
    " mm, hloubka ", mm(rib_depth), " mm ",
    rib_kolmo() ? "kolmo na profil" : "vodorovně"));
if (round_corners)
    echo(str("Zakulacení rohů: ", mm(corner_r), " mm"));
if (bends_on())
    echo(str("Zakulacení lomů profilu: ", mm(bend_radius), " mm"));
if (round_corners && corner_radius > corner_r + 0.05)
    echo(str("Varování: poloměr rohů je zkrácený na ", mm(corner_r),
        " mm, ať se rohy na konci žebra neslijí."));
for (i = [0:center_count - 1])
    echo(str("Střed ", i + 1, ": výška ", mm(center_height(i)),
        " mm, průměr ", mm(2 * ring_outer_radius(i)),
        " mm, zapuštění ", mm(center_notch(i)),
        " mm, ", ring_solid(i) ? "plný" : str("věnec ", mm(ring_width_of(i)), " mm")));
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
        tx = (which == 1 || which == 3 ? inner_tangent(mid) : tangent_up(mid))[0],
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
        outer = which == 0 || which == 2,
        T = outer ? tangent_up(zc) : inner_tangent(zc),
        N = outer ? [-T[1], T[0]] : [T[1], -T[0]],
        P = [outer ? radius_at(zc) : inner_x(zc), zc],
        center = P + N * r,
        cap_y = which < 2 ? z_min() : z_max(),
        sharp_z = which < 2 ? z_min() : z_max(),
        sharp = [outer ? radius_at(sharp_z) : inner_x(sharp_z), sharp_z]
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

function edge_samples(z0, z1, inner) =
    [for (i = [0:profile_steps - 1])
        let(z = z0 + (z1 - z0) * i / (profile_steps - 1))
        [inner ? inner_x(z) : radius_at(z), z]];

function clip_band(pts, z0, z1) =
    [for (p = pts) if (p[1] > z0 + 0.02 && p[1] < z1 - 0.02) p];

// Hladká křivka profilu a čtyři kulaté rohy. Zářezy na středy se nezaoblují.
function rib_points() =
    let(
        outer = outer_pts(),
        inner = rib_kolmo()
            ? inner_band
            : [for (p = outer) [p[0] - rib_depth, p[1]]],
        r = corner_r
    )
    r < 0.05
        ? concat(outer, [for (i = [len(inner) - 1:-1:0]) inner[i]])
        : let(
            bo = corner_fillet(0, r),
            bi = corner_fillet(1, r),
            to = corner_fillet(2, r),
            ti = corner_fillet(3, r)
        )
        drop_near(concat(
            fillet_arc(bo[0], r, bo[1], bo[2], bo[3]),
            rib_kolmo()
                ? clip_band(outer, bo[2][1], to[2][1])
                : edge_samples(bo[2][1], to[2][1], false),
            fillet_arc(to[0], r, to[2], to[1], to[3]),
            fillet_arc(ti[0], r, ti[1], ti[2], ti[3]),
            rib_kolmo()
                ? [for (i = [len(inner) - 1:-1:0])
                    if (inner[i][1] < ti[2][1] - 0.02 && inner[i][1] > bi[2][1] + 0.02)
                        inner[i]]
                : edge_samples(ti[2][1], bi[2][1], true),
            fillet_arc(bi[0], r, bi[2], bi[1], bi[3])
        ));

module rib_2d() {
    difference() {
        polygon(rib_points());
        for (i = [0:center_count - 1])
            rib_notch(i);
    }
}

// Vnitřní polovina zapuštění. Obroučka je vodorovná, zářez taky.
// Ústa jedou po hraně, dno je v polovině hloubky spoje.
module rib_notch(i) {
    h = center_height(i);
    half = notch_band() / 2;
    floor_x = notch_mid_x(i);
    steps = 4;
    polygon(concat(
        [for (k = [0:steps])
            let(z = h - half + notch_band() * k / steps)
            [inner_x(z) - 1, z]],
        [[floor_x, h + half], [floor_x, h - half]]
    ));
}

// Vnější polovina zapuštění. Šířka je tloušťka desky a zářez sleduje sklon žebra.
// Kousek přes obvod, ať je zářez otevřený a žebro do něj vejde.
module ring_slot(i) {
    x0 = notch_mid_x(i);
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
    inner_r = outer_r - ring_width_of(i);
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

// Značka středu. Tenká, bez kerfu, ať průsečík sedí na ose kruhu.
module center_cross() {
    color("#222222") {
        square([10, 1], center = true);
        square([1, 10], center = true);
    }
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
                if (mark_centers && ring_solid(i))
                    difference() {
                        laser_cut()
                            ring_2d(i);
                        center_cross();
                    }
                else {
                    laser_cut()
                        ring_2d(i);
                    if (mark_centers)
                        center_cross();
                }
        }
}

if (flat_layout)
    flat_sheet();
else
    assembled();
