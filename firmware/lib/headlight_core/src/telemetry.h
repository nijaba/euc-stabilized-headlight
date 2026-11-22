// Serial telemetry line (firmware-spec §9): one line per report, key=value pairs, easy to
// read in a terminal and to parse from a log.
//
// Pure logic: formats into a caller's buffer, no allocation, no I/O.
#pragma once

#include <cstddef>
#include <cstdint>

namespace hl {

enum class HeadState : uint8_t { Run, ImuLost };

const char* head_state_name(HeadState s);

struct TelemetryFrame {
    uint32_t t_ms;
    float pitch_deg;       // filtered pitch
    float road_deg;        // road grade estimate (road_imu)
    float mirror_deg;      // pitch mirror command, from nominal
    float servo_l_deg;     // left mirror pitch servo
    float servo_r_deg;     // right mirror pitch servo
    float imu_temp_c;      // IMU die temperature (internal temperature)
    HeadState state;
};

// Writes e.g. "t=12345 pitch=+1.23 road=+0.40 mirror=-0.42 sl=88.3 sr=91.7 timu=31.5 st=RUN"
// (no newline). Returns the length written, or 0 if it doesn't fit in n bytes.
size_t telemetry_format(char* out, size_t n, const TelemetryFrame& f);

}  // namespace hl
