// Board entry point: the phase 2 bench loop (build plan phase 2, firmware-spec §2).
//
// Each 5 ms: read the IMU, run the pitch filter and the hill follower, and drive both mirrors'
// pitch servos. The yaw servos hold their trim: turn steering waits for the owner's decision
// (build plan phase 5). If the IMU stops answering, both mirrors hold the calibrated aim
// (safety invariant 3). LEDs, auto-off, derating and the remote come in later phases.
//
// All the logic is in lib/headlight_core and tested on the host; this file only wires the
// hardware to it and keeps time.
#include <Arduino.h>
#include <Wire.h>

#include "board.h"
#include "imu_convert.h"
#include "imu_lsm6dso32.h"
#include "imu_watch.h"
#include "mirror_cmd.h"
#include "pitch_filter.h"
#include "road_follow.h"
#include "servo_out.h"
#include "telemetry.h"

namespace {

const hl::PitchFilterParams kFilterParams;
const hl::RoadFollowParams kRoadParams;
const hl::MirrorParams kMirrorParams;
const hl::ImuWatchParams kWatchParams;
const hl::ServoPwmParams kServoParams;
const hl::ImuMount kMount;   // bench default: board flat, x forward, z up

constexpr uint32_t kLoopUs = 1000000UL / board::kLoopHz;
constexpr uint32_t kReportEvery = board::kLoopHz / board::kTelemetryHz;

Lsm6dso32 imu;
ServoOut servo_lp, servo_ly, servo_rp, servo_ry;
hl::PitchFilter filter;
hl::RoadFollow road;
hl::ImuWatch watch;
hl::ImuSample last_sample{{0, 0, 1}, {0, 0, 0}, 25.0f};
bool follow_road = true;
uint32_t next_us = 0;
uint32_t ticks = 0;

void drive_mirrors(float mirror_deg, float& servo_l, float& servo_r) {
    servo_l = hl::servo_command(kMirrorParams, board::kTrimDeg, board::kLeftPitchDir * mirror_deg);
    servo_r = hl::servo_command(kMirrorParams, board::kTrimDeg, board::kRightPitchDir * mirror_deg);
    servo_lp.write_deg(servo_l);
    servo_rp.write_deg(servo_r);
}

}  // namespace

void setup() {
    Serial.begin(115200);
    Wire.begin(board::kSda, board::kScl, board::kI2cHz);

    const bool servos_ok = servo_lp.begin(board::kServoLeftPitch, kServoParams) &&
                           servo_ly.begin(board::kServoLeftYaw, kServoParams) &&
                           servo_rp.begin(board::kServoRightPitch, kServoParams) &&
                           servo_ry.begin(board::kServoRightYaw, kServoParams);
    servo_ly.write_deg(board::kTrimDeg);
    servo_ry.write_deg(board::kTrimDeg);

    const bool imu_ok = imu.begin(Wire, board::kImuAddr);
    Serial.printf("headlight: Arduino-ESP32 %d.%d.%d, servos %s, IMU %s\n", ESP_ARDUINO_VERSION_MAJOR,
                  ESP_ARDUINO_VERSION_MINOR, ESP_ARDUINO_VERSION_PATCH, servos_ok ? "ok" : "FAILED",
                  imu_ok ? "ok" : "NOT FOUND");

    // Start the filter at the accelerometer's pitch rather than at 0, so it doesn't sweep.
    hl::ImuRaw raw;
    if (imu_ok && imu.read(raw)) {
        last_sample = hl::imu_convert(raw);
        filter.pitch_deg = hl::pitch_inputs(last_sample, kMount).acc_pitch_deg;
        road.road_imu_deg = filter.pitch_deg;
    }
    next_us = micros();
}

void loop() {
    const uint32_t now = micros();
    if (static_cast<int32_t>(now - next_us) < 0) return;
    next_us += kLoopUs;
    const float dt = 1.0f / board::kLoopHz;

    hl::ImuRaw raw;
    const bool read_ok = imu.read(raw);
    const bool lost = hl::imu_watch_step(watch, kWatchParams, read_ok);

    float mirror = 0.0f;
    if (lost) {
        mirror = hl::mirror_command(kMirrorParams, 0.0f, board::kAimDownDeg);   // fixed at the aim
    } else {
        if (read_ok) last_sample = hl::imu_convert(raw);   // a glitch reuses the last sample
        const hl::PitchInputs in = hl::pitch_inputs(last_sample, kMount);
        hl::pitch_filter_step(filter, kFilterParams, in.gyro_rate_dps, in.acc_pitch_deg, in.acc_norm_g, dt);
        hl::road_follow_step(road, kRoadParams, filter.pitch_deg, in.acc_pitch_deg, in.acc_norm_g, dt);
        const float err = hl::mirror_pitch_error(filter.pitch_deg, road.road_imu_deg, follow_road, 0.0f);
        mirror = hl::mirror_command(kMirrorParams, err, board::kAimDownDeg);
    }
    float servo_l = 0.0f, servo_r = 0.0f;
    drive_mirrors(mirror, servo_l, servo_r);

    if (++ticks % kReportEvery == 0) {
        const hl::TelemetryFrame f{millis(), filter.pitch_deg, road.road_imu_deg, mirror, servo_l, servo_r,
                                   last_sample.temp_c, lost ? hl::HeadState::ImuLost : hl::HeadState::Run};
        char line[128];
        if (hl::telemetry_format(line, sizeof line, f) > 0) Serial.println(line);
    }

    // If a step overran (e.g. the bus hung), don't try to catch up with a burst of steps.
    if (static_cast<int32_t>(micros() - next_us) > static_cast<int32_t>(kLoopUs)) next_us = micros();
}
