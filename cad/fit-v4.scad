// C-PKG-18: what is left of the internal parts outside the v4 body's outer skin. render.sh exports this for
// the fixed parts and for the mirrors at the corners of their travel; any non-empty result fails the check.
include <headlight-v4.scad>
part = "fixed";   // fixed | mirrors
difference() {
    if (part == "fixed") { for (sx = [-1,1]) module_optics(sx); servos_and_links(); electronics(); lidar_unit(); }
    else for (sx = [-1,1]) mirror_module(sx);
    body_outer();
}
