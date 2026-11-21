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
toe = 4;                           // FILIPPA toe-out each side, on aluminium wedges (design §3)

/* [Cornering lights] (design §3) */
crn_yaw = 30;  crn_pitch = -10;    // aim: outward and down
crn_d = 20;    crn_h = 14;         // XP-L HI + Carclo 10003-L25 in 10734 holder
brow_d = 34;                       // depth of the top brow that holds them (and the lidar)

/* [Mirror] (design §2) */
mir_t = 1.1;                       // 1.1 mm front-surface glass
mir_W = 55;
tilt_max = 7.5;
steer = 2 * tilt_max;
cradle_t = 2;
mir_clear = 3;

/* [Housing] (design §5) */
wall = 1.6;                        // 4 perimeters (lean package, 2026-11-21)
front_clear = 3;
elec_depth = 20;
win_t = 1.5;
bezel_lip = 4;
r_edge = 6;                        // front edge radius: rounded for safety and looks
taper = 14;                        // body narrows by this much each side toward the back (aerodynamic)
roof_drop = 20;                    // roof slopes down this much from front to back
r_tail = 14;                       // radius of the rounded tail edges
hood_tail = 30;                    // how far back the brow fairing blends into the roof

/* [Heatsink] sized for moving air; firmware derates when parked */
hs_base = 2.5;  hs_fin_h = 14;  hs_fin_t = 1.2;  hs_pitch = 10;  hs_margin = 6;

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
// A toed-out FILIPPA also drifts sideways on its way up to the mirror.
function reach(o, x) = o[0] == 1
    ? abs(x) + o[1]/2 + win_d*tan(fil_fwtm + toe) + (mir_z - star_t - fil_h)*tan(toe)
    : abs(x) + o[1]/2 + win_d*tan(spot_fwtm);
beam_reach = max([for (i = [0:n_opt-1]) reach(optics_list[i], x_at(i))]);
win_w    = 2*beam_reach + 2;
in_L_min = max(mir_L + 2*(cradle_t + 3), win_w);

win_half = fil_d/2 + win_d*tan(steer) + win_d*tan(fil_fwtm);
win_zc   = mir_z;
win_top  = win_zc + win_half;
win_bot  = win_zc - win_half;
// The window and bezel sit on the flat part of the front, inside the rounded edges.
top_z    = max(win_top + bezel_lip + r_edge, mir_z + half_z(tilt_max) + 2 + wall);

out_L = max(in_L_min + 2*wall, win_w + 2*bezel_lip + 2*r_edge);
in_L  = out_L - 2*wall;
out_D = in_front - in_back + 2*wall;
out_H = top_z + wall;                                // floor wall below z=0
top_rear = top_z - roof_drop;

// Heatsink: under the optic zone only; the rest of the floor is printed.
hs_L = out_L - 2*(r_tail + 0.55*taper);              // stays on the flat bottom, inside the rounded, tapering edges
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
assert(hs_D <= out_D - 2*wall,     "C-PKG-07 heatsink wider than the floor");
assert(win_bot - bezel_lip >= -wall + r_edge, "C-PKG-08 window runs into the rounded bottom edge");

// Surface area of a box with all edges rounded to radius r.
function rbox_area(L, D, H, r) = 2*((L-2*r)*(D-2*r) + (L-2*r)*(H-2*r) + (D-2*r)*(H-2*r))
                               + 2*3.14159*r*((L-2*r) + (D-2*r) + (H-2*r))   // 12 quarter-cylinder edges
                               + 4*3.14159*r*r;                              // 8 sphere-eighth corners

// Top brow across the front: cornering lights at its ends, the lidar (if fitted) in the middle.
brow_h  = lidar_on_head ? lidar[1] + 2*wall : crn_d + 6;
brow_y0 = in_front + wall - brow_d;
crn_x   = out_L/2 - 16;
crn_z   = top_z + brow_h/2 - 2;
crn_extent = (crn_d/2)*cos(crn_yaw) + crn_h*sin(crn_yaw);
assert(crn_x - crn_extent >= (lidar_on_head ? lidar[0]/2 + wall : 0), "C-PKG-09 cornering lights collide with the lidar");
assert(crn_x + crn_extent <= out_L/2 + 2, "C-PKG-10 cornering lights stick out past the end of the body");
// Servo and electronics board must fit the narrower, lower tail.
// The tail's corners are rounded in plan (radius r_tail), so the flat back is narrower than the tail.
back_flat = out_L/2 - taper - r_tail;                 // half-width of the flat inner back wall
function tail_half(d) = back_flat + sqrt(max(r_tail*r_tail - pow(max(r_tail - d, 0), 2), 0)) - wall;  // inner half-width d mm in front of the back
servo_y0 = 4;                                          // servo starts this far in front of the back wall
servo_x = in_L/2 - taper - servo[2]/2 - 6;
board_x0 = -(back_flat - 2);
board_x1 = servo_x - servo[2]/2 - 3;
board_top = top_rear - wall - 6;
assert(board_top - 6 >= 45, "C-PKG-11 sloping roof leaves the electronics board under 45 mm tall");
assert(servo_x + servo[2]/2 <= tail_half(servo_y0), "C-PKG-12 servo hits the rounded, tapered tail");
assert(board_x1 - board_x0 >= 55, "C-PKG-13 electronics board narrower than 55 mm in the tail");
assert(servo_y0 + servo[0] <= elec_depth - 2, "C-PKG-06 servo does not fit the back slot");
echo(str("PKG config=", n_fil, "F+", n_spot, "S", lidar_on_head ? "+lidar" : "",
         " body_outer_mm=", out_L, "x", out_D, "x", out_H,
         " head_height_mm=", out_H + hs_base + hs_fin_h + brow_h,
         " window_mm=", in_L, "x", 2*win_half, " mirror_mm=", mir_L, "x", mir_W,
         " heatsink_mm=", hs_L, "x", hs_D, " fins=", hs_fins, " fore-aft"));
echo(str("MASS n_fil=", n_fil, " n_spot=", n_spot, " lidar=", lidar_on_head ? 1 : 0,
         " wall_mm=", wall,
         " window_mm3=", (in_L + 2*bezel_lip)*(2*win_half + 2*bezel_lip)*win_t,
         " hs_mm3=", hs_L*hs_D*hs_base + hs_fins*hs_fin_t*hs_D*hs_fin_h,
         " mirror_mm3=", mir_L*mir_W*mir_t, " shaft_mm=", in_L,
         " seal_mm=", 2*(out_L + out_D) + 2*(hs_L + hs_D)));

// ---------- colours ----------
c_alu = [0.75,0.77,0.80]; c_asa = [0.18,0.19,0.21]; c_asa_in = [0.05,0.05,0.06];
c_pmma = [0.85,0.92,1.0,0.75]; c_led = [0.95,0.85,0.3]; c_pcb = [0.1,0.45,0.25];
c_mirror = [0.85,0.9,0.95]; c_beam_lo = [1,0.95,0.6,0.18]; c_beam_hi = [0.7,0.85,1,0.15];

// ---------- parts ----------
module rbox(size, r, $fn = 28) {           // box with every edge rounded, corner at origin
    hull() for (x = [r, size[0]-r], y = [r, size[1]-r], z = [r, size[2]-r])
        translate([x, y, z]) sphere(r = r);
}
module rrect_frame(w, h, t, r, lip) {       // rounded rectangular bezel frame, centred, normal along y
    difference() {
        hull() for (x = [-w/2-lip+r, w/2+lip-r], z = [-h/2-lip+r, h/2+lip-r]) translate([x, 0, z]) rotate([90,0,0]) cylinder(r=r, h=t, center=true, $fn=24);
        hull() for (x = [-w/2+r, w/2-r], z = [-h/2+r, h/2-r]) translate([x, 0, z]) rotate([90,0,0]) cylinder(r=max(r-lip,1), h=t+2, center=true, $fn=24);
    }
}

module heatsink() color(c_alu) {
    translate([-hs_L/2, hs_y0, -hs_base]) cube([hs_L, hs_D, hs_base]);
    for (i = [0:hs_fins-1])                                   // fins run fore-aft (along y), rounded ends
        translate([-hs_L/2 + i*hs_pitch, 0, -hs_base]) hull() for (y = [hs_y0 + hs_fin_h*0.7, -hs_y0 - hs_fin_h*0.7])
            translate([0, y, 0]) intersection() {
                rotate([0,90,0]) cylinder(r = hs_fin_h, h = hs_fin_t, $fn=32);
                translate([0, -hs_fin_h, -hs_fin_h]) cube([hs_fin_t, 2*hs_fin_h, hs_fin_h]);
            }
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

// FILIPPA optics lean outward by `toe` about the fore-aft axis; after the mirror that's a sideways swing.
module toed(x) translate([x,0,0]) rotate([0, -sign(x)*toe, 0]) translate([-x,0,0]) children();
module wedge(x) color(c_alu) translate([x,0,0]) hull() {
    rotate([0, -sign(x)*toe, 0]) translate([-star_d/2, -star_d/2, -0.6]) cube([star_d, star_d, 0.6]);
    translate([-star_d/2, -star_d/2, -0.1]) cube([star_d, star_d, 0.1]);
}
module optics() {
    for (i = [0:n_opt-1]) {
        x = x_at(i);
        if (optics_list[i][0] == 1) { wedge(x); toed(x) translate([0,0,1.5]) { led_star(x); filippa(x); } }
        else { led_star(x); spot_optic(x); }
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
    sx = servo_x;  sy = in_back + servo_y0 + servo[0]/2;  sz = mir_z - 4;
    color([0.15,0.15,0.6]) translate([sx - servo[2]/2, sy - servo[0]/2, sz - servo[1]/2]) cube([servo[2], servo[0], servo[1]]);
    color("white") translate([sx - servo[2]/2 - 2, sy, sz - servo[1]/2 + 6]) rotate([0,90,0]) cylinder(d=12, h=2, $fn=24);
    color("silver") hull() {
        translate([sx - servo[2]/2 - 2, sy, sz - servo[1]/2]) sphere(d=1.2, $fn=8);
        translate(back_edge(tilt)) sphere(d=1.2, $fn=8);
    }
}

module electronics() {
    by = in_back + 0.5;  x0 = board_x0;  x1 = board_x1;  h = board_top - 6;
    color(c_pcb) translate([x0, by, 6]) cube([x1 - x0, 1.6, h]);
    parts = [[xiao, 0.15, 0.8], [bbk, 0.45, 0.55], [bbk, 0.8, 0.55], [pol, 0.15, 0.25], [imu, 0.6, 0.18]];
    for (p = parts) {
        d = p[0];
        color(p == parts[0] ? [0.1,0.1,0.1] : [0.2,0.25,0.3])
            translate([x0 + p[1]*(x1 - x0) - d[0]/2, by + 1.6, 6 + p[2]*h - d[1]/2]) cube([d[0], d[2], d[1]]);
    }
}

// ---------- outer shapes: a rounded front that tapers and lowers toward a soft tail ----------
module blob(pts) hull() for (p = pts) translate(p[0]) sphere(r = max(p[1], 0.5), $fn = 32);
function body_pts(inset) = [
    for (sx = [-1,1], z = [-wall + r_edge, top_z - r_edge]) [[sx*(out_L/2 - r_edge), in_front + wall - r_edge, z], r_edge - inset],
    for (sx = [-1,1], z = [-wall + r_tail, top_rear - r_tail]) [[sx*(out_L/2 - taper - r_tail), in_back - wall + r_tail, z], r_tail - inset]];
module body_outer() blob(body_pts(0));
module body_inner() blob(body_pts(wall));

function roof_z(y) = let(yf = in_front + wall - r_edge, yr = in_back - wall + r_tail)
    top_rear + (top_z - top_rear) * (y - yr) / (yf - yr);
hood_r = 6;
function hood_pts(inset) = [
    for (sx = [-1,1], z = [top_z - r_edge, top_z + brow_h - hood_r]) [[sx*(out_L/2 - hood_r), in_front + wall - hood_r, z], hood_r - inset],
    for (sx = [-1,1], z = [top_z - r_edge, top_z + brow_h - hood_r]) [[sx*(out_L/2 - hood_r - 2), brow_y0 + hood_r, z], hood_r - inset],
    for (sx = [-1,1]) [[sx*(out_L/2 - taper/2 - 22), brow_y0 - hood_tail, roof_z(brow_y0 - hood_tail) - 4], 4 - inset]];
module hood_outer() blob(hood_pts(0));
module hood_inner() blob(hood_pts(wall));

module window_opening() translate([0, in_front + wall/2, win_zc]) hull() for (x = [-win_w/2+6, win_w/2-6], z = [-win_half+6, win_half-6])
    translate([x, 0, z]) rotate([90,0,0]) cylinder(r=6, h=wall+4, center=true, $fn=24);
module shell_solid() difference() {
    body_outer(); body_inner();
    translate([-hs_L/2, hs_y0, -wall - 1]) cube([hs_L, hs_D, wall + 2]);                 // heatsink opening
    window_opening();
}
module crn_apertures() for (sx = [-1,1]) crn_aim(sx) translate([0, 4, 0]) rotate([-90,0,0]) cylinder(d=crn_d + 4, h=30, $fn=40);
module lidar_cavity() translate([-lidar[0]/2, in_front + wall - lidar[2] - wall, top_z + wall]) cube([lidar[0], lidar[2] + 2*wall, lidar[1]]);
module hood_solid() difference() {
    hood_outer(); hood_inner(); body_outer(); crn_apertures();
    if (lidar_on_head) lidar_cavity();
}

module body_shell() {
    color(c_asa) shell_solid();
    color(c_asa) translate([0, in_front + wall + 1, win_zc]) rrect_frame(win_w, 2*win_half, 2.5, 6, bezel_lip);   // bezel
    // mount boss with 1/4"-20 insert, on the back (faces the wheel)
    color(c_asa) translate([0, in_back - wall + 2, top_rear*0.45]) rotate([90,0,0]) cylinder(d=18, h=10, $fn=40);
    color([0.8,0.65,0.3]) translate([0, in_back - wall - 7.8, top_rear*0.45]) rotate([90,0,0]) cylinder(d=8, h=0.5, $fn=24);
    // gland and vent low on the back, button on the right side
    color([0.1,0.1,0.1]) translate([-28, in_back - wall - 10, 12]) rotate([-90,0,0]) cylinder(d=12, h=12, $fn=6);
    color([0.1,0.1,0.1]) translate([28, in_back - wall - 5, 12]) rotate([-90,0,0]) cylinder(d=12, h=6, $fn=24);
    color([0.6,0.6,0.62]) translate([out_L/2 - 2, 2, top_z - 22]) rotate([0,90,0]) cylinder(d=12, h=3, $fn=32);
}

module window() color([0.85,0.95,1,0.25])
    translate([0, in_front + wall/2, win_zc]) hull() for (x = [-win_w/2-bezel_lip+7, win_w/2+bezel_lip-7], z = [-win_half-bezel_lip+7, win_half+bezel_lip-7])
        translate([x, 0, z]) rotate([90,0,0]) cylinder(r=6.5, h=win_t, center=true, $fn=24);

// Rounded brow across the top front: lidar in the middle (if fitted), a cornering light at each end.
module crn_aim(sx) translate([sx*crn_x, in_front + wall - 16, crn_z]) rotate([0,0,sx*-crn_yaw]) rotate([crn_pitch,0,0]) children();
module cornering(sx) crn_aim(sx) {
    color(c_alu) translate([-12, -10, -12]) cube([24, 2, 24]);                       // spreader plate
    color(c_pcb) translate([0,-8,0]) rotate([-90,0,0]) cylinder(d=star_d, h=star_t, $fn=40);
    color(c_pmma) translate([0,-6.4,0]) rotate([-90,0,0]) cylinder(d1=crn_d, d2=crn_d*0.8, h=crn_h, $fn=40);
}
module brow() {
    color(c_asa) hood_solid();
    color([0.85,0.95,1,0.35]) for (sx = [-1,1]) crn_aim(sx) translate([0, 9.5, 0]) rotate([-90,0,0]) cylinder(d=crn_d + 6, h=1.5, $fn=40);
    if (lidar_on_head) {
        color([0.1,0.1,0.12]) translate([-lidar[0]/2, in_front + wall - lidar[2] - wall, top_z + wall]) cube([lidar[0], lidar[2], lidar[1]]);
        color([0.3,0.3,0.35]) for (s2=[-1,1]) translate([s2*15, in_front + 0.1, top_z + wall + lidar[1]/2]) rotate([-90,0,0]) cylinder(d=18, h=0.5, $fn=32);
    }
    for (sx = [-1,1]) cornering(sx);
}

module beams() {
    for (i = [0:n_opt-1]) {
        o = optics_list[i];  lo = o[0] == 1;
        color(lo ? c_beam_lo : c_beam_hi) {
            t = lo ? toe : 0;  sx = sign(x_at(i));
            translate([x_at(i), 0, star_t + o[2]]) rotate([0, -sx*t, 0]) cylinder(d=o[1], h=mir_z - star_t - o[2], $fn=32);
            translate([x_at(i) - sx*(mir_z - star_t - o[2])*tan(t), 0, mir_z]) rotate([0, 0, sx*t]) rotate([-90 + 2*tilt, 0, 0])
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
    translate([0,0,explode*70]) brow();
    if (show_beams && explode == 0) beams();
}

module cutaway() {
    intersection() { union() { heatsink(); body_shell(); window(); brow(); }
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
else if (view == "stl_shell") shell_solid();
else if (view == "stl_hood")  hood_solid();
else if (view == "wheel") {
    generic_wheel();
    translate([0, 150 + 18 - (in_back - wall), 380]) {
        head();
        color([0.3,0.3,0.3]) translate([-8, in_back - wall - 18, top_rear*0.45 - 7]) cube([16, 10, 14]);
    }
}
