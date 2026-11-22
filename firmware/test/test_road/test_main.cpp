// Hill follower (firmware-spec §2), test plan U-ROAD.
#include <unity.h>

#include <cmath>
#include <initializer_list>

#include "../imu_sim.h"
#include "mirror_cmd.h"
#include "road_follow.h"

using namespace hl;

namespace {
constexpr float kDt = 1.0f / 200.0f;

// Step the follower with a perfect pitch estimate; returns the largest |road_imu| seen.
template <typename AccelAt>
float ride(RoadFollow& r, const RoadFollowParams& p, float grade_deg, float seconds, AccelAt accel_at) {
    float worst = 0.0f;
    for (float t = 0.0f; t < seconds; t += kDt) {
        const float a = accel_at(t);
        const float pitch = sim::wheel_pitch(grade_deg, a, p.k_tilt);
        const sim::AccReading acc = sim::accelerometer(pitch, a);
        road_follow_step(r, p, pitch, acc.pitch_deg, acc.norm_g, kDt);
        worst = std::fmax(worst, std::fabs(r.road_imu_deg - grade_deg));
    }
    return worst;
}
}  // namespace

void setUp() {}
void tearDown() {}

void test_U_ROAD_01_grade_step_settles_to_95_percent_within_1_s() {
    RoadFollow r;
    RoadFollowParams p;
    const float grade = 4.57f;   // 8 %
    ride(r, p, grade, 1.0f, [](float) { return 0.0f; });
    TEST_ASSERT_TRUE(r.road_imu_deg >= 0.95f * grade);
    TEST_ASSERT_TRUE(r.road_imu_deg <= grade + 1e-3f);
}

void test_U_ROAD_02_follow_road_off_holds_gravity_level() {
    MirrorParams mp;
    const float aim_down = -1.2f, level_offset = 0.0f;
    for (float road = -6.0f; road <= 6.0f; road += 3.0f) {
        for (float pitch = -10.0f; pitch <= 10.0f; pitch += 2.5f) {
            const float err = mirror_pitch_error(pitch, road, false, level_offset);
            const float mirror = mirror_command(mp, err, aim_down);
            const float beam = pitch + 2.0f * mirror;   // the mirror doubles its angle
            TEST_ASSERT_FLOAT_WITHIN(1e-4f, level_offset + aim_down, beam);
        }
    }
}

void test_U_ROAD_03_hard_acceleration_lean_barely_moves_road_imu() {
    RoadFollow r;
    RoadFollowParams p;
    const float a_max = sim::kG * std::tan(10.0f * sim::kDeg);   // ~1.7 m/s^2, 10 deg of lean
    const float worst = ride(r, p, 0.0f, 5.0f, [a_max](float t) {
        return a_max * (sim::ramp(t, 0.5f, 0.9f) - sim::ramp(t, 3.9f, 4.3f));
    });
    TEST_ASSERT_TRUE_MESSAGE(worst < 0.3f, "road_imu moved 0.3 deg or more");
}

void test_U_ROAD_04_gentle_acceleration_for_8_s_barely_moves_road_imu() {
    RoadFollow r;
    RoadFollowParams p;
    const float worst = ride(r, p, 0.0f, 9.0f, [](float t) {
        return 0.15f * (sim::ramp(t, 0.2f, 0.6f) - sim::ramp(t, 8.2f, 8.6f));
    });
    TEST_ASSERT_TRUE_MESSAGE(worst < 0.3f, "road_imu moved 0.3 deg or more");
}

void test_U_ROAD_05_jolt_freezes_the_follower_for_0_3_s() {
    RoadFollowParams p;
    const float grade = 5.0f;
    // a 0.3 g bump (norm), then a steady 5 deg grade
    {
        RoadFollow r;
        road_follow_step(r, p, 0.0f, 0.0f, 1.3f, kDt);
        float t = 0.0f;
        for (; t < 0.29f; t += kDt) road_follow_step(r, p, grade, grade, 1.0f, kDt);
        TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.0f, r.road_imu_deg);
        for (; t < 0.32f; t += kDt) road_follow_step(r, p, grade, grade, 1.0f, kDt);
        TEST_ASSERT_TRUE(r.road_imu_deg > 0.0f);
    }
    // a_long above 1 m/s^2 with a normal 1 g reading also freezes it
    {
        RoadFollow r;
        const float acc_pitch = std::asin(1.5f / sim::kG) / sim::kDeg;   // a_long = 1.5 m/s^2 at pitch 0
        TEST_ASSERT_FLOAT_WITHIN(1e-3f, 1.5f, road_a_long(0.0f, acc_pitch));
        road_follow_step(r, p, 0.0f, acc_pitch, 1.0f, kDt);
        TEST_ASSERT_FLOAT_WITHIN(1e-6f, 0.0f, r.road_imu_deg);
        TEST_ASSERT_FLOAT_WITHIN(1e-6f, p.hold_s, r.hold_s);
    }
}

void test_U_ROAD_06_a_long_matches_a_known_acceleration_on_a_tilted_imu() {
    // within 5 % for +-1.7 m/s^2 with the head pitched up to +-10 deg
    for (float pitch = -10.0f; pitch <= 10.0f; pitch += 5.0f) {
        for (float a : {-1.7f, -0.5f, 0.5f, 1.7f}) {
            const sim::AccReading acc = sim::accelerometer(pitch, a);
            const float a_long = road_a_long(pitch, acc.pitch_deg);
            TEST_ASSERT_FLOAT_WITHIN(0.05f * std::fabs(a), a, a_long);
        }
    }
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_U_ROAD_01_grade_step_settles_to_95_percent_within_1_s);
    RUN_TEST(test_U_ROAD_02_follow_road_off_holds_gravity_level);
    RUN_TEST(test_U_ROAD_03_hard_acceleration_lean_barely_moves_road_imu);
    RUN_TEST(test_U_ROAD_04_gentle_acceleration_for_8_s_barely_moves_road_imu);
    RUN_TEST(test_U_ROAD_05_jolt_freezes_the_follower_for_0_3_s);
    RUN_TEST(test_U_ROAD_06_a_long_matches_a_known_acceleration_on_a_tilted_imu);
    return UNITY_END();
}
