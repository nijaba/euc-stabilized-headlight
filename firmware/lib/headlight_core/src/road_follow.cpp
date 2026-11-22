#include "road_follow.h"

#include <algorithm>
#include <cmath>

namespace hl {

namespace {
constexpr float kDeg = 3.14159265358979f / 180.0f;
}

float road_a_long(float pitch_deg, float acc_pitch_deg) {
    return kGravity * (std::sin(acc_pitch_deg * kDeg) - std::sin(pitch_deg * kDeg));
}

void road_follow_step(RoadFollow& r, const RoadFollowParams& p, float pitch_deg,
                      float acc_pitch_deg, float acc_norm_g, float dt_s) {
    const float a_long = road_a_long(pitch_deg, acc_pitch_deg);
    const float raw = pitch_deg + p.k_tilt * std::atan2(a_long, kGravity) / kDeg;   // ~ road grade
    const bool jolt = std::fabs(a_long) > p.a_jolt || std::fabs(acc_norm_g - 1.0f) > p.norm_jolt;
    r.hold_s = jolt ? p.hold_s : std::max(0.0f, r.hold_s - dt_s);
    if (r.hold_s == 0.0f) {
        r.road_imu_deg += (raw - r.road_imu_deg) * dt_s / p.tau_s;
    }
}

}  // namespace hl
