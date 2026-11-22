// IMU loss detection (firmware-spec §1.3): losing the IMU falls back to a fixed mirror at
// the calibrated aim. A short glitch is ridden through; a run of failed reads trips it, and
// it takes a run of good reads to trust the IMU again.
//
// Pure logic: the caller says whether each read succeeded.
#pragma once

namespace hl {

struct ImuWatchParams {
    int fail_to_trip = 5;       // consecutive failed reads before the fallback (25 ms at 200 Hz)
    int good_to_recover = 20;   // consecutive good reads before trusting the IMU again (100 ms)
};

struct ImuWatch {
    bool lost = false;
    int run = 0;   // length of the current run of failures (while ok) or successes (while lost)
};

// Feed one read result; returns true while the IMU counts as lost.
bool imu_watch_step(ImuWatch& w, const ImuWatchParams& p, bool read_ok);

}  // namespace hl
