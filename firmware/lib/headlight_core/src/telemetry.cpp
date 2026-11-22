#include "telemetry.h"

#include <cstdio>

namespace hl {

const char* head_state_name(HeadState s) {
    switch (s) {
        case HeadState::Run: return "RUN";
        case HeadState::ImuLost: return "IMU_LOST";
    }
    return "?";
}

size_t telemetry_format(char* out, size_t n, const TelemetryFrame& f) {
    if (out == nullptr || n == 0) return 0;
    const int len = std::snprintf(out, n, "t=%lu pitch=%+.2f road=%+.2f mirror=%+.2f sl=%.1f sr=%.1f timu=%.1f st=%s",
                                  static_cast<unsigned long>(f.t_ms), static_cast<double>(f.pitch_deg),
                                  static_cast<double>(f.road_deg), static_cast<double>(f.mirror_deg),
                                  static_cast<double>(f.servo_l_deg), static_cast<double>(f.servo_r_deg),
                                  static_cast<double>(f.imu_temp_c), head_state_name(f.state));
    if (len < 0 || static_cast<size_t>(len) >= n) {
        out[0] = '\0';
        return 0;
    }
    return static_cast<size_t>(len);
}

}  // namespace hl
