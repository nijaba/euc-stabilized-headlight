// Serial telemetry line (firmware-spec §9), test plan U-TEL.
#include <unity.h>

#include <cstring>

#include "telemetry.h"

using namespace hl;

void setUp() {}
void tearDown() {}

void test_U_TEL_01_line_carries_pitch_mirror_temperature_and_state() {
    const TelemetryFrame f{12345, 1.234f, 0.4f, -0.42f, 88.32f, 91.68f, 31.46f, HeadState::Run};
    char buf[128];
    const size_t n = telemetry_format(buf, sizeof buf, f);
    TEST_ASSERT_EQUAL_STRING("t=12345 pitch=+1.23 road=+0.40 mirror=-0.42 sl=88.3 sr=91.7 timu=31.5 st=RUN", buf);
    TEST_ASSERT_EQUAL_size_t(std::strlen(buf), n);
    const TelemetryFrame lost{1, 0.0f, 0.0f, -0.6f, 90.0f, 90.0f, 25.0f, HeadState::ImuLost};
    telemetry_format(buf, sizeof buf, lost);
    TEST_ASSERT_NOT_NULL(std::strstr(buf, "st=IMU_LOST"));
}

void test_U_TEL_02_a_buffer_too_small_gives_an_empty_line_not_a_truncated_one() {
    const TelemetryFrame f{12345, 1.234f, 0.4f, -0.42f, 88.32f, 91.68f, 31.46f, HeadState::Run};
    char buf[20];
    TEST_ASSERT_EQUAL_size_t(0, telemetry_format(buf, sizeof buf, f));
    TEST_ASSERT_EQUAL_STRING("", buf);
}

int main() {
    UNITY_BEGIN();
    RUN_TEST(test_U_TEL_01_line_carries_pitch_mirror_temperature_and_state);
    RUN_TEST(test_U_TEL_02_a_buffer_too_small_gives_an_empty_line_not_a_truncated_one);
    return UNITY_END();
}
