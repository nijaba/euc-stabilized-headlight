#include "servo_out.h"

#include <Arduino.h>

bool ServoOut::begin(int pin, const hl::ServoPwmParams& p) {
    pin_ = pin;
    p_ = p;
    return ledcAttach(pin, p.frame_hz, p.duty_bits);
}

void ServoOut::write_deg(float angle_deg) {
    if (pin_ < 0) return;
    ledcWrite(pin_, hl::servo_duty(p_, hl::servo_pulse_us(p_, angle_deg)));
}
