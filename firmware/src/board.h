// Pins and bench defaults for the XIAO ESP32-S3 (design §7 pin map).
#pragma once

#include <cstdint>

namespace board {

// I2C bus: IMU (and the optional lidar later)
constexpr int kSda = 5;   // D4
constexpr int kScl = 6;   // D5
constexpr uint32_t kI2cHz = 400000;
constexpr uint8_t kImuAddr = 0x6A;   // Adafruit LSM6DSO32 breakout default (0x6B with its DO jumper)

// Servo PWM (v4: pitch and yaw for each mirror)
constexpr int kServoLeftPitch = 9;     // D10
constexpr int kServoLeftYaw = 4;       // D3
constexpr int kServoRightPitch = 41;   // back pad MTDI: confirm on Seeed's pinout before wiring
constexpr int kServoRightYaw = 42;     // back pad MTMS: confirm on Seeed's pinout before wiring

// Control loop
constexpr uint32_t kLoopHz = 200;        // firmware-spec §2 (200-400 Hz)
constexpr uint32_t kTelemetryHz = 20;    // serial report rate

// Bench defaults until calibration (firmware-spec §3) stores real values in NVS.
constexpr float kTrimDeg = 90.0f;        // every servo centred
constexpr float kAimDownDeg = -1.2f;     // cutoff about 1.2 deg below horizontal
// Servo direction: +1 or -1, so each mirror tilts the right way however its servo is mounted.
// The right side is mirror-image, so its pitch servo likely runs the other way: check on the
// bench with the laser (B-MIR-01) and flip here if needed.
constexpr float kLeftPitchDir = 1.0f;
constexpr float kRightPitchDir = -1.0f;

}  // namespace board
