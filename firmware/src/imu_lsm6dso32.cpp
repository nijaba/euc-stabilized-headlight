#include "imu_lsm6dso32.h"

namespace {
constexpr uint8_t kWhoAmI = 0x0F;
constexpr uint8_t kWhoAmIValue = 0x6C;
constexpr uint8_t kCtrl1Xl = 0x10;   // accelerometer ODR and full scale
constexpr uint8_t kCtrl2G = 0x11;    // gyro ODR and full scale
constexpr uint8_t kCtrl3C = 0x12;    // BDU, auto-increment
constexpr uint8_t kOutTempL = 0x20;  // then gyro x/y/z, then accel x/y/z, all little-endian

constexpr uint8_t kOdr416Hz = 0x60;
constexpr uint8_t kAccelFs32g = 0x04;  // FS_XL = 01 on the DSO32
constexpr uint8_t kGyroFs500 = 0x04;   // FS_G = 01
constexpr uint8_t kBduIfInc = 0x44;    // block data update + register auto-increment

int16_t le16(const uint8_t* p) { return static_cast<int16_t>(p[0] | (p[1] << 8)); }
}  // namespace

bool Lsm6dso32::begin(TwoWire& wire, uint8_t addr) {
    wire_ = &wire;
    addr_ = addr;
    uint8_t id = 0;
    if (!read_regs(kWhoAmI, &id, 1) || id != kWhoAmIValue) return false;
    return write_reg(kCtrl3C, kBduIfInc) && write_reg(kCtrl1Xl, kOdr416Hz | kAccelFs32g) &&
           write_reg(kCtrl2G, kOdr416Hz | kGyroFs500);
}

bool Lsm6dso32::read(hl::ImuRaw& out) {
    uint8_t b[14];
    if (!read_regs(kOutTempL, b, sizeof b)) return false;
    out.temp = le16(&b[0]);
    out.gx = le16(&b[2]);
    out.gy = le16(&b[4]);
    out.gz = le16(&b[6]);
    out.ax = le16(&b[8]);
    out.ay = le16(&b[10]);
    out.az = le16(&b[12]);
    return true;
}

bool Lsm6dso32::write_reg(uint8_t reg, uint8_t value) {
    wire_->beginTransmission(addr_);
    wire_->write(reg);
    wire_->write(value);
    return wire_->endTransmission() == 0;
}

bool Lsm6dso32::read_regs(uint8_t reg, uint8_t* buf, size_t n) {
    wire_->beginTransmission(addr_);
    wire_->write(reg);
    if (wire_->endTransmission(false) != 0) return false;
    if (wire_->requestFrom(addr_, n) != n) return false;
    for (size_t i = 0; i < n; ++i) buf[i] = static_cast<uint8_t>(wire_->read());
    return true;
}
