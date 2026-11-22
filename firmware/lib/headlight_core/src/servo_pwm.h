// Servo pulse output (firmware-spec §2): servo angle to pulse width to LEDC duty counts.
//
// Pure logic: the LEDC calls live in src/. Hobby servos read a 500-2500 us pulse as
// 0-180 degrees (check each servo on the bench, B-MIR-03); the frame rate may be
// 50-333 Hz (digital servos), with the duty resolution chosen to match.
#pragma once

#include <cstdint>

namespace hl {

struct ServoPwmParams {
    float pulse_min_us = 500.0f;    // pulse at servo angle 0
    float pulse_max_us = 2500.0f;   // pulse at servo angle 180
    float angle_max_deg = 180.0f;
    uint32_t frame_hz = 50;         // PWM frame rate
    uint8_t duty_bits = 14;         // LEDC duty resolution
};

// Pulse width for a servo angle, clamped to the servo's pulse range.
float servo_pulse_us(const ServoPwmParams& p, float angle_deg);

// LEDC duty counts for a pulse width at the configured frame rate and resolution.
uint32_t servo_duty(const ServoPwmParams& p, float pulse_us);

}  // namespace hl
