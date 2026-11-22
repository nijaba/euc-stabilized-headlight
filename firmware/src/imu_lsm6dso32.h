// LSM6DSO32 driver over I2C (design §7): configures +-32 g / +-500 dps at 416 Hz and reads
// one sample. Register access only; conversion is in lib/headlight_core (imu_convert).
#pragma once

#include <Wire.h>

#include "imu_convert.h"

class Lsm6dso32 {
public:
    // Checks WHO_AM_I and writes the configuration. Returns false if the IMU doesn't answer.
    bool begin(TwoWire& wire, uint8_t addr);
    // Reads temperature, gyro and accelerometer in one burst. Returns false on a bus error.
    bool read(hl::ImuRaw& out);

private:
    bool write_reg(uint8_t reg, uint8_t value);
    bool read_regs(uint8_t reg, uint8_t* buf, size_t n);

    TwoWire* wire_ = nullptr;
    uint8_t addr_ = 0;
};
