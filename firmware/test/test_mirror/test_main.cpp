// Mirror and servo command (firmware-spec §2), test plan U-MIR.
#include <unity.h>

#include "mirror_cmd.h"

using namespace hl;

void setUp() {}
void tearDown() {}

void test_U_MIR_01_mirror_moves_half_the_error_the_other_way() {
    MirrorParams p;
    TEST_ASSERT_FLOAT_WITHIN(1e-6f, -2.0f, mirror_command(p, 4.0f, 0.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-6f, 3.0f, mirror_command(p, -6.0f, 0.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-6f, -0.6f, mirror_command(p, 0.0f, -1.2f));   // aim_down/2
}

void test_U_MIR_02_mirror_command_is_clamped_to_7_5_deg() {
    MirrorParams p;
    TEST_ASSERT_FLOAT_WITHIN(1e-6f, -7.5f, mirror_command(p, 30.0f, 0.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-6f, 7.5f, mirror_command(p, -30.0f, 0.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-6f, 7.5f, mirror_command(p, -15.0f, 0.0f));   // exactly at the limit
}

void test_U_MIR_03_servo_is_trim_plus_mirror_times_linkage_clamped() {
    MirrorParams p;   // 4:1, servo 0..180
    TEST_ASSERT_FLOAT_WITHIN(1e-5f, 110.0f, servo_command(p, 90.0f, 5.0f));
    TEST_ASSERT_FLOAT_WITHIN(1e-5f, 60.0f, servo_command(p, 90.0f, -7.5f));
    TEST_ASSERT_FLOAT_WITHIN(1e-5f, 180.0f, servo_command(p, 170.0f, 7.5f));   // mechanical limit
    TEST_ASSERT_FLOAT_WITHIN(1e-5f, 0.0f, servo_command(p, 5.0f, -7.5f));
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_U_MIR_01_mirror_moves_half_the_error_the_other_way);
    RUN_TEST(test_U_MIR_02_mirror_command_is_clamped_to_7_5_deg);
    RUN_TEST(test_U_MIR_03_servo_is_trim_plus_mirror_times_linkage_clamped);
    return UNITY_END();
}
