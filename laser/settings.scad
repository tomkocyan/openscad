// Jediné místo pro tloušťku, kerf a mezery na desce. Jednotky jsou milimetry.
// Modely to vloží přes include <settings.scad>. V jejich Customizeru se to neukáže.

/* [Materiál a laser] */
// Tloušťka překližky v mm. Změřená deska.
thickness = 3.33; // [1:0.01:8]

// Šířka řezu v mm. Čtverec dal 0,15. O dvě setiny víc, ať spoj drží i bez lepidla.
kerf = 0.17; // [0:0.01:0.4]

// O kolik je zářez širší než prst, v mm. 0 je těsný spoj po kompenzaci kerfu.
joint_clearance = 0.1; // [0:0.01:0.4]

// Barva řezu v náhledu. Do DXF a SVG se nepropíše.
cut_color = "#e10600";

/* [Deska] */
// Mezera mezi hotovými obrysy v mm. Řez do ní sahá polovinou kerfu z každé strany.
part_gap = 8; // [2:1:30]

// Okraj od počátku souřadnic k hotovému obrysu v mm
sheet_margin = 5; // [0:1:30]

assert(thickness > 0, "Tloušťka materiálu musí být kladná");
assert(kerf >= 0 && kerf < thickness, "Kerf musí být nezáporný a menší než tloušťka");
assert(joint_clearance >= 0, "Vůle spoje musí být nezáporná");
assert(part_gap > kerf, "Mezera mezi díly musí být větší než kerf");
assert(sheet_margin >= 0, "Okraj desky musí být nezáporný");

// Vypíše se v logu každého modelu. Volá se z něj, ať je nastavení u rozměrů.
module log_laser() {
    echo("—— laser ——");
    echo(str("Překližka ", thickness, " mm, kerf ", kerf,
        " mm, vůle spoje ", joint_clearance, " mm"));
    echo(str("Deska: mezera ", part_gap, " mm, okraj ", sheet_margin, " mm"));
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

// Řez pro výkres: červený v náhledu a rozšířený o kerf.
module laser_cut() {
    color(cut_color)
        cut_outline()
            children();
}
