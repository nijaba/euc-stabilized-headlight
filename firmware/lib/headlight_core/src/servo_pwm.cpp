#include "servo_pwm.h"

#include <algorithm>
#include <cmath>

namespace hl {

float servo_pulse_us(const ServoPwmParams& p, float angle_deg) {
    const float a = std::clamp(angle_deg, 0.0f, p.angle_max_deg);
    return p.pulse_min_us + (p.pulse_max_us - p.pulse_min_us) * a / p.angle_max_deg;
}

uint32_t servo_duty(const ServoPwmParams& p, float pulse_us) {
    const float period_us = 1e6f / static_cast<float>(p.frame_hz);
    const float full = static_cast<float>((1u << p.duty_bits) - 1u);
    const float d = std::round(std::clamp(pulse_us / period_us, 0.0f, 1.0f) * full);
    return static_cast<uint32_t>(d);
}

}  // namespace hl
