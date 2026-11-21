// EUC Stabilized Headlight: packaging model, layout v4 (study, 2026-11-21).
//
// Two independent mirror modules, each steering one FILIPPA low beam and one spot
// on two axes: pitch (levelling) and yaw (swinging into turns). The yaw steering
// replaces the fixed cornering lights and the toe-out wedges, so there is no brow:
// the lidar sits on its side in the main body, between the two modules.
//
// Same conventions as headlight.scad (layout v3): heatsink at the bottom with fins
// fore-aft, LEDs facing up, mount on the back, rounded tapered body.
// Axes: x = left-right, y = forward, z = up. Origin: centre of the LED plane.
//
// Render with cad/render.sh. Variables can be overridden with -D.

/* [View] */
view = "assembly";   // assembly | cutaway | exploded | front | under | wheel | stl_shell
tilt = 0;            // mirror pitch from nominal, degrees (-7.5 .. 7.5)
yaw = 0;             // mirror yaw, degrees (-7.5 .. 7.5); beam swings by twice this
show_beams = true;

/* [Optics] */
fil_d = 32.9;   fil_h = 18.5;      // LEDiL FILIPPA-STVZO
spot_d = 20;    spot_h = 14;       // Carclo 10003 in 10734 holder
star_d = 20;    star_t = 1.6;
opt_gap = 2;
fil_fwtm = 16.5;  spot_fwtm = 6;   // tenth-intensity half-angles (window sized for these when straight)
fil_fwhm = 11;    spot_fwhm = 5;   // half-intensity half-angles (window sized for these at full yaw)

/* [Clear wraparound sides] (study, 2026-11-21) */
wrap_sides = false;                // true: on each side, one thermoformed clear piece runs across the front, round the corner
                                   // and back along the side, with no pillar; the outward beam leaves through the side
wrap_side_min = 30;                // the clear side reaches at least this far back from the front face
yaw_out_max = 12.5;                // with wrap_sides: outward mirror yaw (beam ±25° outward); inward stays yaw_max
r_wrap = 18;                       // front-corner radius of the clear wrap

/* [Mirrors] */
mir_t = 1.1;  mir_W = 55;
tilt_max = 7.5;  yaw_max = 7.5;    // mirror travel; beam moves twice as far
frame_t = 4;                       // gimbal frame around each mirror
mir_clear = 3;

/* [Housing] */
wall = 1.6;  front_clear = 3;  elec_depth = 20;  win_t = 1.5;  bezel_lip = 4;
r_edge = 6;  taper = 14;  roof_drop = 20;  r_tail = 14;

/* [Heatsink] */
hs_base = 2.5;  hs_fin_h = 14;  hs_fin_t = 1.2;  hs_pitch = 10;  hs_margin = 6;

/* [Bought parts] */
servo = [12, 23, 24];              // envelope: W(y) x L(z) x H(x); 5 g servos are smaller
lidar = [41.5, 69, 26];            // TF02-Pro on its side: x, z, y

// ---------- one module: spot on the inside (next to the lidar), FILIPPA on the outside ----------
mod_L  = spot_d + opt_gap + fil_d;
spot_rx = -mod_L/2 + spot_d/2;     // relative to the module centre, + = outward
fil_rx  =  mod_L/2 - fil_d/2;
mir_L  = mod_L + 2;
max_h  = max(fil_h, spot_h);

function half_z(a) = (mir_W/2)*sin(45 + a) + mir_t;
function half_y(a) = (mir_W/2)*cos(45 - a);
yaw_hi = wrap_sides ? max(yaw_max, yaw_out_max) : yaw_max;
yaw_lift = (mir_L/2)*sin(yaw_hi);                     // mirror ends rise and fall when yawed
mir_z  = star_t + max_h + mir_clear + yaw_lift + half_z(tilt_max);
mir_hy = half_y(tilt_max);
in_front = mir_hy + front_clear;
in_back  = -(mir_hy + elec_depth);
win_d    = in_front;
steer = 2*tilt_max;  beam_yaw = 2*yaw_max;

// Beam reach at the window from the module centre, inward and outward.
function spread(fwtm, fwhm) = max(fwtm, fwhm + beam_yaw);
reach_in  = -spot_rx + spot_d/2 + win_d*tan(spread(spot_fwtm, spot_fwhm));
reach_out =  fil_rx  + fil_d/2  + win_d*tan(spread(fil_fwtm,  fil_fwhm));
lidar_half = lidar[0]/2 + wall + 1;
x_c = lidar_half + reach_in;                         // module centre: inward beam clears the lidar bay
r_front = wrap_sides ? r_wrap : r_edge;
// Without the wrap, the outward beam must leave through the flat front, which sets the width.
// With it, the width is set by the mirror module and its bearings, and the outward beam leaves through the clear corner.
half_int = max(x_c + mir_L/2 + frame_t + 6, x_c + fil_rx + fil_d/2 + 3) + wall;
half_L = wrap_sides ? half_int : x_c + reach_out + 1 + bezel_lip + r_edge;
win_in  = x_c - reach_in - 1;
win_out = wrap_sides ? half_L - r_front : x_c + reach_out + 1;
win_w = win_out - win_in;                            // one flat-front window per module
win_xc = (win_in + win_out)/2;
// Where the outward beam's half-intensity edge meets the side wall at full outward yaw: the clear wrap must reach back that far.
beam_out_angle = fil_fwhm + 2*(wrap_sides ? yaw_out_max : yaw_max);
x_beam0 = x_c + fil_rx + fil_d/2;
y_hit = in_front - (half_L - wall - x_beam0) / tan(beam_out_angle) - 0;
wrap_depth = wrap_sides ? max(in_front + wall - y_hit, r_front + 4, wrap_side_min) : 0;
// Clear piece per side: flat front from the lidar bay edge to the corner, the corner arc, then the flat side.
wrap_len = win_w + 3.14159*r_front/2 + (wrap_depth - r_front);

win_half = fil_d/2 + win_d*tan(steer) + win_d*tan(fil_fwtm);
win_zc = mir_z;  win_top = win_zc + win_half;  win_bot = win_zc - win_half;
top_z = max(win_top + bezel_lip + r_edge, mir_z + half_z(tilt_max) + 2 + wall, lidar[1] + 10 + r_edge);
top_rear = top_z - roof_drop;

out_L = 2*half_L;
in_L  = out_L - 2*wall;
out_D = in_front - in_back + 2*wall;
out_H = top_z + wall;

// Two heatsinks, one under each module (nothing under the lidar bay needs cooling).
// Each heatsink just covers its two LED boards plus a margin.
hs_x0 = x_c + spot_rx - star_d/2 - hs_margin;  hs_x1 = x_c + fil_rx + star_d/2 + hs_margin;
hs_L = hs_x1 - hs_x0;  hs_xc = (hs_x0 + hs_x1)/2;
hs_D = star_d + 2*hs_margin;  hs_y0 = -hs_D/2;
hs_fins = floor((hs_L - hs_fin_t) / hs_pitch) + 1;

// Servos: per side, pitch servo low and yaw servo above it, in the back slot behind the module.
back_flat = out_L/2 - taper - r_tail;
function tail_half(d) = back_flat + sqrt(max(r_tail*r_tail - pow(max(r_tail - d, 0), 2), 0)) - wall;
servo_y0 = 4;
servo_x = min(x_c, tail_half(servo_y0) - servo[2]/2 - 1);
servo_z = [10 + servo[1]/2, 13 + 1.5*servo[1]];
board_w = 2*(servo_x - servo[2]/2 - 3);
board_top = top_rear - wall - 6;

// ---------- checks (C-PKG, v4) ----------
assert(mod_L <= mir_L, "C-PKG-01 optic module longer than its mirror");
assert(mir_hy + 1 < in_front, "C-PKG-02 mirror hits the front wall at full pitch");
assert(-mir_hy - 1 > in_back + 12, "C-PKG-03 mirror sweeps into the back slot");
assert(win_bot > wall + 1, "C-PKG-04 window runs into the floor");
assert(servo_y0 + servo[0] <= elec_depth - 2, "C-PKG-06 servos do not fit the back slot");
assert(win_bot - bezel_lip >= -wall + r_edge, "C-PKG-08 window runs into the rounded bottom edge");
assert(!wrap_sides || in_front + wall - wrap_depth > in_back + elec_depth, "C-PKG-17 clear wrap would reach back into the servo slot");
assert(servo_z[1] + servo[1]/2 <= top_rear - wall - 2, "C-PKG-11 stacked servos hit the sloping roof");
assert(board_w >= 55, "C-PKG-13 electronics board narrower than 55 mm");
assert(lidar[1] + 10 <= top_z - wall, "C-PKG-14 lidar taller than the body");
// Flat-bottom half-width at a given y: the body tapers and its edge radius grows from front to tail.
function flat_half(y) = let(yf = in_front + wall - r_edge, yr = in_back - wall + r_tail, t = (yf - y)/(yf - yr))
    (out_L/2 - t*taper) - (r_edge + t*(r_tail - r_edge));
assert(hs_x1 <= flat_half(hs_y0) - 1, "C-PKG-07 heatsink runs into the rounded, tapering edge");
assert(x_c - reach_in >= lidar_half, "C-PKG-15 a beam at full yaw crosses the lidar bay");
assert(x_c - mir_L/2 - frame_t >= lidar[0]/2 - 6, "C-PKG-16 gimbal frame collides with the lidar bay");

echo(str("PKG config=v4-2x2axis+lidar body_outer_mm=", out_L, "x", out_D, "x", out_H,
         " head_height_mm=", out_H + hs_base + hs_fin_h,
         " windows_mm=2x", win_w, "x", 2*win_half, " mirrors_mm=2x", mir_L, "x", mir_W,
         " heatsinks_mm=2x", hs_L, "x", hs_D, " fins=2x", hs_fins, " beam_yaw=+-", beam_yaw,
         wrap_sides ? str(" wrap_depth_mm=", wrap_depth, " outward_beam=", 2*yaw_out_max) : " wrap=none"));
echo(str("MASS n_fil=2 n_spot=2 lidar=1 cornering=0 toe=0 n_servo=4 n_frames=2 ribs_g=16",
         " wall_mm=", wall,
         " window_mm3=", wrap_sides ? 2*(wrap_len + bezel_lip)*(2*win_half + 2*bezel_lip)*win_t
                                    : 2*(win_w + 2*bezel_lip)*(2*win_half + 2*bezel_lip)*win_t,
         " hs_mm3=", 2*(hs_L*hs_D*hs_base + hs_fins*hs_fin_t*hs_D*hs_fin_h),
         " mirror_mm3=", 2*mir_L*mir_W*mir_t, " shaft_mm=", 2*(mir_L + 2*frame_t + 10),
         " seal_mm=", 2*(out_L + out_D) + 2*(hs_L + hs_D) + 2*(lidar[0] + lidar[1])));

// ---------- colours ----------
c_alu = [0.75,0.77,0.80]; c_asa = [0.18,0.19,0.21]; c_asa_in = [0.05,0.05,0.06];
c_pmma = [0.85,0.92,1.0,0.75]; c_led = [0.95,0.85,0.3]; c_pcb = [0.1,0.45,0.25];
c_mirror = [0.85,0.9,0.95]; c_beam_lo = [1,0.95,0.6,0.18]; c_beam_hi = [0.7,0.85,1,0.15];

// ---------- helpers ----------
module blob(pts) hull() for (p = pts) translate(p[0]) sphere(r = max(p[1], 0.5), $fn = 32);
module rrect(w, h, t, r) hull() for (x = [-w/2+r, w/2-r], z = [-h/2+r, h/2-r]) translate([x, 0, z]) rotate([90,0,0]) cylinder(r=r, h=t, center=true, $fn=24);
module rrect_frame(w, h, t, r, lip) difference() { rrect(w + 2*lip, h + 2*lip, t, r); rrect(w, h, t + 2, max(r - lip, 1)); }

// ---------- parts ----------
module heatsink() color(c_alu) for (sx = [-1,1]) translate([sx*hs_xc, 0, 0]) {
    translate([-hs_L/2, hs_y0, -hs_base]) cube([hs_L, hs_D, hs_base]);
    for (i = [0:hs_fins-1])
        translate([-hs_L/2 + i*hs_pitch, 0, -hs_base]) hull() for (y = [hs_y0 + hs_fin_h*0.7, -hs_y0 - hs_fin_h*0.7])
            translate([0, y, 0]) intersection() {
                rotate([0,90,0]) cylinder(r = hs_fin_h, h = hs_fin_t, $fn=32);
                translate([0, -hs_fin_h, -hs_fin_h]) cube([hs_fin_t, 2*hs_fin_h, hs_fin_h]);
            }
}
module led_star(x) { color(c_pcb) translate([x,0,0]) cylinder(d=star_d, h=star_t, $fn=40);
                     color(c_led) translate([x-2.5,-2.5,star_t]) cube([5,5,1.3]); }
module filippa(x) color(c_pmma) translate([x,0,star_t]) {
    cylinder(d=fil_d, h=1.5, $fn=60);
    translate([0,0,1.5]) cylinder(d1=fil_d*0.8, d2=fil_d*0.62, h=fil_h-1.5, $fn=60);
    translate([-1.55, fil_d/2-1, 0]) cube([3.1,2,1.5]);
}
module spot_optic(x) color(c_pmma) translate([x,0,star_t]) cylinder(d1=spot_d, d2=spot_d*0.75, h=spot_h, $fn=50);

module module_optics(sx) {
    xs = sx*(x_c + spot_rx);  xf = sx*(x_c + fil_rx);
    led_star(xs); spot_optic(xs); led_star(xf); filippa(xf);
}

// Gimbal: an outer frame pitches about x on bearings; the mirror yaws inside it about its own width axis.
module mirror_module(sx, a = tilt, b = yaw) translate([sx*x_c, 0, mir_z]) rotate([-(135 + a),0,0]) {
    color(c_asa_in) difference() {                                              // outer frame (pitch)
        translate([-mir_L/2 - frame_t, -mir_W/2 - 1, -1]) cube([mir_L + 2*frame_t, mir_W + 2, 2]);
        translate([-mir_L/2 - 0.5, -mir_W/2 + 3, -2]) cube([mir_L + 1, mir_W - 6, 4]);
    }
    color(c_alu) rotate([0,90,0]) cylinder(d=3, h=mir_L + 2*frame_t + 10, center=true, $fn=16);   // pitch stubs
    rotate([0, sx*b, 0]) {                                                       // yaw about the frame's width axis
        color(c_mirror) translate([-mir_L/2, -mir_W/2, 0.2]) cube([mir_L, mir_W, mir_t]);
        color(c_alu) rotate([90,0,0]) cylinder(d=2, h=mir_W + 4, center=true, $fn=12);     // yaw pins
    }
}

module servos_and_links() for (sx = [-1,1]) for (k = [0,1]) {
    sy = in_back + servo_y0 + servo[0]/2;  sz = servo_z[k];
    color(k == 0 ? [0.15,0.15,0.6] : [0.45,0.15,0.55])
        translate([sx*servo_x - servo[2]/2, sy - servo[0]/2, sz - servo[1]/2]) cube([servo[2], servo[0], servo[1]]);
    target = k == 0 ? [sx*(x_c - 8), -cos(45 + tilt)*(mir_W/2 + 1), mir_z - sin(45 + tilt)*(mir_W/2 + 1)]   // pitch: frame back edge
                    : [sx*(x_c + mir_L/2 - 3), -cos(45 + tilt)*(mir_W/2 - 6), mir_z - sin(45 + tilt)*(mir_W/2 - 6)];  // yaw: mirror outer end
    color("silver") hull() { translate([sx*servo_x, sy + servo[0]/2, sz + servo[1]/2 - 4]) sphere(d=1.2, $fn=8); translate(target) sphere(d=1.2, $fn=8); }
}

module electronics() {
    color(c_pcb) translate([-board_w/2, in_back + 0.5, 6]) cube([board_w, 1.6, board_top - 6]);
    color([0.1,0.1,0.1]) translate([-12, in_back + 2.1, board_top - 25]) cube([21, 4, 17.8]);              // XIAO
    color([0.2,0.25,0.3]) for (x = [-board_w/2 + 4, board_w/2 - 36]) translate([x, in_back + 2.1, 20]) cube([32, 10, 22]);  // BuckBlocks
}

function body_pts(inset) = [
    for (sx = [-1,1], z = [-wall + r_edge, top_z - r_edge]) [[sx*(out_L/2 - r_front), in_front + wall - r_front, z], r_edge - inset],
    for (sx = [-1,1], z = [-wall + r_edge, top_z - r_edge]) [[sx*(out_L/2 - r_edge), in_front + wall - r_front, z], r_edge - inset],
    for (sx = [-1,1], z = [-wall + r_tail, top_rear - r_tail]) [[sx*(out_L/2 - taper - r_tail), in_back - wall + r_tail, z], r_tail - inset]];
module body_outer() blob(body_pts(0));
module body_inner() blob(body_pts(wall));

lidar_y0 = in_front + wall - lidar[2] - wall;
module window_openings() for (sx = [-1,1]) translate([sx*win_xc, in_front + wall/2, win_zc]) rrect(win_w, 2*win_half, wall + 4, 6);
module lidar_opening() translate([0, in_front + wall/2, 10 + lidar[1]/2]) rrect(lidar[0] - 4, lidar[1] - 4, wall + 4, 4);
// The clear wrap: the front corners within the window band, from the flat front back to wrap_depth.
module wrap_region() for (sx = [-1,1])
    translate([sx > 0 ? win_in : -out_L/2 - 1, in_front + wall - wrap_depth, win_bot])
        cube([out_L/2 + 1 - win_in, wrap_depth + 1, 2*win_half]);
module wrap_clear() intersection() { difference() { body_outer(); body_inner(); } wrap_region(); }
module shell_solid() difference() {
    body_outer(); body_inner();
    if (wrap_sides) wrap_region();
    for (sx = [-1,1]) translate([sx*hs_xc - hs_L/2, hs_y0, -wall - 1]) cube([hs_L, hs_D, wall + 2]);
    if (!wrap_sides) window_openings();
    lidar_opening();
}

module body_shell() {
    color(c_asa) shell_solid();
    if (!wrap_sides) color(c_asa) for (sx = [-1,1]) translate([sx*win_xc, in_front + wall + 1, win_zc]) rrect_frame(win_w, 2*win_half, 2.5, 6, bezel_lip);
    color(c_asa) translate([0, in_front + wall + 1, 10 + lidar[1]/2]) rrect_frame(lidar[0] - 4, lidar[1] - 4, 2.5, 4, 3);
    color(c_asa) for (sx = [-1,1]) translate([sx*(lidar[0]/2 + 0.8), lidar_y0 - 2, 0]) cube([wall, lidar[2] + 2, top_z - 2*wall], center=false);  // lidar bay walls
    color(c_asa) translate([0, in_back - wall + 2, top_rear*0.45]) rotate([90,0,0]) cylinder(d=18, h=10, $fn=40);   // 1/4"-20 mount boss
    color([0.8,0.65,0.3]) translate([0, in_back - wall - 7.8, top_rear*0.45]) rotate([90,0,0]) cylinder(d=8, h=0.5, $fn=24);
    color([0.1,0.1,0.1]) translate([-28, in_back - wall - 10, 12]) rotate([-90,0,0]) cylinder(d=12, h=12, $fn=6);
    color([0.1,0.1,0.1]) translate([28, in_back - wall - 5, 12]) rotate([-90,0,0]) cylinder(d=12, h=6, $fn=24);
    color([0.6,0.6,0.62]) translate([out_L/2 - 2, 0, top_z - 22]) rotate([0,90,0]) cylinder(d=12, h=3, $fn=32);
}
module windows() {
    if (wrap_sides) color([0.85,0.95,1,0.3]) wrap_clear();
    else color([0.85,0.95,1,0.25]) for (sx = [-1,1]) translate([sx*win_xc, in_front + wall/2, win_zc]) rrect(win_w + 2*bezel_lip - 1, 2*win_half + 2*bezel_lip - 1, win_t, 6.5);
}
module lidar_unit() {
    color([0.1,0.1,0.12]) translate([-lidar[0]/2, lidar_y0, 10]) cube([lidar[0], lidar[2], lidar[1]]);
    color([0.3,0.3,0.35]) for (s=[-1,1]) translate([0, in_front + 0.1, 10 + lidar[1]/2 + s*15]) rotate([-90,0,0]) cylinder(d=18, h=0.5, $fn=32);
}

module beams() for (sx = [-1,1]) for (o = [[spot_rx, spot_d, spot_h, spot_fwtm, c_beam_hi], [fil_rx, fil_d, fil_h, fil_fwtm, c_beam_lo]]) {
    x = sx*(x_c + o[0]);
    color(o[4]) {
        translate([x, 0, star_t + o[2]]) cylinder(d=o[1], h=mir_z - star_t - o[2], $fn=32);
        translate([x, 0, mir_z]) rotate([0, 0, -2*yaw]) rotate([-90 + 2*tilt, 0, 0])
            cylinder(d1=o[1], d2=o[1] + 2*60*tan(o[3]), h=win_d + 60, $fn=32);
    }
}

module head(explode = 0) {
    translate([0,0,-explode*40]) heatsink();
    translate([0,0,-explode*15]) for (sx = [-1,1]) module_optics(sx);
    translate([0,0,explode*12]) for (sx = [-1,1]) mirror_module(sx);
    translate([0,-explode*30,0]) { servos_and_links(); electronics(); }
    translate([0,0,explode*35]) body_shell();
    translate([0,explode*35,0]) windows();
    translate([0,explode*20,explode*20]) lidar_unit();
    if (show_beams && explode == 0) beams();
}

module cutaway() {
    intersection() { union() { heatsink(); body_shell(); windows(); } translate([x_c, -200, -300]) cube([400, 400, 600]); }
    for (sx = [-1,1]) { module_optics(sx); mirror_module(sx); }
    servos_and_links(); electronics(); lidar_unit();
    if (show_beams) beams();
}

module generic_wheel() {
    color([0.12,0.12,0.12]) translate([0,0,205]) rotate([0,90,0]) cylinder(d=410, h=75, center=true, $fn=80);
    color([0.35,0.36,0.38]) hull() { translate([-95,-150,120]) cube([190,300,20]); translate([-85,-120,470]) cube([170,240,30]); }
    color([0.25,0.25,0.25]) for (s=[-1,1]) translate([s*20,-130,500]) cylinder(d=14, h=280, $fn=16);
    color([0.25,0.25,0.25]) translate([-30,-130,780]) rotate([0,90,0]) cylinder(d=24, h=60, $fn=16);
    color([0.2,0.2,0.2]) for (s=[-1,1]) translate([s*90,-60,85]) cube([20,120,10]);
}

if (view == "assembly" || view == "front" || view == "under") head();
else if (view == "exploded") head(explode = 1);
else if (view == "cutaway")  cutaway();
else if (view == "stl_shell") shell_solid();
else if (view == "stl_wrap") wrap_clear();
else if (view == "wheel") {
    generic_wheel();
    translate([0, 150 + 18 - (in_back - wall), 380]) {
        head();
        color([0.3,0.3,0.3]) translate([-8, in_back - wall - 18, top_rear*0.45 - 7]) cube([16, 10, 14]);
    }
}
