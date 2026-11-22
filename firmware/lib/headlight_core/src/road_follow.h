// Hill follower: estimates the road grade from the IMU (firmware-spec §2, adopted 2026-11-21).
//
// It removes the pitch that the measured acceleration explains, then follows the rest
// with a short time constant, and freezes briefly after hard acceleration or a jolt.
// Pure logic: angles in degrees, accelerations in m/s^2 (a_long) or g (acc_norm_g).
#pragma once

namespace hl {

constexpr float kGravity = 9.81f;

struct RoadFollowParams {
    float k_tilt = 1.0f;          // wheel pitch per unit of atan(a/g); learned, default 1
    float tau_s = 0.3f;           // follow time constant
    float a_jolt = 1.0f;          // |a_long| above this (m/s^2) freezes the follower
    float norm_jolt = 0.2f;       // |norm(acc)/g - 1| above this freezes it
    float hold_s = 0.3f;          // how long it stays frozen after the last jolt
};

struct RoadFollow {
    float road_imu_deg = 0.0f;
    float hold_s = 0.0f;          // time left before the follower resumes
};

// Longitudinal acceleration, m/s^2: G * (sin(acc_pitch) - sin(pitch)).
float road_a_long(float pitch_deg, float acc_pitch_deg);

// One loop step. pitch_deg is the filtered pitch (pitch_filter), acc_pitch_deg the
// accelerometer-only pitch, acc_norm_g the accelerometer magnitude in g.
void road_follow_step(RoadFollow& r, const RoadFollowParams& p, float pitch_deg,
                      float acc_pitch_deg, float acc_norm_g, float dt_s);

}  // namespace hl
