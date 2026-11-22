#include "imu_watch.h"

namespace hl {

bool imu_watch_step(ImuWatch& w, const ImuWatchParams& p, bool read_ok) {
    if (!w.lost) {
        w.run = read_ok ? 0 : w.run + 1;
        if (w.run >= p.fail_to_trip) {
            w.lost = true;
            w.run = 0;
        }
    } else {
        w.run = read_ok ? w.run + 1 : 0;
        if (w.run >= p.good_to_recover) {
            w.lost = false;
            w.run = 0;
        }
    }
    return w.lost;
}

}  // namespace hl
