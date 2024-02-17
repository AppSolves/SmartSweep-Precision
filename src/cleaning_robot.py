# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import the necessary libraries
import asyncio
import time

from machine import I2C, Pin  # type: ignore

from src.actuators import Motor
from src.config import Singleton
from src.gpio import Button
from src.sensors import Magnetometer, UltrasonicSensor


# Define the `CleaningRobot` class
@Singleton
class CleaningRobot:
    # Define the `__init__` method
    def __init__(self):
        # Define the `Motor` instances
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
        # Define the `UltrasonicSensor` instances
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
        # Define the `Magnetometer` instance
        self.__magnetometer__ = Magnetometer(
            I2C(2, freq=400000),
            config={
                "declination": {
                    "degrees": 3,
                    "minutes": 37,
                },
            },
        )
        # Define the `Button` instance
        self.__startstop_button__ = Button(
            pin="D22",
            pull=Pin.PULL_DOWN,
        )
        # Set the `is_cleaning` attribute to `False`
        self.__is_cleaning__ = False

    # Define the `startstop_button` property
    @property
    def startstop_button(self):
        return self.__startstop_button__

    # Define the `magnetometer` property
    @property
    def magnetometer(self):
        return self.__magnetometer__

    # Define the `is_cleaning` property
    @property
    def is_cleaning(self):
        return self.__is_cleaning__

    # When deleting the object, stop the motors and set the magnetometer to inactive
    def __del__(self):
        self.stop_routine()
        self.__magnetometer__.config = {"mode": "standby"}

    # Define the `get_distance` method
    def get_distance(self):
        return {
            "left": self.__ultrasonic_sensor_left__.get_distance_mm(),
            "front": self.__ultrasonic_sensor_front__.get_distance_mm(),
            "right": self.__ultrasonic_sensor_right__.get_distance_mm(),
        }

    # Define the `get_speed` method
    def get_speed(self):
        return {
            "left": self.__motor_left__.speed,
            "right": self.__motor_right__.speed,
        }

    # Define the `set_speed` method
    def set_speed(self, speed: dict | int):
        if isinstance(speed, int):
            speed = {
                "left": speed,
                "right": speed,
            }
        self.__motor_left__.speed = speed["left"]
        self.__motor_right__.speed = speed["right"]

    # Define the `forward` method
    def forward(self):
        self.__motor_left__.forward()
        self.__motor_right__.forward()

    # Define the `backwards` method
    def backwards(self):
        self.__motor_left__.backwards()
        self.__motor_right__.backwards()

    # Define the `stop` method
    def stop(self):
        self.__motor_left__.stop()
        self.__motor_right__.stop()

    # Define the `turn_left` method
    def turn_left(self):
        self.__motor_left__.backwards()
        self.__motor_right__.forward()

    # Define the `smooth_turn_left` method
    def __smooth_turn_left__(self):
        self.__motor_left__.stop()
        self.__motor_right__.forward()

    # Define the `turn_right` method
    def turn_right(self):
        self.__motor_left__.forward()
        self.__motor_right__.backwards()

    # Define the `smooth_turn_right` method
    def __smooth_turn_right__(self):
        self.__motor_left__.forward()
        self.__motor_right__.stop()

    # Define the `turn` method
    async def __turn__(
        self,
        degrees: int,
        speed: int | None = None,
        smooth: bool = False,
    ):
        # Get current magnetometer heading
        heading = self.__magnetometer__.read()["heading"]
        # Calculate target heading
        target_heading = self.magnetometer.correct_heading(heading + degrees)
        # Set speed
        if speed is not None:
            self.set_speed(speed)
        # Turn left or right depending on degrees
        if degrees < 0:
            if smooth:
                self.__smooth_turn_left__()
            else:
                self.turn_left()
        else:
            if smooth:
                self.__smooth_turn_right__()
            else:
                self.turn_right()
        # Loop until target heading is reached
        while True:
            # Get current magnetometer heading
            heading = self.__magnetometer__.read()["heading"]
            # Calculate difference between target heading and current heading
            diff = target_heading - heading
            # If difference is less than 10 degrees, stop turning
            if abs(diff) < 10:
                self.stop()
                break
            # Wait 10 milliseconds
            await asyncio.sleep(0.01)

    # Define the `stop_routine` method
    def stop_routine(self):
        # Check if the robot is cleaning, if not, return
        if not self.__is_cleaning__:
            return

        # Set the `is_cleaning` attribute to `False` and stop the robot
        self.__is_cleaning__ = False
        self.stop()
        time.sleep(1)

    # Define the `start_routine` method
    def start_routine(self):
        # Check if the robot is cleaning, if so, return
        if self.__is_cleaning__:
            return

        # Set the `is_cleaning` attribute to `True`, set the speed to 100 and start the routine
        self.__is_cleaning__ = True
        self.set_speed(100)
        asyncio.create_task(self.__routine__())
        time.sleep(1)

    # Define the `__routine__` method
    async def __routine__(self):
        # Loop until the robot is cleaning
        last_direction = None
        while self.__is_cleaning__:
            # Get the distance and heading
            distance = self.get_distance()
            heading = self.__magnetometer__.read()["heading"]
            print(heading, distance)

            # Drive to the front until distance is less than 10cm
            if distance["front"] > 100:
                self.forward()
            else:
                # Stop the robot
                self.stop()
                # Turn left or right depending on the last direction
                if last_direction == "left":
                    await self.__turn__(180, smooth=(distance["right"] > 500))
                    last_direction = "right"
                else:
                    await self.__turn__(-180, smooth=(distance["left"] > 500))
                    last_direction = "left"

            # Wait 10 milliseconds
            await asyncio.sleep(0.01)
