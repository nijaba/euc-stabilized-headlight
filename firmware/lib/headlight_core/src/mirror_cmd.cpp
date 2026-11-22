#include "mirror_cmd.h"

#include <algorithm>

namespace hl {

float mirror_pitch_error(float pitch_deg, float road_deg, bool follow_road, float level_offset_deg) {
    return pitch_deg - (follow_road ? road_deg : level_offset_deg);
}

float mirror_command(const MirrorParams& p, float err_deg, float aim_down_deg) {
    return std::clamp(-err_deg / 2.0f + aim_down_deg / 2.0f, -p.mirror_max_deg, p.mirror_max_deg);
}

float servo_command(const MirrorParams& p, float trim_deg, float mirror_deg) {
    return std::clamp(trim_deg + mirror_deg * p.linkage_ratio, p.servo_min_deg, p.servo_max_deg);
}

}  // namespace hl
