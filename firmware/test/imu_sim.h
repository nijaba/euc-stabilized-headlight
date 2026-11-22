// Ideal IMU for host tests: what the accelerometer reports for a given true pitch
// and forward acceleration. Test helper only; never part of the firmware.
#pragma once

#include <cmath>

namespace sim {

constexpr float kG = 9.81f;
constexpr float kDeg = 3.14159265358979f / 180.0f;

struct AccReading {
    float pitch_deg;   // pitch the accelerometer alone implies
    float norm_g;      // magnitude, in g
};

// Specific force of a head pitched by pitch_deg (nose up +) accelerating forward at a_ms2.
inline AccReading accelerometer(float pitch_deg, float a_ms2) {
    return {pitch_deg + std::atan2(a_ms2, kG) / kDeg, std::sqrt(a_ms2 * a_ms2 + kG * kG) / kG};
}

// Wheel pitch while accelerating on a grade: the wheel leans nose-down by k_tilt * atan(a/g).
inline float wheel_pitch(float grade_deg, float a_ms2, float k_tilt = 1.0f) {
    return grade_deg - k_tilt * std::atan2(a_ms2, kG) / kDeg;
}

// Smooth 0..1 ramp between t0 and t1.
inline float ramp(float t, float t0, float t1) {
    if (t <= t0) return 0.0f;
    if (t >= t1) return 1.0f;
    const float x = (t - t0) / (t1 - t0);
    return x * x * (3.0f - 2.0f * x);
}

}  // namespace sim
