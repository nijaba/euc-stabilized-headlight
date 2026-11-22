#include "pitch_filter.h"

#include <algorithm>
#include <cmath>

namespace hl {

bool pitch_filter_steady(const PitchFilterParams& p, float gyro_rate_dps, float acc_norm_g) {
    return std::fabs(acc_norm_g - 1.0f) < p.acc_norm_tol && std::fabs(gyro_rate_dps) < p.rate_max_dps;
}

void pitch_filter_step(PitchFilter& f, const PitchFilterParams& p, float gyro_rate_dps,
                       float acc_pitch_deg, float acc_norm_g, float dt_s) {
    f.pitch_deg += gyro_rate_dps * dt_s;
    if (pitch_filter_steady(p, gyro_rate_dps, acc_norm_g)) {
        const float k = std::min(1.0f, dt_s / p.acc_tau_s);   // per-step share, from the time constant
        f.pitch_deg += k * (acc_pitch_deg - f.pitch_deg);
    }
}

}  // namespace hl
