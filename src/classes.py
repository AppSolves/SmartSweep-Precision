# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of Cleaning-Robot.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import asyncio
import json
import math
import os
import time

import pyb  # type: ignore
from machine import I2C, Pin, time_pulse_us  # type: ignore

#! CONFIGURATION

pin_map = {
    "D0": "PB7",
    "D1": "PA9",
    "D2": "PA3",
    "D3": "PA2",
    "D4": "PJ8",
    "D5": "PA7",
    "D6": "PD13",
    "D7": "PB4",
    "D8": "PB8",
    "D9": "PB9",
    "D10": "PK1",
    "D11": "PJ10",
    "D12": "PJ11",
    "D13": "PH6",
    "D14": "PG14",
    "D15": "PC7",
    "D16": "PH13",
    "D17": "PI9",
    "D18": "PD5",
    "D19": "PD6",
    "D20": "PB11",
    "D21": "PH4",
    "D22": "PJ12",
    "D23": "PG13",
    "D24": "PG12",
    "D25": "PJ0",
    "D26": "PJ14",
    "D27": "PJ1",
    "D28": "PJ15",
    "D29": "PJ2",
    "D30": "PK3",
    "D31": "PJ3",
    "D32": "PK4",
    "D33": "PJ4",
    "D34": "PK5",
    "D35": "PJ5",
    "D36": "PK6",
    "D37": "PJ6",
    "D38": "PJ7",
    "D39": "PI14",
    "D40": "PE6",
    "D41": "PK7",
    "D42": "PI15",
    "D43": "PI10",
    "D44": "PG10",
    "D45": "PI13",
    "D46": "PH15",
    "D47": "PB2",
    "D48": "PK0",
    "D49": "PE4",
    "D50": "PI11",
    "D51": "PE5",
    "D52": "PK2",
    "D53": "PG7",
    "D54": "PI5",
    "D55": "PH8",
    "D56": "PA6",
    "D57": "PJ9",
    "D58": "PI7",
    "D59": "PI6",
    "D60": "PI4",
    "D61": "PH14",
    "D62": "PG11",
    "D63": "PH11",
    "D64": "PH10",
    "D65": "PH9",
    "D66": "PA1",
    "D67": "PD4",
    "D68": "PC6",
    "D69": "PI0",
    "D70": "PI1",
    "D71": "PI2",
    "D72": "PI3",
    "D73": "PC1",
    "D74": "PB12",
    "D75": "PD3",
    "A0": "PC4",
    "A1": "PC5",
    "A2": "PB0",
    "A3": "PB1",
    "A4": "PC3",
    "A5": "PC2",
    "A6": "PC0",
    "A7": "PA0",
    "A12": "PA4",
    "A13": "PA5",
}

timer_map = {
    "D0": {
        "timer": 17,
        "channel": 1,
    },
    "D1": {
        "timer": 1,
        "channel": 2,
    },
    "D2": {
        "timer": 2,
        "channel": 4,
    },
    "D3": {
        "timer": 2,
        "channel": 3,
    },
    "D4": {
        "timer": 1,
        "channel": 3,
    },
    "D5": {
        "timer": 1,
        "channel": 1,
    },
    "D6": {
        "timer": 1,
        "channel": 1,
    },
    "D7": {
        "timer": 16,
        "channel": 1,
    },
    "D8": {
        "timer": 16,
        "channel": 1,
    },
    "D9": {
        "timer": 17,
        "channel": 1,
    },
    "D10": {
        "timer": 1,
        "channel": 1,
    },
    "D11": {
        "timer": 1,
        "channel": 2,
    },
    "D12": {
        "timer": 1,
        "channel": 2,
    },
    "D13": {
        "timer": None,
        "channel": None,
    },
}


class Singleton:
    def __init__(self, decorated):
        self._decorated = decorated

    def instance(self):
        try:
            return self._instance
        except AttributeError:
            self._instance = self._decorated()
            return self._instance

    def __call__(self):
        raise TypeError("Singletons must be accessed through `instance()`.")

    def __instancecheck__(self, inst):
        return isinstance(inst, self._decorated)


@Singleton
class BoardConfigManager:
    def __init__(self):
        self.__file__ = "../config/board_config.json"
        if not self.isdir("../config"):
            os.mkdir("../config")

        self.reinit()

    @staticmethod
    def isdir(filename):
        try:
            return (os.stat(filename)[0] & 0x4000) != 0
        except OSError:
            return False

    @staticmethod
    def __json_dump__(data, f, indent=4):
        def write_json(data, f, level):
            if isinstance(data, dict):
                f.write("{\n")
                for i, (key, value) in enumerate(data.items()):
                    f.write(" " * indent * (level + 1))
                    f.write(json.dumps(key))
                    f.write(": ")
                    write_json(value, f, level + 1)
                    if i < len(data) - 1:
                        f.write(",")
                    f.write("\n")
                f.write(" " * indent * level)
                f.write("}")
            elif isinstance(data, list):
                f.write("[\n")
                for i, item in enumerate(data):
                    f.write(" " * indent * (level + 1))
                    write_json(item, f, level + 1)
                    if i < len(data) - 1:
                        f.write(",")
                    f.write("\n")
                f.write(" " * indent * level)
                f.write("]")
            else:
                f.write(json.dumps(data))

        write_json(data, f, 0)

    def reinit(self):
        try:
            with open(self.__file__, "r", encoding="utf-8") as f:
                self.__config__ = json.load(f)
        except:
            self.__config__ = {}

    def has(self, key, check_none: bool = False):
        if check_none:
            return key in self.__config__ and self.__config__[key] is not None
        return key in self.__config__

    def get(self, key, default=None):
        return self.__config__.get(key, default)

    def set(self, key, value):
        self.__config__[key] = value
        try:
            with open(self.__file__, "w", encoding="utf-8") as f:
                self.__json_dump__(self.__config__, f)
        except:
            pass


#! GPIO CLASSES


class Button(Pin):
    def __init__(self, pin: str, pull: int | None = Pin.PULL_UP):
        self.__pull__ = pull
        super().__init__(pin_map[pin], Pin.IN, pull)

    @property
    def is_pressed(self) -> bool:
        if self.__pull__ is None:
            return self.value() == 1
        elif self.__pull__ == Pin.PULL_UP:
            return self.value() == 0
        elif self.__pull__ == Pin.PULL_DOWN:
            return self.value() == 1
        return False


#! SENSOR CLASSES


class UltrasonicSensor:
    MAX_RANGE_IN_CM = const(500)  # type: ignore

    def __init__(self, trigger_pin: str, echo_pin: str):
        self.__active__ = True
        self.__distance__ = 0
        self.__trigger_pin__ = Pin(pin_map[trigger_pin], Pin.OUT, pull=None)
        self.__echo_pin__ = Pin(pin_map[echo_pin], Pin.IN, pull=None)
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
            self.__indicator_pin__ = Pin(pin_map[indicator_pin], Pin.OUT)
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


#! ACTUATOR CLASSES


class Motor:
    def __init__(self, pin1: str, pin2: str, enable_pin: str, initial_speed: int = 0):
        self.__pin1__ = Pin(pin_map[pin1], Pin.OUT)
        self.__pin2__ = Pin(pin_map[pin2], Pin.OUT)

        ena_pin = Pin(pin_map[enable_pin], Pin.OUT)
        timer2 = pyb.Timer(timer_map[enable_pin]["timer"], freq=100)

        self.__enable_pin__ = timer2.channel(
            timer_map[enable_pin]["channel"],
            pyb.Timer.PWM,
            pin=ena_pin,
        )
        self.stop()
        self.set_speed(initial_speed)

    def get_speed(self):
        return self.__speed__

    def set_speed(self, speed: int):
        self.__speed__ = 100 if speed > 100 else (0 if speed < 0 else speed)
        self.__enable_pin__.pulse_width_percent(self.__speed__)

    def forward(self):
        self.__pin1__.off()
        self.__pin2__.on()

    def backwards(self):
        self.__pin1__.on()
        self.__pin2__.off()

    def stop(self):
        self.set_speed(0)
        self.__pin1__.off()
        self.__pin2__.off()


class CleaningRobot:
    def __init__(self):
        self.__motor_left__ = Motor(
            pin1="D6",
            pin2="D7",
            enable_pin="D3",
            initial_speed=100,
        )
        self.__motor_right__ = Motor(
            pin1="D5",
            pin2="D4",
            enable_pin="D2",
            initial_speed=100,
        )
        self.__ultrasonic_sensor_left__ = UltrasonicSensor(
            trigger_pin="D10",
            echo_pin="D11",
        )
        self.__ultrasonic_sensor_front__ = UltrasonicSensor(
            trigger_pin="D8",
            echo_pin="D9",
        )
        self.__ultrasonic_sensor_right__ = UltrasonicSensor(
            trigger_pin="D12",
            echo_pin="D13",
        )
        self.__magnetometer__ = Magnetometer(
            I2C(2, freq=400000),
            indicator_pin="D23",
            config={
                "declination": {
                    "degrees": 3,
                    "minutes": 37,
                },
            },
        )
        self.__startstop_button__ = Button(
            pin="D22",
            pull=Pin.PULL_DOWN,
        )
        self.__is_cleaning__ = False

    @property
    def startstop_button(self):
        return self.__startstop_button__

    @property
    def magnetometer(self):
        return self.__magnetometer__

    @property
    def board_config_manager(self):
        return BoardConfigManager.instance()

    @property
    def is_cleaning(self):
        return self.__is_cleaning__

    # When deleting the object, stop the motors and set sensors to inactive
    def __del__(self):
        self.stop_routine()
        self.__magnetometer__.config = {"mode": "standby"}

    def get_distance(self):
        return {
            "left": self.__ultrasonic_sensor_left__.get_distance_mm(),
            "front": self.__ultrasonic_sensor_front__.get_distance_mm(),
            "right": self.__ultrasonic_sensor_right__.get_distance_mm(),
        }

    def get_speed(self):
        return {
            "left": self.__motor_left__.get_speed(),
            "right": self.__motor_right__.get_speed(),
        }

    def __set_speed__(self, speed: dict | int):
        if isinstance(speed, int):
            speed = {
                "left": speed,
                "right": speed,
            }
        self.__motor_left__.set_speed(speed["left"])
        self.__motor_right__.set_speed(speed["right"])

    def __forward__(self):
        self.__motor_left__.forward()
        self.__motor_right__.forward()

    def __backwards__(self):
        self.__motor_left__.backwards()
        self.__motor_right__.backwards()

    def __stop__(self):
        self.__motor_left__.stop()
        self.__motor_right__.stop()

    def __turn_left__(self):
        self.__motor_left__.backwards()
        self.__motor_right__.forward()

    def __smooth_turn_left__(self):
        self.__motor_left__.stop()
        self.__motor_right__.forward()

    def __turn_right__(self):
        self.__motor_left__.forward()
        self.__motor_right__.backwards()

    def __smooth_turn_right__(self):
        self.__motor_left__.forward()
        self.__motor_right__.stop()

    def __turn__(self, degrees: int, speed: int | None = None, smooth: bool = False):
        # Get current magnetometer heading
        heading = self.__magnetometer__.read()["heading"]
        # Calculate target heading
        target_heading = self.magnetometer.correct_heading(heading + degrees)
        # Set speed
        if speed is not None:
            self.__set_speed__(speed)
        # Turn left or right depending on degrees
        if degrees < 0:
            if smooth:
                self.__smooth_turn_left__()
            else:
                self.__turn_left__()
        else:
            if smooth:
                self.__smooth_turn_right__()
            else:
                self.__turn_right__()
        # Loop until target heading is reached
        while True:
            # Get current magnetometer heading
            heading = self.__magnetometer__.read()["heading"]
            # Calculate difference between target heading and current heading
            diff = target_heading - heading
            # If difference is less than 10 degrees, stop turning
            if abs(diff) < 10:
                self.__stop__()
                break
            # Wait 1 millisecond
            time.sleep_ms(10)  # type: ignore

    def stop_routine(self):
        self.__is_cleaning__ = False
        self.__stop__()

    def start_routine(self):
        self.__is_cleaning__ = True
        self.__set_speed__(100)
        self.__loop__ = asyncio.get_event_loop()
        self.__loop__.create_task(self.__listen_for_button__())
        self.__loop__.create_task(self.__routine__())
        self.__loop__.run_forever()
        time.sleep(1)

    async def __listen_for_button__(self):
        await asyncio.sleep(1)
        while self.__is_cleaning__:
            if (
                self.startstop_button.is_pressed
            ):  # Replace with your button checking logic
                self.stop_routine()
            await asyncio.sleep(0.01)  # Sleep for a short time to prevent blocking

        self.__loop__.stop()
        del self.__loop__
        await asyncio.sleep(1)

    async def __routine__(self):
        last_direction = None
        while self.__is_cleaning__:
            distance = self.get_distance()
            heading = self.__magnetometer__.read()["heading"]
            print(heading, distance)

            # Drive to the front until distance is less than 10cm
            if distance["front"] > 100:
                self.__forward__()
            else:
                self.__stop__()
                # Check if he can turn right
                if last_direction == "left":
                    self.__turn__(180, smooth=(distance["right"] > 500))
                    last_direction = "right"
                else:
                    self.__turn__(-180, smooth=(distance["left"] > 500))
                    last_direction = "left"

            await asyncio.sleep(0.1)
