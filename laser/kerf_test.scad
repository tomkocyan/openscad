// Zkouška kerfu pro překližku. Jednotky jsou milimetry.
// Čtverec je bez kompenzace. Kerf = nakreslená strana minus změřená šířka.
// Každý zářez je kompenzovaný svým číslem. Do něj zastrč hranu téže desky.
// Prostřední zářez používá kerf z nastavení. Doleva je volnější, doprava těsnější.
// Čísla jsou vyříznutá v dílu. V LightBurnu nech kerf na nule.
// Tloušťku v nastavení nastav na změřenou desku, jinak sedne jiný zářez než čtverec.

include <settings.scad>

/* [Zkouška] */
// Strana čtverce bez kompenzace, v mm. Tu pak změř.
square_size = 50; // [30:1:100]

// Počet zářezů. Prostřední má kerf z nastavení.
sample_count = 7; // [3:2:11]

// O kolik mm se sousední zářezy liší.
kerf_step = 0.02; // [0.01:0.01:0.05]

// Jak hluboko zářez jde, v mm. Aby se do něj vešla hrana desky.
slot_depth = 15; // [8:1:40]

// Materiál vedle zářezu, v mm.
side_wall = 8; // [7:1:20]

/* [Hidden] */

function sample_n() = sample_count % 2 == 0 ? sample_count + 1 : sample_count;

function trial_kerf(i) = max(0, kerf + (i - floor(sample_n() / 2)) * kerf_step);

function coupon_w() = thickness + 2 * side_wall;

function coupon_h() = slot_depth + side_wall;

function label(v) =
    let (h = round(v * 100))
    str(floor(h / 100), ".", (h % 100) < 10 ? "0" : "", h % 100);

// Sedmisegmentovka. Písmo z OpenSCAD se do DXF nezapíše.
digit_w = 3.5;
digit_h = 5.6;
digit_t = 0.8;
digit_bits = [
    [1, 1, 1, 1, 1, 1, 0],
    [0, 1, 1, 0, 0, 0, 0],
    [1, 1, 0, 1, 1, 0, 1],
    [1, 1, 1, 1, 0, 0, 1],
    [0, 1, 1, 0, 0, 1, 1],
    [1, 0, 1, 1, 0, 1, 1],
    [1, 0, 1, 1, 1, 1, 1],
    [1, 1, 1, 0, 0, 0, 0],
    [1, 1, 1, 1, 1, 1, 1],
    [1, 1, 1, 1, 0, 1, 1]
];

function char_advance(c) = c == "." ? 1.5 : digit_w + 0.4;

function text_w(s, i = 0) =
    i >= len(s) ? -0.4 : char_advance(s[i]) + text_w(s, i + 1);

module digit(d) {
    b = digit_bits[d];
    if (b[0]) translate([0, digit_h - digit_t]) square([digit_w, digit_t]);
    if (b[1]) translate([digit_w - digit_t, digit_h / 2]) square([digit_t, digit_h / 2]);
    if (b[2]) translate([digit_w - digit_t, 0]) square([digit_t, digit_h / 2]);
    if (b[3]) translate([0, 0]) square([digit_w, digit_t]);
    if (b[4]) translate([0, 0]) square([digit_t, digit_h / 2]);
    if (b[5]) translate([0, digit_h / 2]) square([digit_t, digit_h / 2]);
    if (b[6]) translate([0, digit_h / 2 - digit_t / 2]) square([digit_w, digit_t]);
}

module glyphs(s, i = 0) {
    if (i < len(s)) {
        if (s[i] == ".")
            translate([0.25, 0]) square([0.9, 0.9]);
        else
            digit(ord(s[i]) - ord("0"));
        translate([char_advance(s[i]), 0])
            glyphs(s, i + 1);
    }
}

module centered_label(s, scale = 1) {
    scale(scale)
        translate([-text_w(s) / 2, -digit_h / 2])
            glyphs(s);
}

module fit_coupon(amount) {
    difference() {
        square([coupon_w(), coupon_h()]);
        translate([(coupon_w() - thickness) / 2, side_wall])
            square([thickness, slot_depth + 1]);
        translate([coupon_w() / 2, side_wall / 2])
            centered_label(label(amount), min(1, (side_wall - 1.4) / digit_h));
    }
}

module cut_trial(amount) {
    color(cut_color)
        offset(delta = amount / 2)
            nominal_outline()
                children();
}

module square_part() {
    color(cut_color)
        difference() {
            square([square_size, square_size]);
            translate([square_size / 2, square_size / 2])
                centered_label(str(square_size), 2.4);
        }
}

module coupon_part(amount) {
    cut_trial(amount)
        fit_coupon(amount);
}

row_y = sheet_margin;
square_y = row_y + coupon_h() + part_gap;

translate([sheet_margin, square_y])
    square_part();

for (i = [0 : sample_n() - 1])
    translate([sheet_margin + i * (coupon_w() + part_gap), row_y])
        coupon_part(trial_kerf(i));

assert(sample_count >= 3, "Zářezů musí být aspoň tři");
assert(kerf_step > 0, "Krok kerfu musí být kladný");
assert(square_size > 20, "Čtverec je moc malý na měření");
assert(slot_depth > thickness, "Zářez musí být hlubší než tloušťka");
assert(side_wall >= 7, "Stěna vedle zářezu je moc úzká na číslo");
assert(kerf + floor(sample_n() / 2) * kerf_step < thickness - 0.4,
    "Krajní kerf by zářez zavřel. Zmenši krok nebo počet.");

log_laser();
echo(str("Čtverec bez kompenzace, strana ", square_size,
    " mm. Kerf = ", square_size, " minus změřená šířka."));
echo(str("Zářezy zleva, v mm: ",
    [for (i = [0 : sample_n() - 1]) label(trial_kerf(i))]));
echo(str("Prostřední zářez je kerf z nastavení, ", label(kerf),
    " mm. Doleva volnější, doprava těsnější."));
echo("Čísla jsou vyříznutá v dílech. V LightBurnu nech kerf na nule.");

row_w = sample_n() * coupon_w() + (sample_n() - 1) * part_gap;
span_x = sheet_margin + max(square_size, row_w);
span_y = square_y + square_size;
$vpr = [0, 0, 0];
$vpt = [span_x / 2, span_y / 2, 0];
$vpd = max(span_x, span_y) * 1.4;
