// Servo PWM on the ESP32-S3's LEDC peripheral (firmware-spec §2). Pulse maths is in
// lib/headlight_core (servo_pwm); this only attaches pins and writes duty.
#pragma once

#include "servo_pwm.h"

class ServoOut {
public:
    // Attaches the pin at the configured frame rate and resolution. Returns false on failure.
    bool begin(int pin, const hl::ServoPwmParams& p);
    // Moves the servo to a servo angle in degrees (clamped by the pulse maths).
    void write_deg(float angle_deg);

private:
    int pin_ = -1;
    hl::ServoPwmParams p_;
};
