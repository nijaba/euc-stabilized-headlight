#include "pitch_filter.h"

#include <cmath>

namespace hl {

bool pitch_filter_steady(const PitchFilterParams& p, float gyro_rate_dps, float acc_norm_g) {
    return std::fabs(acc_norm_g - 1.0f) < p.acc_norm_tol && std::fabs(gyro_rate_dps) < p.rate_max_dps;
}

void pitch_filter_step(PitchFilter& f, const PitchFilterParams& p, float gyro_rate_dps,
                       float acc_pitch_deg, float acc_norm_g, float dt_s) {
    f.pitch_deg += gyro_rate_dps * dt_s;
    if (pitch_filter_steady(p, gyro_rate_dps, acc_norm_g)) {
        f.pitch_deg += p.acc_gain * (acc_pitch_deg - f.pitch_deg);
    }
}

}  // namespace hl
