# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of Cleaning-Robot.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import math
import time

from machine import I2C, Pin, time_pulse_us  # type: ignore

from src.config import BoardConfigManager


class UltrasonicSensor:
    MAX_RANGE_IN_CM = const(500)  # type: ignore

    def __init__(self, trigger_pin: str, echo_pin: str):
        self.__active__ = True
        self.__distance__ = 0
        self.__board_config_manager__ = BoardConfigManager.instance()
        self.__trigger_pin__ = Pin(
            self.__board_config_manager__.pin_map[trigger_pin],
            Pin.OUT,
            pull=None,
        )
        self.__echo_pin__ = Pin(
            self.__board_config_manager__.pin_map[echo_pin],
            Pin.IN,
            pull=None,
        )
        self.__trigger_pin__.off()

    def __send_pulse__(self):
        self.__trigger_pin__.off()
        time.sleep_us(5)  # type: ignore
        self.__trigger_pin__.on()
        time.sleep_us(10)  # type: ignore
        self.__trigger_pin__.off()
        try:
            pulse_time = time_pulse_us(
                self.__echo_pin__,
                1,
                30000,
            )
            if pulse_time < 0:
                pulse_time = int(self.MAX_RANGE_IN_CM * 29.1)
            return pulse_time
        except:
            return -1

    def get_distance_mm(self, pulse_count: int = 5):
        try:
            distances_mm = [
                (self.__send_pulse__() * 100 // 582) for _ in range(pulse_count)
            ]
            distances_mm = [x for x in distances_mm if x != 2499]
            return int(sum(distances_mm) / len(distances_mm))
        except:
            return -1


class Magnetometer:
    __config_map__ = {
        "mode": {
            "STANDBY": 0x00,
            "CONTINUOUS": 0x01,
        },
        "output_data_rate": {
            "10HZ": 0x00,
            "50HZ": 0x04,
            "100HZ": 0x08,
            "200HZ": 0x0C,
        },
        "range": {
            "2G": 0x00,
            "8G": 0x10,
        },
        "oversampling_ratio": {
            "512": 0x00,
            "256": 0x40,
            "128": 0x80,
            "64": 0xC0,
        },
    }

    def __init__(
        self,
        i2c: I2C,
        address: int = 0x0D,
        indicator_pin: str | None = None,
        config: dict | None = None,
    ):
        self.__i2c__ = i2c
        self.__address__ = address
        self.__board_config_manager__ = BoardConfigManager.instance()

        if indicator_pin is not None:
            self.__indicator_pin__ = Pin(
                self.__board_config_manager__.pin_map[indicator_pin],
                Pin.OUT,
            )
            self.indicator_pin.off()

        if config is None:
            if self.__board_config_manager__.has("magnetometer", check_none=True):
                self.config = self.__board_config_manager__.get("magnetometer")
            else:
                self.config = {
                    "mode": "continuous",
                    "output_data_rate": "200HZ",
                    "range": "2G",
                    "oversampling_ratio": "512",
                    "declination": {
                        "degrees": 0,
                        "minutes": 0,
                    },
                    "calibration": {
                        "x": {"offset": 0, "scale": 1},
                        "y": {"offset": 0, "scale": 1},
                        "z": {"offset": 0, "scale": 1},
                    },
                }
        else:
            self.config = config

        self.__write_Reg__(0x0B, 0x01)

    def __del__(self):
        self.config = {"mode": "standby"}

    @property
    def config(self):
        return self.__board_config_manager__.get("magnetometer")

    @config.setter
    def config(self, config: dict):
        config = {
            "mode": config.get(
                "mode",
                self.__board_config_manager__.get("magnetometer", {}).get(
                    "mode", "continuous"
                ),
            ),
            "output_data_rate": config.get(
                "output_data_rate",
                self.__board_config_manager__.get("magnetometer", {}).get(
                    "output_data_rate", "200HZ"
                ),
            ),
            "range": config.get(
                "range",
                self.__board_config_manager__.get("magnetometer", {}).get(
                    "range", "2G"
                ),
            ),
            "oversampling_ratio": config.get(
                "oversampling_ratio",
                self.__board_config_manager__.get("magnetometer", {}).get(
                    "oversampling_ratio", "512"
                ),
            ),
            "declination": config.get(
                "declination",
                self.__board_config_manager__.get("magnetometer", {}).get(
                    "declination",
                    {
                        "degrees": 0,
                        "minutes": 0,
                    },
                ),
            ),
            "calibration": config.get(
                "calibration",
                self.__board_config_manager__.get("magnetometer", {}).get(
                    "calibration",
                    {
                        "x": {"offset": 0, "scale": 1},
                        "y": {"offset": 0, "scale": 1},
                        "z": {"offset": 0, "scale": 1},
                    },
                ),
            ),
        }
        self.__board_config_manager__.set("magnetometer", config)
        self.__write_Reg__(
            0x09,
            self.__config_map__["mode"][config["mode"].upper()]
            | self.__config_map__["output_data_rate"][
                config["output_data_rate"].upper()
            ]
            | self.__config_map__["range"][config["range"].upper()]
            | self.__config_map__["oversampling_ratio"][
                config["oversampling_ratio"].upper()
            ],
        )

    @property
    def magnetic_declination_degrees(self):
        return (
            self.config["declination"]["degrees"]
            + self.config["declination"]["minutes"] / 60
        )

    def reset(self):
        self.__write_Reg__(0x0A, 0x80)

    @staticmethod
    def __int_from_bytes__(
        bytes: bytes,
        byteorder: str,
        signed: bool = False,
    ):
        if byteorder not in ("little", "big"):
            raise ValueError("byteorder must be either 'little' or 'big'")
        if signed:
            # Calculate the two's complement for signed integers
            length = len(bytes)
            if byteorder == "big":
                value = int.from_bytes(bytes, byteorder)
                if (bytes[0] & 0b10000000) != 0:
                    return value - (1 << (8 * length))
                else:
                    return value
            else:
                value = int.from_bytes(bytes, byteorder)
                if (bytes[-1] & 0b10000000) != 0:
                    return value - (1 << (8 * length))
                else:
                    return value
        else:
            # Use the standard int.from_bytes for unsigned integers
            return int.from_bytes(bytes, byteorder)

    def calibrate(self, n_samples: int = 1000, delay: int = 10, output: bool = False):
        # Initialize variables
        x_min = 0
        x_max = 0
        y_min = 0
        y_max = 0
        z_min = 0
        z_max = 0
        # Print information for user that he should rotate the magnetometer for calibration
        if output:
            print("Magnetometer calibration!")
            print(
                "Please rotate the magnetometer 360° until done (starting in 3 seconds)."
            )
            # Wait 3 seconds
            time.sleep_ms(3000)  # type: ignore
            print("Calibrating...")
        if hasattr(self, "__indicator_pin__"):
            self.indicator_pin.on()
        # Loop through n_samples
        for _ in range(n_samples):
            # Read magnetometer values
            data = self.__read_Reg__(0x00, 6)
            # Get raw values
            v_raw = [
                self.__int_from_bytes__(data[0:2], "little", signed=True),
                self.__int_from_bytes__(data[2:4], "little", signed=True),
                self.__int_from_bytes__(data[4:6], "little", signed=True),
            ]
            # Get min and max values
            x_min = v_raw[0] if v_raw[0] < x_min else x_min
            x_max = v_raw[0] if v_raw[0] > x_max else x_max
            y_min = v_raw[1] if v_raw[1] < y_min else y_min
            y_max = v_raw[1] if v_raw[1] > y_max else y_max
            z_min = v_raw[2] if v_raw[2] < z_min else z_min
            z_max = v_raw[2] if v_raw[2] > z_max else z_max
            # Wait delay milliseconds
            time.sleep_ms(delay)  # type: ignore
        # Calculate offsets
        x_offset = (x_min + x_max) / 2
        y_offset = (y_min + y_max) / 2
        z_offset = (z_min + z_max) / 2
        # Calculate scales
        x_scale = 2 / (x_max - x_min)
        y_scale = 2 / (y_max - y_min)
        z_scale = 2 / (z_max - z_min)
        # Set calibration values
        self.config = {
            "calibration": {
                "x": {"offset": x_offset, "scale": x_scale},
                "y": {"offset": y_offset, "scale": y_scale},
                "z": {"offset": z_offset, "scale": z_scale},
            }
        }
        # Print information for user that calibration is done if output is True
        if output:
            print("Calibration done!")
            print(f"Offsets: {x_offset}, {y_offset}, {z_offset}")
            print(f"Scales: {x_scale}, {y_scale}, {z_scale}")
        if hasattr(self, "__indicator_pin__"):
            self.indicator_pin.off()

    @property
    def indicator_pin(self):
        return self.__indicator_pin__

    def correct_heading(self, heading: float):
        if heading < 0:
            heading += 360
        elif heading > 360:
            heading -= 360
        return heading

    def read(self):
        data = self.__read_Reg__(0x00, 6)

        v_raw = [
            self.__int_from_bytes__(data[0:2], "little", signed=True),
            self.__int_from_bytes__(data[2:4], "little", signed=True),
            self.__int_from_bytes__(data[4:6], "little", signed=True),
        ]

        v = [
            (v_raw[0] - self.config["calibration"]["x"]["offset"])
            * self.config["calibration"]["x"]["scale"],
            (v_raw[1] - self.config["calibration"]["y"]["offset"])
            * self.config["calibration"]["y"]["scale"],
            (v_raw[2] - self.config["calibration"]["z"]["offset"])
            * self.config["calibration"]["z"]["scale"],
        ]
        heading = self.correct_heading(
            math.degrees(math.atan2(v[1], v[0])) + self.magnetic_declination_degrees
        )

        return {
            "x": v[0],
            "y": v[1],
            "z": v[2],
            "heading": heading,
        }

    def __write_Reg__(self, reg: int, value: int):
        self.__i2c__.writeto_mem(self.__address__, reg, bytearray([value]))

    def __read_Reg__(self, reg: int, length: int = 1):
        return self.__i2c__.readfrom_mem(self.__address__, reg, length)
