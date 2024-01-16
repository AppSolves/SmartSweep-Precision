# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of Cleaning-Robot.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import asyncio
import time

from machine import I2C, Pin  # type: ignore

from actuators import Motor
from config import BoardConfigManager
from gpio import Button
from sensors import Magnetometer, UltrasonicSensor


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
