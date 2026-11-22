// Gated complementary pitch filter (firmware-spec §2).
//
// Pure logic: the caller passes the gyro rate, the accelerometer reading and dt.
// Angles in degrees, rates in degrees per second, accelerations in g.
#pragma once

namespace hl {

struct PitchFilterParams {
    float acc_norm_tol = 0.03f;   // |norm(acc)/g - 1| below this counts as steady
    float rate_max_dps = 5.0f;    // pitch rate below this counts as steady
    float acc_tau_s = 0.25f;      // time constant of the pull toward the accelerometer pitch when
                                  // steady (0.02 per step at the 200 Hz loop; same speed at any rate)
};

struct PitchFilter {
    float pitch_deg = 0.0f;
};

// Is the accelerometer trustworthy right now? (not accelerating, not rotating)
bool pitch_filter_steady(const PitchFilterParams& p, float gyro_rate_dps, float acc_norm_g);

// One loop step: integrate the gyro, then pull toward the accelerometer pitch with time
// constant acc_tau_s, only when steady. acc_pitch_deg is the pitch the accelerometer alone implies.
void pitch_filter_step(PitchFilter& f, const PitchFilterParams& p, float gyro_rate_dps,
                       float acc_pitch_deg, float acc_norm_g, float dt_s);

}  // namespace hl
