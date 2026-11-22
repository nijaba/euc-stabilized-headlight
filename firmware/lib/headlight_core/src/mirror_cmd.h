// Mirror and servo command for one mirror's pitch axis (firmware-spec §2).
//
// The mirror doubles the angle, so it moves by half the pitch error, the other way.
// Pure logic: angles in degrees (servo angle in servo degrees, after the linkage).
#pragma once

namespace hl {

struct MirrorParams {
    float mirror_max_deg = 7.5f;   // mechanical mirror travel, each way
    float linkage_ratio = 4.0f;    // servo degrees per mirror degree (~4:1)
    float servo_min_deg = 0.0f;    // servo's mechanical limits
    float servo_max_deg = 180.0f;
};

// Pitch error the mirror corrects: against the road when follow_road is on (default),
// otherwise against gravity level plus level_offset.
float mirror_pitch_error(float pitch_deg, float road_deg, bool follow_road, float level_offset_deg);

// Mirror angle from nominal: -err/2 + aim_down/2, clamped to the mirror's travel.
float mirror_command(const MirrorParams& p, float err_deg, float aim_down_deg);

// Servo angle: trim + mirror * linkage ratio, clamped to the servo's limits.
float servo_command(const MirrorParams& p, float trim_deg, float mirror_deg);

}  // namespace hl
