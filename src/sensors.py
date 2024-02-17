# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import the necessary libraries
import math
import time

from machine import I2C, Pin, time_pulse_us  # type: ignore

from src.config import BoardConfigManager


# Define the `UltrasonicSensor` class
class UltrasonicSensor:
    # Define the `MAX_RANGE_IN_CM` constant
    MAX_RANGE_IN_CM = const(500)  # type: ignore

    # Define the `__init__` method
    def __init__(self, trigger_pin: str, echo_pin: str):
        # Set the `trigger_pin` and `echo_pin` attributes, and initialize the sensor
        self.__active__ = True
        self.__distance__ = 0
        self.__board_config_manager__ = BoardConfigManager()
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

    # Define the `__send_pulse__` method
    def __send_pulse__(self):
        # Send a pulse to the sensor and return the calculated pulse time
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

    # Define the `get_distance_mm` method
    def get_distance_mm(self, pulse_count: int = 5):
        # Get the distance in millimeters
        try:
            # Get the distances and return the average
            distances_mm = [
                (self.__send_pulse__() * 100 // 582) for _ in range(pulse_count)
            ]
            # Remove the invalid distances (2499)
            distances_mm = [x for x in distances_mm if x != 2499]
            return int(sum(distances_mm) / len(distances_mm))
        except:
            return -1


# Define the `Magnetometer` class
class Magnetometer:
    # Define the `__config_map__` attribute
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

    # Define the `__init__` method
    def __init__(
        self,
        i2c: I2C,
        address: int = 0x0D,
        indicator_pin: str | None = None,
        config: dict | None = None,
    ):
        # Set the `i2c`, `address`, `indicator_pin`, and `config` attributes
        self.__i2c__ = i2c
        self.__address__ = address
        self.__board_config_manager__ = BoardConfigManager()

        # For debugging purposes, set the `indicator_pin` attribute
        if indicator_pin is not None:
            self.__indicator_pin__ = Pin(
                self.__board_config_manager__.pin_map[indicator_pin],
                Pin.OUT,
            )
            self.indicator_pin.off()

        # Set the `config` attribute and initialize the sensor with the given `config`
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

        # Initialize the sensor by setting the `mode` to `continuous`
        self.__write_Reg__(0x0B, 0x01)

    # Define the `__del__` method
    def __del__(self):
        # Set the `mode` to `standby` and delete the sensor
        self.config = {"mode": "standby"}

    # Define the `config` property
    @property
    def config(self):
        # Get the configuration of the sensor
        return self.__board_config_manager__.get("magnetometer")

    # Define the `config` setter
    @config.setter
    def config(self, config: dict):
        # Set the configuration of the sensor
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
        # Set the configuration of the sensor by writing to the registers
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

    # Define the `magnetic_declination_degrees` property
    @property
    def magnetic_declination_degrees(self):
        # Get the magnetic declination in degrees
        return (
            self.config["declination"]["degrees"]
            + self.config["declination"]["minutes"] / 60
        )

    # Define the `reset` method
    def reset(self):
        # Reset the sensor by writing to the registers
        self.__write_Reg__(0x0A, 0x80)

    # Define the `__int_from_bytes__` method
    @staticmethod
    def __int_from_bytes__(
        bytes: bytes,
        byteorder: str,
        signed: bool = False,
    ):
        # Define custom int.from_bytes method for signed integers, as it is not available in MicroPython
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

    # Define the `calibrate` method
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
        # Print information for user that calibration is done if `output` is True
        if output:
            print("Calibration done!")
            print(f"Offsets: {x_offset}, {y_offset}, {z_offset}")
            print(f"Scales: {x_scale}, {y_scale}, {z_scale}")
        if hasattr(self, "__indicator_pin__"):
            self.indicator_pin.off()

    # Define the `indicator_pin` property
    @property
    def indicator_pin(self):
        return self.__indicator_pin__

    # Define the `correct_heading` method
    def correct_heading(self, heading: float):
        # Correct the heading by adding the magnetic declination and normalizing it
        if heading < 0:
            heading += 360
        elif heading > 360:
            heading -= 360
        return heading

    # Define the `read` method
    def read(self) -> dict[str, float | int]:
        # Read the magnetometer values and return the calibrated values
        data = self.__read_Reg__(0x00, 6)

        v_raw = [
            self.__int_from_bytes__(data[0:2], "little", signed=True),
            self.__int_from_bytes__(data[2:4], "little", signed=True),
            self.__int_from_bytes__(data[4:6], "little", signed=True),
        ]

        # Calibrate the values
        v = [
            (v_raw[0] - self.config["calibration"]["x"]["offset"])
            * self.config["calibration"]["x"]["scale"],
            (v_raw[1] - self.config["calibration"]["y"]["offset"])
            * self.config["calibration"]["y"]["scale"],
            (v_raw[2] - self.config["calibration"]["z"]["offset"])
            * self.config["calibration"]["z"]["scale"],
        ]
        # Calculate the heading
        heading = self.correct_heading(
            math.degrees(math.atan2(v[1], v[0])) + self.magnetic_declination_degrees
        )

        # Return the calibrated values in a dictionary
        return {
            "x": v[0],
            "y": v[1],
            "z": v[2],
            "heading": heading,
        }

    # Define the `__write_Reg__` method
    def __write_Reg__(self, reg: int, value: int):
        # Write the `value` to the register `reg` over the I2C bus
        self.__i2c__.writeto_mem(self.__address__, reg, bytearray([value]))

    # Define the `__read_Reg__` method
    def __read_Reg__(self, reg: int, length: int = 1):
        # Read the `length` bytes from the register `reg` over the I2C bus
        return self.__i2c__.readfrom_mem(self.__address__, reg, length)
