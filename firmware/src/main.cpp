// Board entry point. For now it only proves the build: the core library links and
// the serial port prints. The hardware layer (IMU over I2C, servo PWM on LEDC) and
// telemetry come next (build plan phase 2).
#include <Arduino.h>

#include "mirror_cmd.h"

namespace {
const hl::MirrorParams kMirror;
}

void setup() {
    Serial.begin(115200);
    Serial.printf("headlight: Arduino-ESP32 %d.%d.%d, mirror limit %.1f deg\n", ESP_ARDUINO_VERSION_MAJOR,
                  ESP_ARDUINO_VERSION_MINOR, ESP_ARDUINO_VERSION_PATCH, kMirror.mirror_max_deg);
}

void loop() {
    delay(1000);
}
