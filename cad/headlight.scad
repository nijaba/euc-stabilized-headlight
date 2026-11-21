// EUC Stabilized Headlight: packaging model (phase 1), layout v2.
//
// v2 (owner's requirements, 2026-11-21): the heatsink is at the BOTTOM with its
// fins running fore-aft, along the direction of travel. The LEDs face up and the
// mirror above them folds the beam forward.
//
// Every bought part is a simple solid at its datasheet size; printed parts are
// shells. It checks fit, sweep and mass. It isn't the printable housing yet.
//
// Axes: x = left-right (mirror pivot axis), y = forward (beam leaves at +y),
// z = up. Origin: centre of the LED plane (top of the heatsink base).
//
// Render with cad/render.sh. Variables below can be overridden with -D.

/* [View] */
view = "assembly";   // assembly | cutaway | exploded | front | under | wheel
tilt = 0;            // mirror tilt from nominal, degrees (-7.5 .. 7.5)
show_beams = true;

/* [Configuration] */
n_fil = 2;            // FILIPPA low-beam optics (1 or 2)
n_spot = 2;           // spot optics (0, 1 or 2)
lidar_on_head = true; // false: lidar mounted separately on the wheel shell

/* [Optics] (design §3) */
fil_d = 32.9;   fil_h = 18.5;      // LEDiL FILIPPA-STVZO
spot_d = 20;    spot_h = 14;       // Carclo 10003 in 10734 holder
star_d = 20;    star_t = 1.6;      // 20 mm copper DTP board
opt_gap = 2;
fil_fwtm = 16.5;  spot_fwtm = 6;   // half-angles used for clearance

/* [Mirror] (design §2) */
mir_t = 1.1;                       // 1.1 mm front-surface glass
mir_W = 55;
tilt_max = 7.5;
steer = 2 * tilt_max;
cradle_t = 2;
mir_clear = 3;

/* [Housing] (design §5) */
wall = 2.0;
front_clear = 3;
elec_depth = 20;
win_t = 2.0;
bezel_lip = 4;

/* [Heatsink] sized for moving air; firmware derates when parked */
hs_base = 3;  hs_fin_h = 14;  hs_fin_t = 1.2;  hs_pitch = 8;  hs_margin = 6;

/* [Bought parts] */
servo = [12, 23, 24];              // EMAX ES08MD II: W(y) x L(z) x H(x)
xiao  = [21, 17.8, 4];
bbk   = [32, 22, 10];
pol   = [25.4, 17.8, 6];
imu   = [25.6, 17.8, 3];
lidar = [69, 41.5, 26];            // Benewake TF02-Pro: x, z, y

// ---------- optic row ----------
SPOT = [0, spot_d, spot_h];  FIL = [1, fil_d, fil_h];
optics_list = concat(n_spot >= 2 ? [SPOT] : [], [for (i = [1:n_fil]) FIL], n_spot >= 1 ? [SPOT] : []);
n_opt = len(optics_list);
function sum_d(l, i) = i < 0 ? 0 : l[i][1] + sum_d(l, i-1);
row_L = sum_d(optics_list, n_opt-1) + (n_opt-1)*opt_gap;
function x_at(i) = -row_L/2 + (i == 0 ? 0 : sum_d(optics_list, i-1) + i*opt_gap) + optics_list[i][1]/2;
max_h = max([for (o = optics_list) o[2]]);

mir_L = row_L + 2;

// ---------- mirror (normal points forward-down; plate runs back-low → front-high) ----------
function half_z(a) = (mir_W/2)*sin(45 + a) + mir_t;
function half_y(a) = (mir_W/2)*cos(45 - a);
mir_z  = star_t + max_h + mir_clear + half_z(tilt_max);
mir_hy = half_y(tilt_max);

in_front = mir_hy + front_clear;
in_back  = -(mir_hy + elec_depth);
win_d    = in_front;

// Inner length: the mirror and its bearing bosses, or the beam's spread at the window, whichever is wider.
function reach(o, x) = abs(x) + o[1]/2 + win_d*tan(o[0] == 1 ? fil_fwtm : spot_fwtm);
beam_reach = max([for (i = [0:n_opt-1]) reach(optics_list[i], x_at(i))]);
in_L     = max(mir_L + 2*(cradle_t + 3), 2*beam_reach + 2);

win_half = fil_d/2 + win_d*tan(steer) + win_d*tan(fil_fwtm);
win_zc   = mir_z;
win_top  = win_zc + win_half;
win_bot  = win_zc - win_half;
top_z    = max(win_top + bezel_lip, mir_z + half_z(tilt_max) + 2) + wall;

out_L = in_L + 2*wall;
out_D = in_front - in_back + 2*wall;
out_H = top_z + wall;                                // floor wall below z=0

// Heatsink: under the optic zone only; the rest of the floor is printed.
hs_L = out_L;
hs_D = fil_d + 2*hs_margin;
hs_y0 = -hs_D/2;
hs_fins = floor((hs_L - hs_fin_t) / hs_pitch) + 1;

// ---------- checks (C-PKG) ----------
mir_low = mir_z - half_z(tilt_max);
assert(row_L <= mir_L,             str("C-PKG-01 optic row ", row_L, " mm longer than mirror ", mir_L));
assert(mir_hy + 1 < in_front,      "C-PKG-02 mirror hits the front wall at full tilt");
assert(-mir_hy - 1 > in_back + 12, "C-PKG-03 mirror sweeps into the electronics slot");
assert(win_bot > wall + 1 && mir_low > star_t + max_h + 1, "C-PKG-04 window or mirror runs into the optics or floor");
assert(beam_reach <= in_L/2,       str("C-PKG-05 beam wider than the window: ", 2*beam_reach));
assert(servo[0] <= elec_depth - 2, "C-PKG-06 servo does not fit the back slot");
assert(hs_D <= out_D - 2*wall,     "C-PKG-07 heatsink wider than the floor");

lidar_pod_area = lidar_on_head ? 2*(lidar[0]*lidar[2] + lidar[0]*lidar[1]) : 0;
echo(str("PKG config=", n_fil, "F+", n_spot, "S", lidar_on_head ? "+lidar" : "",
         " body_outer_mm=", out_L, "x", out_D, "x", out_H,
         " head_height_mm=", out_H + hs_base + hs_fin_h + (lidar_on_head ? lidar[1] + wall : 0),
         " window_mm=", in_L, "x", 2*win_half, " mirror_mm=", mir_L, "x", mir_W,
         " heatsink_mm=", hs_L, "x", hs_D, " fins=", hs_fins, " fore-aft"));
echo(str("MASS n_fil=", n_fil, " n_spot=", n_spot, " lidar=", lidar_on_head ? 1 : 0,
         " wall_mm=", wall,
         " shell_area_mm2=", out_L*out_D*2 - hs_L*hs_D + 2*out_L*out_H + 2*out_D*out_H,
         " lidar_pod_area_mm2=", lidar_pod_area,
         " window_mm3=", (in_L + 2*bezel_lip)*(2*win_half + 2*bezel_lip)*win_t,
         " hs_mm3=", hs_L*hs_D*hs_base + hs_fins*hs_fin_t*hs_D*hs_fin_h,
         " mirror_mm3=", mir_L*mir_W*mir_t, " shaft_mm=", in_L,
         " seal_mm=", 2*(out_L + out_D) + 2*(hs_L + hs_D)));

// ---------- colours ----------
c_alu = [0.75,0.77,0.80]; c_asa = [0.18,0.19,0.21]; c_asa_in = [0.05,0.05,0.06];
c_pmma = [0.85,0.92,1.0,0.75]; c_led = [0.95,0.85,0.3]; c_pcb = [0.1,0.45,0.25];
c_mirror = [0.85,0.9,0.95]; c_beam_lo = [1,0.95,0.6,0.18]; c_beam_hi = [0.7,0.85,1,0.15];

// ---------- parts ----------
module heatsink() color(c_alu) {
    translate([-hs_L/2, hs_y0, -hs_base]) cube([hs_L, hs_D, hs_base]);
    for (i = [0:hs_fins-1])                                   // fins run fore-aft (along y)
        translate([-hs_L/2 + i*hs_pitch, hs_y0, -hs_base - hs_fin_h]) cube([hs_fin_t, hs_D, hs_fin_h]);
}

module led_star(x) {
    color(c_pcb) translate([x,0,0]) cylinder(d=star_d, h=star_t, $fn=40);
    color(c_led) translate([x-2.5,-2.5,star_t]) cube([5,5,1.3]);
}

module filippa(x) color(c_pmma) translate([x,0,star_t]) {
    cylinder(d=fil_d, h=1.5, $fn=60);                                       // flange
    translate([0,0,1.5]) cylinder(d1=fil_d*0.8, d2=fil_d*0.62, h=fil_h-1.5, $fn=60);
    translate([-1.55, fil_d/2-1, 0]) cube([3.1,2,1.5]);                     // orienting rib → front (window)
}

module spot_optic(x) color(c_pmma) translate([x,0,star_t]) cylinder(d1=spot_d, d2=spot_d*0.75, h=spot_h, $fn=50);

module optics() {
    for (i = [0:n_opt-1]) {
        led_star(x_at(i));
        if (optics_list[i][0] == 1) filippa(x_at(i)); else spot_optic(x_at(i));
    }
    color(c_asa_in) translate([-in_L/2, -fil_d/2-3, star_t + 2]) difference() {   // optic plate
        cube([in_L, fil_d+6, 2]);
        for (i = [0:n_opt-1]) translate([x_at(i)+in_L/2, fil_d/2+3, -1]) cylinder(d=optics_list[i][1]*0.9, h=5, $fn=40);
    }
}

module mirror_assy(a = tilt) translate([0,0,mir_z]) rotate([-(135 + a),0,0]) {
    color(c_mirror) translate([-mir_L/2, -mir_W/2, 0]) cube([mir_L, mir_W, mir_t]);
    color(c_asa_in) translate([-mir_L/2-cradle_t, -mir_W/2-1, mir_t]) difference() {
        cube([mir_L+2*cradle_t, mir_W+2, 2]);
        translate([cradle_t+6, 6, -1]) cube([mir_L-12, mir_W-10, 5]);
    }
    color(c_alu) rotate([0,90,0]) cylinder(d=3, h=in_L, center=true, $fn=16);
    color(c_asa_in) translate([mir_L/2-14, mir_W/2, mir_t]) cube([4, 5, 2]);      // pushrod tab
}

module bearings() color([0.5,0.5,0.55]) for (s = [-1,1])
    translate([s*(in_L/2 - 1.25), 0, mir_z]) rotate([0,90,0]) cylinder(d=6, h=2.5, center=true, $fn=24);

// Mirror back-low edge position (for the pushrod), in world coordinates.
function back_edge(a) = [mir_L/2 - 12, -cos(45 + a)*(mir_W/2 + 3), mir_z - sin(45 + a)*(mir_W/2 + 3)];

module servo_and_link() {
    sx = in_L/2 - servo[2]/2 - 6;  sy = in_back + servo[0]/2 + 1;  sz = mir_z - 4;
    color([0.15,0.15,0.6]) translate([sx - servo[2]/2, sy - servo[0]/2, sz - servo[1]/2]) cube([servo[2], servo[0], servo[1]]);
    color("white") translate([sx - servo[2]/2 - 2, sy, sz - servo[1]/2 + 6]) rotate([0,90,0]) cylinder(d=12, h=2, $fn=24);
    color("silver") hull() {
        translate([sx - servo[2]/2 - 2, sy, sz - servo[1]/2]) sphere(d=1.2, $fn=8);
        translate(back_edge(tilt)) sphere(d=1.2, $fn=8);
    }
}

module electronics() {
    by = in_back + 0.5;
    color(c_pcb) translate([-in_L/2 + 4, by, 6]) cube([in_L - servo[2] - 22, 1.6, top_z - 14]);
    parts = [[xiao, -0.35, 0.75], [bbk, -0.1, 0.45], [bbk, 0.15, 0.45], [pol, -0.35, 0.2], [imu, 0.15, 0.15]];
    for (p = parts) {
        d = p[0];
        color(p == parts[0] ? [0.1,0.1,0.1] : [0.2,0.25,0.3])
            translate([p[1]*in_L - d[0]/2, by + 1.6, 6 + p[2]*(top_z - 14) - d[1]/2]) cube([d[0], d[2], d[1]]);
    }
}

module body_shell() {
    color(c_asa) difference() {
        translate([-out_L/2, in_back - wall, -wall]) cube([out_L, out_D, out_H]);
        translate([-in_L/2, in_back, 0]) cube([in_L, in_front - in_back, top_z - wall]);
        translate([-hs_L/2 - 1, hs_y0, -wall - 1]) cube([hs_L + 2, hs_D, wall + 2]);       // heatsink opening
        translate([-in_L/2 + 0.01, in_front - 1, win_bot]) cube([in_L - 0.02, wall + 2, 2*win_half]);
    }
    color(c_asa) translate([0, in_front + wall, win_zc]) difference() {                  // bezel
        cube([in_L + 2*bezel_lip, 2.5, 2*win_half + 2*bezel_lip], center=true);
        cube([in_L - 2, 4, 2*win_half - 2], center=true);
    }
    // mount boss with 1/4"-20 insert, on the back (faces the wheel)
    color(c_asa) translate([0, in_back - wall, top_z*0.45]) rotate([90,0,0]) cylinder(d=18, h=8, $fn=40);
    color([0.8,0.65,0.3]) translate([0, in_back - wall - 0.2, top_z*0.45]) rotate([90,0,0]) cylinder(d=8, h=8, $fn=24);
    // gland and vent low on the back, button on the right end
    color([0.1,0.1,0.1]) translate([-35, in_back - wall - 14, 12]) rotate([-90,0,0]) cylinder(d=15, h=14, $fn=6);
    color([0.1,0.1,0.1]) translate([35, in_back - wall - 6, 12]) rotate([-90,0,0]) cylinder(d=12, h=6, $fn=24);
    color([0.6,0.6,0.62]) translate([out_L/2, in_back + 12, top_z - 18]) rotate([0,90,0]) cylinder(d=12, h=3, $fn=32);
}

module window() color([0.85,0.95,1,0.25])
    translate([0, in_front + wall/2, win_zc]) cube([in_L + 2*bezel_lip - 1, win_t, 2*win_half + 2*bezel_lip - 1], center=true);

// Lidar in a pocket on top of the body, lenses forward, flush with the front.
module lidar_pod() {
    color(c_asa) translate([-lidar[0]/2 - wall, in_front + wall - lidar[2] - 2*wall, top_z])
        cube([lidar[0] + 2*wall, lidar[2] + 2*wall, lidar[1] + wall]);
    color([0.3,0.3,0.35]) for (s=[-1,1]) translate([s*15, in_front + wall + 0.1, top_z + lidar[1]/2]) rotate([-90,0,0]) cylinder(d=18, h=0.5, $fn=32);
}

module beams() {
    for (i = [0:n_opt-1]) {
        o = optics_list[i];  lo = o[0] == 1;
        color(lo ? c_beam_lo : c_beam_hi) {
            translate([x_at(i), 0, star_t + o[2]]) cylinder(d=o[1], h=mir_z - star_t - o[2], $fn=32);
            translate([x_at(i), 0, mir_z]) rotate([-90 + 2*tilt, 0, 0])
                cylinder(d1=o[1], d2=o[1] + 2*60*tan(lo ? fil_fwtm : spot_fwtm), h=win_d + 60, $fn=32);
        }
    }
}

module head(explode = 0) {
    translate([0,0,-explode*40]) heatsink();
    translate([0,0,-explode*15]) optics();
    translate([0,0,explode*10]) { mirror_assy(); bearings(); }
    translate([0,-explode*30,0]) { servo_and_link(); electronics(); }
    translate([0,0,explode*35]) body_shell();
    translate([0,explode*35,0]) window();
    if (lidar_on_head) translate([0,0,explode*70]) lidar_pod();
    if (show_beams && explode == 0) beams();
}

module cutaway() {
    intersection() { union() { heatsink(); body_shell(); window(); if (lidar_on_head) lidar_pod(); }
                     translate([0, -200, -300]) cube([400, 400, 600]); }
    optics(); mirror_assy(); bearings(); servo_and_link(); electronics();
    if (show_beams) beams();
}

// A generic EUC for scale: 16" wheel, upright shell, trolley handle. Not any real model.
module generic_wheel() {
    color([0.12,0.12,0.12]) translate([0,0,205]) rotate([0,90,0]) cylinder(d=410, h=75, center=true, $fn=80);
    color([0.35,0.36,0.38]) hull() {
        translate([-95,-150,120]) cube([190,300,20]);
        translate([-85,-120,470]) cube([170,240,30]);
    }
    color([0.25,0.25,0.25]) for (s=[-1,1]) translate([s*20,-130,500]) cylinder(d=14, h=280, $fn=16);
    color([0.25,0.25,0.25]) translate([-30,-130,780]) rotate([0,90,0]) cylinder(d=24, h=60, $fn=16);
    color([0.2,0.2,0.2]) for (s=[-1,1]) translate([s*90,-60,85]) cube([20,120,10]);
}

if (view == "assembly")      head();
else if (view == "exploded") head(explode = 1);
else if (view == "cutaway")  cutaway();
else if (view == "front")    head();
else if (view == "under")    head();
else if (view == "wheel") {
    generic_wheel();
    translate([0, 150 + 18 - (in_back - wall), 380]) {
        head();
        color([0.3,0.3,0.3]) translate([-8, in_back - wall - 18, top_z*0.45 - 7]) cube([16, 10, 14]);
    }
}
