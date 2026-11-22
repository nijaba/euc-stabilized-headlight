// IMU conversion and loss detection (firmware-spec §2, §1.3; design §7), test plan U-IMU.
#include <unity.h>

#include <cmath>

#include "imu_convert.h"
#include "imu_watch.h"

using namespace hl;

namespace {
constexpr float kDeg = 3.14159265358979f / 180.0f;

ImuSample sample(Vec3 acc_g, Vec3 gyro_dps) { return {acc_g, gyro_dps, 25.0f}; }
}  // namespace

void setUp() {}
void tearDown() {}

void test_U_IMU_01_raw_counts_convert_at_the_configured_full_scales() {
    const ImuRaw raw{512, 1000, -2000, 0, 1025, 0, -1025};   // temp, gyro xyz, accel xyz
    const ImuSample s = imu_convert(raw);
    TEST_ASSERT_FLOAT_WITHIN(1e-3f, 1.0004f, s.acc_g.x);      // ~1 g at +-32 g full scale
    TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.0f, s.acc_g.y);
    TEST_ASSERT_FLOAT_WITHIN(1e-3f, -1.0004f, s.acc_g.z);
    TEST_ASSERT_FLOAT_WITHIN(1e-4f, 17.5f, s.gyro_dps.x);     // +-500 dps: 17.5 mdps/LSB
    TEST_ASSERT_FLOAT_WITHIN(1e-4f, -35.0f, s.gyro_dps.y);
    TEST_ASSERT_FLOAT_WITHIN(1e-4f, 27.0f, s.temp_c);         // 25 C + 512/256
}

void test_U_IMU_02_accelerometer_pitch_follows_the_mounting() {
    const float th = 10.0f;
    // default mount (x forward, z up), head pitched 10 deg nose up, at rest
    {
        const ImuMount m;
        const PitchInputs p = pitch_inputs(sample({std::sin(th * kDeg), 0.0f, std::cos(th * kDeg)}, {0, 0, 0}), m);
        TEST_ASSERT_FLOAT_WITHIN(1e-3f, th, p.acc_pitch_deg);
        TEST_ASSERT_FLOAT_WITHIN(1e-4f, 1.0f, p.acc_norm_g);
    }
    // board mounted on its side: IMU y forward, IMU x up; the same head pitch reads the same
    {
        ImuMount m;
        m.forward = {0.0f, 1.0f, 0.0f};
        m.up = {1.0f, 0.0f, 0.0f};
        const PitchInputs p = pitch_inputs(sample({std::cos(th * kDeg), std::sin(th * kDeg), 0.0f}, {0, 0, 0}), m);
        TEST_ASSERT_FLOAT_WITHIN(1e-3f, th, p.acc_pitch_deg);
    }
}

void test_U_IMU_03_pitch_rate_is_positive_nose_up_for_any_mounting() {
    // default mount: nose up is a rotation about the head's right axis = -y in IMU axes
    {
        const ImuMount m;
        TEST_ASSERT_FLOAT_WITHIN(1e-5f, 12.0f, pitch_inputs(sample({0, 0, 1}, {0.0f, -12.0f, 0.0f}), m).gyro_rate_dps);
        TEST_ASSERT_FLOAT_WITHIN(1e-5f, 0.0f, pitch_inputs(sample({0, 0, 1}, {7.0f, 0.0f, 3.0f}), m).gyro_rate_dps);
    }
    // y forward, x up: right = forward x up = -z
    {
        ImuMount m;
        m.forward = {0.0f, 1.0f, 0.0f};
        m.up = {1.0f, 0.0f, 0.0f};
        TEST_ASSERT_FLOAT_WITHIN(1e-5f, 12.0f, pitch_inputs(sample({1, 0, 0}, {0.0f, 0.0f, -12.0f}), m).gyro_rate_dps);
    }
}

void test_U_IMU_04_a_run_of_failed_reads_trips_the_fallback_and_good_reads_recover() {
    ImuWatch w;
    ImuWatchParams p;   // trip after 5 failures, recover after 20 good reads
    for (int i = 0; i < 4; ++i) TEST_ASSERT_FALSE(imu_watch_step(w, p, false));
    TEST_ASSERT_FALSE(imu_watch_step(w, p, true));             // a glitch, then a good read: reset
    for (int i = 0; i < 4; ++i) TEST_ASSERT_FALSE(imu_watch_step(w, p, false));
    TEST_ASSERT_TRUE(imu_watch_step(w, p, false));             // fifth in a row: lost
    for (int i = 0; i < 19; ++i) TEST_ASSERT_TRUE(imu_watch_step(w, p, true));
    TEST_ASSERT_TRUE(imu_watch_step(w, p, false));             // a failure restarts the count
    for (int i = 0; i < 19; ++i) TEST_ASSERT_TRUE(imu_watch_step(w, p, true));
    TEST_ASSERT_FALSE(imu_watch_step(w, p, true));             // twentieth good read: trusted again
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_U_IMU_01_raw_counts_convert_at_the_configured_full_scales);
    RUN_TEST(test_U_IMU_02_accelerometer_pitch_follows_the_mounting);
    RUN_TEST(test_U_IMU_03_pitch_rate_is_positive_nose_up_for_any_mounting);
    RUN_TEST(test_U_IMU_04_a_run_of_failed_reads_trips_the_fallback_and_good_reads_recover);
    return UNITY_END();
}
