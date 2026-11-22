// Servo pulse output (firmware-spec §2), test plan U-SRV.
#include <unity.h>

#include "servo_pwm.h"

using namespace hl;

void setUp() {}
void tearDown() {}

void test_U_SRV_01_angle_maps_linearly_to_pulse_and_is_clamped() {
    ServoPwmParams p;   // 500-2500 us for 0-180 deg
    TEST_ASSERT_FLOAT_WITHIN(1e-3f, 500.0f, servo_pulse_us(p, 0.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-3f, 1500.0f, servo_pulse_us(p, 90.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-3f, 2500.0f, servo_pulse_us(p, 180.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-3f, 500.0f, servo_pulse_us(p, -20.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-3f, 2500.0f, servo_pulse_us(p, 200.0f));
}

void test_U_SRV_02_pulse_converts_to_ledc_duty_at_the_frame_rate() {
    ServoPwmParams p;   // 50 Hz, 14 bit: 20 ms frame, 16383 counts
    TEST_ASSERT_EQUAL_UINT32(1229, servo_duty(p, 1500.0f));   // 1500/20000 * 16383
    TEST_ASSERT_EQUAL_UINT32(410, servo_duty(p, 500.0f));
    p.frame_hz = 200;                                         // digital servo, 5 ms frame
    TEST_ASSERT_EQUAL_UINT32(4915, servo_duty(p, 1500.0f));
    TEST_ASSERT_EQUAL_UINT32(16383, servo_duty(p, 9000.0f));  // never past a full frame
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_U_SRV_01_angle_maps_linearly_to_pulse_and_is_clamped);
    RUN_TEST(test_U_SRV_02_pulse_converts_to_ledc_duty_at_the_frame_rate);
    return UNITY_END();
}
