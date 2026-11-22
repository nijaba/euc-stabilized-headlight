// C-PKG-18: what is left of the internal parts outside the v4 body's skin. render.sh exports this for
// the fixed parts and for the mirrors at the corners of their travel; any non-empty result fails the check.
// Since 2026-11-21 the optics, servos, board and mirrors are checked against the INNER skin (so they also clear
// the wall), and the lidar (in the nose since 2026-11-21) against the outer skin, body plus chin: its window cuts the wall.
include <headlight-v4.scad>
part = "fixed";   // fixed | mirrors
union() {
    difference() {
        if (part == "fixed") { for (sx = [-1,1]) module_optics(sx); servos_and_links(); electronics(); }
        else for (sx = [-1,1]) mirror_module(sx);
        body_inner();
        translate([-200, -200, -50]) cube([400, 400, 50.2]);   // floor level and below: the LED boards sit on the heatsinks through the floor openings
    }
    if (part == "fixed") difference() { lidar_unit(); skin_outer(); }
}
