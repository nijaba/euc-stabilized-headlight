// EUC Stabilized Headlight: packaging model (phase 1).
//
// Every bought part is a simple solid at its datasheet size; printed parts are
// shells. It's for checking fit, sweep and mass, not for printing yet.
//
// Axes: x = left-right (mirror pivot axis), y = forward (beam leaves at +y),
// z = up. Origin: centre of the LED plane (underside of the heatsink base).
//
// Render with cad/render.sh. Variables below can be overridden with -D.

/* [View] */
view = "assembly";   // assembly | cutaway | exploded | front | wheel
tilt = 0;            // mirror tilt from nominal, degrees (-7.5 .. 7.5)
show_lidar = true;
show_beams = true;

/* [Optics] (design §3) */
fil_d = 32.9;   fil_h = 18.5;      // LEDiL FILIPPA-STVZO
spot_d = 20;    spot_h = 14;       // Carclo 10003 in 10734 holder
star_d = 20;    star_t = 1.6;      // 20 mm copper DTP board
opt_gap = 2;                       // gap between optics in the row
fil_fwtm = 16.5;  spot_fwtm = 6;   // half-angles used for clearance

/* [Mirror] (design §2) */
mir_L = 114;  mir_W = 55;  mir_t = 1.9;
tilt_max = 7.5;                    // ± mirror travel
steer = 2 * tilt_max;              // ± beam steering
cradle_t = 2;                      // printed cradle frame each side
mir_clear = 3;                     // gap optics → mirror at full tilt

/* [Housing] (design §5) */
wall = 2.4;                        // 5 perimeters
front_clear = 6;                   // mirror front edge → front wall
elec_depth = 20;                   // back slot for electronics + servo
win_t = 2.5;                       // polycarbonate window
bezel_lip = 5;                     // window overlap each side

/* [Heatsink] */
hs_base = 3;  hs_fin_h = 15;  hs_fin_t = 1.5;  hs_fins = 9;

/* [Bought parts] */
servo = [12, 23, 24];              // EMAX ES08MD II: W(y) x L(z) x H(x)
xiao  = [21, 17.8, 4];
bbk   = [32, 22, 10];              // BuckBlock A009 (approx.)
pol   = [25.4, 17.8, 6];           // Pololu D36V28F5 (approx.)
imu   = [25.6, 17.8, 3];           // Adafruit LSM6DSO32
lidar = [69, 41.5, 26];            // Benewake TF02-Pro: x, z, y

// ---------- derived geometry ----------
// Optic row: spot | FILIPPA | FILIPPA | spot, centred on x = 0.
fil_x  = fil_d/2 + opt_gap/2;
spot_x = fil_d + opt_gap*1.5 + spot_d/2;
row_L  = 2*fil_d + 2*spot_d + 3*opt_gap;

// Mirror at 45° (+tilt). It runs from back-top to front-bottom.
function half_z(a) = (mir_W/2)*sin(45 + a) + mir_t;
function half_y(a) = (mir_W/2)*cos(45 - a);
mir_z  = -(fil_h + mir_clear + half_z(tilt_max));   // pivot height
mir_hy = half_y(tilt_max);                           // max y reach of mirror

in_front = mir_hy + front_clear;                    // front inner wall (y)
in_back  = -(mir_hy + elec_depth);                  // back inner wall (y)
in_L     = mir_L + 2*(cradle_t + 3);                // 3 mm bearing bosses
win_d    = in_front - 0;                            // pivot → window distance

// Window aperture: low-beam column ± steering ± spread (design §2)
win_half = fil_d/2 + win_d*tan(steer) + win_d*tan(fil_fwtm);
win_zc   = mir_z;
win_top  = win_zc + win_half;
win_bot  = win_zc - win_half;
floor_z  = min(win_bot - bezel_lip, mir_z - half_z(tilt_max) - 2) - wall;

out_L = in_L + 2*wall;
out_D = in_front - in_back + 2*wall;
out_H = -floor_z;                                    // body height below lid
hs_L = out_L;  hs_D = out_D;

// ---------- checks (C-PKG) ----------
// Spot outer edge plus spread must fit inside the window width.
spot_reach = spot_x + spot_d/2 + win_d*tan(spot_fwtm);
fil_reach  = fil_x + fil_d/2 + win_d*tan(fil_fwtm);
assert(row_L <= mir_L,           str("C-PKG-01 optic row ", row_L, " mm longer than mirror ", mir_L));
assert(mir_hy + 1 < in_front,    "C-PKG-02 mirror hits the front wall at full tilt");
assert(-mir_hy - 1 > in_back + 12, "C-PKG-03 mirror sweeps into the electronics slot");
assert(win_top < -2,             "C-PKG-04 window aperture runs into the lid");
assert(max(spot_reach, fil_reach) <= in_L/2, str("C-PKG-05 beam wider than the window: ", 2*max(spot_reach, fil_reach)));
assert(servo[0] <= elec_depth - 2, "C-PKG-06 servo does not fit the back slot");
echo(str("PKG body_outer_mm=", out_L, "x", out_D, "x", out_H,
         " head_height_mm=", out_H + hs_base + hs_fin_h,
         " window_mm=", in_L, "x", 2*win_half,
         " mirror_pivot_z=", mir_z, " pivot_to_window=", win_d,
         " beam_reach_x=", max(spot_reach, fil_reach), " in_half_L=", in_L/2));
// Values for weight.py
echo(str("MASS shell_area_mm2=", out_L*out_D + 2*out_L*out_H + 2*out_D*out_H,
         " window_area_mm2=", (in_L + 2*bezel_lip)*(2*win_half + 2*bezel_lip),
         " hs_base_mm3=", hs_L*hs_D*hs_base,
         " hs_fins_mm3=", hs_fins*hs_fin_t*hs_D*hs_fin_h,
         " mirror_mm3=", mir_L*mir_W*mir_t));

// ---------- colours ----------
c_alu = [0.75,0.77,0.80]; c_asa = [0.18,0.19,0.21]; c_asa_in = [0.05,0.05,0.06];
c_pmma = [0.85,0.92,1.0,0.75]; c_led = [0.95,0.85,0.3]; c_pcb = [0.1,0.45,0.25];
c_mirror = [0.85,0.9,0.95]; c_beam_lo = [1,0.95,0.6,0.18]; c_beam_hi = [0.7,0.85,1,0.15];

// ---------- parts ----------
module heatsink() color(c_alu) {
    translate([-hs_L/2, in_back - wall, 0]) cube([hs_L, hs_D, hs_base]);
    pitch = (hs_D - hs_fin_t) / (hs_fins - 1);
    for (i = [0:hs_fins-1])
        translate([-hs_L/2, in_back - wall + i*pitch, hs_base]) cube([hs_L, hs_fin_t, hs_fin_h]);
}

module led_star(x) {
    color(c_pcb) translate([x,0,-star_t]) cylinder(d=star_d, h=star_t, $fn=40);
    color(c_led) translate([x-2.5,-2.5,-star_t-1.3]) cube([5,5,1.3]);
}

module filippa(x) color(c_pmma) translate([x,0,-star_t]) {
    translate([0,0,-1.5]) cylinder(d=fil_d, h=1.5, $fn=60);                // flange
    translate([0,0,-fil_h]) cylinder(d1=fil_d*0.62, d2=fil_d*0.8, h=fil_h-1.5, $fn=60);
    translate([-1.55,-fil_d/2-1,-1.5]) cube([3.1,2,1.5]);                  // orienting rib → back
}

module spot_optic(x) color(c_pmma) translate([x,0,-star_t-spot_h])
    cylinder(d1=spot_d*0.75, d2=spot_d, h=spot_h, $fn=50);

module optics() {
    for (x = [-spot_x, -fil_x, fil_x, spot_x]) led_star(x);
    for (x = [-fil_x, fil_x]) filippa(x);
    for (x = [-spot_x, spot_x]) spot_optic(x);
    // optic plate
    color(c_asa_in) translate([-in_L/2, -fil_d/2-3, -star_t-4]) difference() {
        cube([in_L, fil_d+6, 2.5]);
        for (x = [-spot_x, spot_x]) translate([x+in_L/2, fil_d/2+3, -1]) cylinder(d=spot_d*0.9, h=5, $fn=40);
        for (x = [-fil_x, fil_x]) translate([x+in_L/2, fil_d/2+3, -1]) cylinder(d=fil_d*0.8, h=5, $fn=40);
    }
}

module mirror_assy(a = tilt) translate([0,0,mir_z]) rotate([-(45 + a),0,0]) {
    // normal points up-forward; the plate runs from back-top to front-bottom
    color(c_mirror) translate([-mir_L/2, -mir_W/2, 0]) cube([mir_L, mir_W, mir_t]);
    color(c_asa_in) translate([-mir_L/2-cradle_t, -mir_W/2-1, -2.5]) difference() {
        cube([mir_L+2*cradle_t, mir_W+2, 2.5]);
        translate([cradle_t+6, 6, -1]) cube([mir_L-12, mir_W-10, 5]);
    }
    color(c_alu) rotate([0,90,0]) cylinder(d=3, h=in_L, center=true, $fn=16);       // shaft
    color(c_asa_in) translate([mir_L/2-14, -mir_W/2-5, -2.5]) cube([4, 5, 2.5]);   // pushrod tab (~4:1)
}

module bearings() color([0.5,0.5,0.55]) for (s = [-1,1])
    translate([s*(in_L/2 - 1.25), 0, mir_z]) rotate([0,90,0]) cylinder(d=6, h=2.5, center=true, $fn=24);

module servo_and_link() {
    sx = in_L/2 - servo[2]/2 - 6;  sy = in_back + servo[0]/2 + 1;  sz = mir_z - 6;
    color([0.15,0.15,0.6]) translate([sx - servo[2]/2, sy - servo[0]/2, sz - servo[1]/2]) cube([servo[2], servo[0], servo[1]]);
    color("white") translate([sx - servo[2]/2 - 2, sy, sz + servo[1]/2 - 6]) rotate([0,90,0]) cylinder(d=12, h=2, $fn=24);
    // pushrod from horn to the mirror lever
    lever = [mir_L/2 - 12, -cos(45+tilt)*(mir_W/2+3), mir_z + sin(45+tilt)*(mir_W/2+3)];
    color("silver") hull() {
        translate([sx - servo[2]/2 - 2, sy, sz + servo[1]/2]) sphere(d=1.2, $fn=8);
        translate(lever) sphere(d=1.2, $fn=8);
    }
}

module electronics() {
    by = in_back + 0.5;
    color(c_pcb) translate([-in_L/2 + 4, by, floor_z + wall + 4]) cube([in_L - servo[2] - 22, 1.6, -floor_z - wall - 12]);
    parts = [[xiao, -45, -20], [bbk, -18, -14], [bbk, 18, -14], [pol, -45, -45], [imu, 18, -45]];
    for (p = parts) {
        d = p[0];
        color(p == parts[0] ? [0.1,0.1,0.1] : [0.2,0.25,0.3])
            translate([p[1] - d[0]/2, by + 1.6, p[2] - d[1]/2]) cube([d[0], d[2], d[1]]);
    }
}

module body_shell() {
    color(c_asa) difference() {
        translate([-out_L/2, in_back - wall, floor_z]) cube([out_L, out_D, out_H]);
        translate([-in_L/2, in_back, floor_z + wall]) cube([in_L, in_front - in_back, out_H]);
        // window opening
        translate([-in_L/2 + 0.01, in_front - 1, win_bot]) cube([in_L - 0.02, wall + 2, 2*win_half]);
    }
    // bezel frame
    color(c_asa) translate([0, in_front + wall, win_zc]) difference() {
        cube([in_L + 2*bezel_lip, 3, 2*win_half + 2*bezel_lip], center=true);
        cube([in_L - 2, 4, 2*win_half - 2], center=true);
    }
    // mount boss with 1/4"-20 insert
    color(c_asa) translate([0, (in_front + in_back)/2, floor_z - 8]) cylinder(d=18, h=8, $fn=40);
    color([0.8,0.65,0.3]) translate([0, (in_front + in_back)/2, floor_z - 8.2]) cylinder(d=8, h=8, $fn=24);
    // cable gland + vent on the back, button on the right end
    color([0.1,0.1,0.1]) translate([-25, in_back - wall - 14, floor_z + 14]) rotate([-90,0,0]) cylinder(d=15, h=14, $fn=6);
    color([0.1,0.1,0.1]) translate([25, in_back - wall - 6, floor_z + 14]) rotate([-90,0,0]) cylinder(d=12, h=6, $fn=24);
    color([0.6,0.6,0.62]) translate([out_L/2, in_back + 12, -22]) rotate([0,90,0]) cylinder(d=19, h=4, $fn=32);
    color([0.2,0.8,0.3]) translate([out_L/2 + 3.6, in_back + 12, -22]) rotate([0,90,0]) cylinder(d=10, h=0.6, $fn=32);
}

module window() color([0.85,0.95,1,0.25])
    translate([0, in_front + wall/2, win_zc]) cube([in_L + 2*bezel_lip - 1, win_t, 2*win_half + 2*bezel_lip - 1], center=true);

module lidar_pod() {
    color(c_asa) translate([-lidar[0]/2 - wall, in_front - lidar[2] - wall, floor_z - 8 - lidar[1] - 2*wall])
        cube([lidar[0] + 2*wall, lidar[2] + 2*wall, lidar[1] + 2*wall]);
    color([0.1,0.1,0.12]) translate([-lidar[0]/2, in_front - lidar[2] + wall*0.5, floor_z - 8 - lidar[1] - wall])
        cube([lidar[0], lidar[2], lidar[1]]);
    color([0.3,0.3,0.35]) for (s=[-1,1]) translate([s*15, in_front + wall*1.5 + 0.1, floor_z - 8 - wall - lidar[1]/2]) rotate([-90,0,0]) cylinder(d=18, h=0.5, $fn=32);
}

// Light column from each optic down to the mirror, then forward through the window.
module beams() {
    for (o = [[-fil_x, fil_d, fil_fwtm, c_beam_lo], [fil_x, fil_d, fil_fwtm, c_beam_lo],
              [-spot_x, spot_d, spot_fwtm, c_beam_hi], [spot_x, spot_d, spot_fwtm, c_beam_hi]]) {
        color(o[3]) {
            translate([o[0], 0, mir_z]) cylinder(d=o[1], h=-mir_z - fil_h, $fn=32);
            // forward cone, steered by 2*tilt
            translate([o[0], 0, mir_z]) rotate([-90 - 2*tilt, 0, 0]) rotate([0,0,0])
                cylinder(d1=o[1], d2=o[1] + 2*60*tan(o[2]), h=win_d + 60, $fn=32);
        }
    }
}

module head(explode = 0) {
    translate([0,0,explode*40]) heatsink();
    translate([0,0,explode*25]) optics();
    translate([0,0,explode*5]) { mirror_assy(); bearings(); }
    translate([0,-explode*25,0]) { servo_and_link(); electronics(); }
    translate([0,0,-explode*30]) body_shell();
    translate([0,explode*35,0]) window();
    if (show_lidar) translate([0,0,-explode*60]) lidar_pod();
    if (show_beams && explode == 0) beams();
}

// Section at x = 0: keep the +x half of the shell and heatsink, all internals.
module cutaway() {
    intersection() { union() { heatsink(); body_shell(); window(); if (show_lidar) lidar_pod(); }
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
    color([0.2,0.2,0.2]) for (s=[-1,1]) translate([s*90,-60,85]) cube([20,120,10]);   // pedals
}

if (view == "assembly")      head();
else if (view == "exploded") head(explode = 1);
else if (view == "cutaway")  cutaway();
else if (view == "front")    head();
else if (view == "wheel") {
    generic_wheel();
    // head on the front of the shell, GoPro-style mount to a curved base
    translate([0, 150 + 25 - (in_back - wall), 440]) {
        head();
        color([0.3,0.3,0.3]) translate([-8, in_back - wall - 25, floor_z - 22]) cube([16, 25 + (in_front - in_back)/2, 14]);
    }
}
