// IMU conversion (firmware-spec §2, design §7): raw LSM6DSO32 counts to physical units,
// then the pitch inputs the filter needs.
//
// Pure logic: no I2C here. The driver in src/ reads the registers and passes the counts in.
#pragma once

#include <cstdint>

namespace hl {

// Full scales the driver configures: accelerometer +-32 g (crash detection doesn't
// saturate), gyro +-500 dps.
constexpr float kAccelGPerLsb = 0.000976f;    // LSM6DSO32 at +-32 g: 0.976 mg/LSB
constexpr float kGyroDpsPerLsb = 0.0175f;     // at +-500 dps: 17.5 mdps/LSB
constexpr float kTempLsbPerC = 256.0f;        // 0 LSB = 25 C
constexpr float kTempOffsetC = 25.0f;

struct ImuRaw {   // register order: temperature, gyro x y z, accel x y z
    int16_t temp;
    int16_t gx, gy, gz;
    int16_t ax, ay, az;
};

struct Vec3 {
    float x, y, z;
};

struct ImuSample {
    Vec3 acc_g;      // specific force, g
    Vec3 gyro_dps;   // angular rate, deg/s
    float temp_c;
};

// How the IMU sits in the head: unit vectors, in IMU axes, of the head's forward and up
// directions. A fixed default until calibration (firmware-spec §3 B and C, U-CAL) learns them.
struct ImuMount {
    Vec3 forward{1.0f, 0.0f, 0.0f};
    Vec3 up{0.0f, 0.0f, 1.0f};
};

ImuSample imu_convert(const ImuRaw& raw);

struct PitchInputs {
    float gyro_rate_dps;   // pitch rate, nose up positive
    float acc_pitch_deg;   // pitch the accelerometer alone implies, nose up positive
    float acc_norm_g;      // |acc| in g
};

// Pitch inputs from one sample: the rate about the head's right axis (forward x up) and the
// accelerometer pitch atan2(acc . forward, acc . up).
PitchInputs pitch_inputs(const ImuSample& s, const ImuMount& m);

}  // namespace hl
