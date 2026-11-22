#include "imu_convert.h"

#include <cmath>

namespace hl {

namespace {
constexpr float kDeg = 3.14159265358979f / 180.0f;

float dot(const Vec3& a, const Vec3& b) { return a.x * b.x + a.y * b.y + a.z * b.z; }

Vec3 cross(const Vec3& a, const Vec3& b) {
    return {a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x};
}
}  // namespace

ImuSample imu_convert(const ImuRaw& r) {
    return {{r.ax * kAccelGPerLsb, r.ay * kAccelGPerLsb, r.az * kAccelGPerLsb},
            {r.gx * kGyroDpsPerLsb, r.gy * kGyroDpsPerLsb, r.gz * kGyroDpsPerLsb},
            kTempOffsetC + r.temp / kTempLsbPerC};
}

PitchInputs pitch_inputs(const ImuSample& s, const ImuMount& m) {
    const Vec3 right = cross(m.forward, m.up);
    const float a = s.acc_g.x, b = s.acc_g.y, c = s.acc_g.z;
    return {dot(s.gyro_dps, right), std::atan2(dot(s.acc_g, m.forward), dot(s.acc_g, m.up)) / kDeg,
            std::sqrt(a * a + b * b + c * c)};
}

}  // namespace hl
