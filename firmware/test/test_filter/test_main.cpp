// Pitch filter (firmware-spec §2), test plan U-FILT.
#include <unity.h>

#include <initializer_list>

#include "../imu_sim.h"
#include "pitch_filter.h"

using namespace hl;

namespace {
constexpr float kDt = 1.0f / 200.0f;
}

void setUp() {}
void tearDown() {}

void test_U_FILT_01_gyro_integration_tracks_a_known_rate() {
    PitchFilter f;
    PitchFilterParams p;
    // 10 deg/s for 1 s, accelerometer gated off by its norm
    for (int i = 0; i < 200; ++i) pitch_filter_step(f, p, 10.0f, 0.0f, 1.2f, kDt);
    TEST_ASSERT_FLOAT_WITHIN(0.01f, 10.0f, f.pitch_deg);
}

void test_U_FILT_02_braking_with_the_wheel_level_does_not_tilt() {
    PitchFilter f;
    PitchFilterParams p;
    const sim::AccReading acc = sim::accelerometer(0.0f, -0.5f * sim::kG);   // 0.5 g of braking
    TEST_ASSERT_TRUE(acc.pitch_deg < -25.0f);                                 // ~27 deg of false tilt
    for (int i = 0; i < 400; ++i) pitch_filter_step(f, p, 0.0f, acc.pitch_deg, acc.norm_g, kDt);
    TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.0f, f.pitch_deg);
}

void test_U_FILT_03_gate_rejects_the_accelerometer_above_5_dps() {
    PitchFilter f;
    PitchFilterParams p;
    // norm is a perfect 1 g, but the wheel is rotating at 6 deg/s: only the gyro counts
    for (int i = 0; i < 100; ++i) pitch_filter_step(f, p, 6.0f, 20.0f, 1.0f, kDt);
    TEST_ASSERT_FLOAT_WITHIN(1e-3f, 6.0f * 0.5f, f.pitch_deg);
    TEST_ASSERT_FALSE(pitch_filter_steady(p, 5.01f, 1.0f));
    TEST_ASSERT_TRUE(pitch_filter_steady(p, 4.99f, 1.0f));
}

void test_U_FILT_04_steady_pitch_converges_to_the_accelerometer() {
    PitchFilter f;
    PitchFilterParams p;
    const sim::AccReading acc = sim::accelerometer(3.0f, 0.0f);
    for (int i = 0; i < 400; ++i) pitch_filter_step(f, p, 0.0f, acc.pitch_deg, acc.norm_g, kDt);
    TEST_ASSERT_FLOAT_WITHIN(0.01f, 3.0f, f.pitch_deg);
}

void test_U_FILT_05_correction_speed_does_not_depend_on_the_loop_rate() {
    PitchFilterParams p;
    const sim::AccReading acc = sim::accelerometer(4.0f, 0.0f);
    // after 0.25 s (one time constant) the error has shrunk to about 1/e at 100, 200 and 400 Hz
    for (float hz : {100.0f, 200.0f, 400.0f}) {
        PitchFilter f;
        const int steps = static_cast<int>(0.25f * hz + 0.5f);
        for (int i = 0; i < steps; ++i) pitch_filter_step(f, p, 0.0f, acc.pitch_deg, acc.norm_g, 1.0f / hz);
        TEST_ASSERT_FLOAT_WITHIN(0.06f, 4.0f * 0.3679f, 4.0f - f.pitch_deg);
    }
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_U_FILT_01_gyro_integration_tracks_a_known_rate);
    RUN_TEST(test_U_FILT_02_braking_with_the_wheel_level_does_not_tilt);
    RUN_TEST(test_U_FILT_03_gate_rejects_the_accelerometer_above_5_dps);
    RUN_TEST(test_U_FILT_04_steady_pitch_converges_to_the_accelerometer);
    RUN_TEST(test_U_FILT_05_correction_speed_does_not_depend_on_the_loop_rate);
    return UNITY_END();
}
