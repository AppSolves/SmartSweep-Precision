# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import the necessary libraries
import asyncio

from machine import I2C, Pin  # type: ignore
from micropython import const  # type:ignore

from src.actuators import Motor
from src.config import BoardConfigManager, Singleton
from src.gpio import Button
from src.sensors import Magnetometer, UltrasonicSensor


# Define the `CleaningRobot` class
@Singleton
class CleaningRobot:
    # Define the class constants
    DRIVE_SPEED = const(45)
    TURN_SPEED = const(60)
    FRONT_DISTANCE = const(400)
    SIDE_DISTANCE = const(200)
    TURN_DISTANCE = const(450)

    # Define the `__init__` method
    def __init__(self):
        # Define the `Motor` instances
        self.__board_config_manager__ = BoardConfigManager()
        self.__motor_left__ = Motor(
            pin1="D6",
            pin2="D7",
            enable_pin="D3",
            initial_speed=self.DRIVE_SPEED,
        )
        self.__motor_right__ = Motor(
            pin1="D5",
            pin2="D4",
            enable_pin="D2",
            initial_speed=self.DRIVE_SPEED,
        )
        self.__motor_main_brush__ = Pin(
            self.__board_config_manager__.pin_map["D24"],
            Pin.OUT,
        )
        self.__motor_side_brush__ = Pin(
            self.__board_config_manager__.pin_map["D25"],
            Pin.OUT,
        )
        # Define the `UltrasonicSensor` instances
        self.__ultrasonic_sensor_right__ = UltrasonicSensor(
            trigger_pin="D10",
            echo_pin="D11",
        )
        self.__ultrasonic_sensor_left__ = UltrasonicSensor(
            trigger_pin="D8",
            echo_pin="D9",
        )
        self.__ultrasonic_sensor_front__ = UltrasonicSensor(
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
        self.stop()

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
        # Check if the robot is cleaning and the routine task is not done
        if not hasattr(self, "__routine_task__") or self.__routine_task__ is None:
            return False

        return self.__is_cleaning__ and not self.__routine_task__.done()

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
    def __get_speed__(self, as_dict: bool = True):
        if as_dict:
            return {
                "left": self.__motor_left__.speed,
                "right": self.__motor_right__.speed,
            }

        return round(sum([self.__motor_left__.speed, self.__motor_right__.speed]) / 2)

    def toggle_brush(self, brush: str, value: bool):
        if brush == "main":
            self.__motor_main_brush__.value(value)
            return self.__motor_main_brush__.value()
        elif brush == "side":
            self.__motor_side_brush__.value(value)
            return self.__motor_side_brush__.value()
        else:
            raise ValueError("Invalid brush type")

    @property
    def main_brush(self):
        return self.__motor_main_brush__

    @property
    def side_brush(self):
        return self.__motor_side_brush__

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
        target_heading = self.magnetometer.__correct_heading__(heading + degrees)
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
        while self.is_cleaning:
            # Get current magnetometer heading
            heading = self.__magnetometer__.read()["heading"]
            # Calculate difference between target heading and current heading
            diff = target_heading - heading
            # If difference is less than 3 degrees, break the loop
            if abs(diff) < 3:
                break
            # Wait 10 milliseconds
            await asyncio.sleep(0.01)

        self.stop()

    # Define the `stop_routine` method
    def stop_routine(self):
        # Check if the robot is cleaning, if not, return
        if not self.is_cleaning:
            return

        # Set the `is_cleaning` attribute to `False` and cancel the routine task
        self.__is_cleaning__ = False
        self.__routine_task__.cancel()
        # Stop the robot and deactivate the brushes
        self.stop()
        self.toggle_brush("main", False)
        self.toggle_brush("side", False)

    # Define the `start_routine` method
    def start_routine(self):
        # Check if the robot is cleaning, if so, return
        if self.is_cleaning:
            return

        # Set the `is_cleaning` attribute to `True` and start the routine
        self.__is_cleaning__ = True
        self.__routine_task__ = asyncio.create_task(self.__routine__())

    # Define the `__routine__` method
    async def __routine__(self):
        # Activate the brushes and loop while the robot is cleaning
        self.toggle_brush("main", True)
        self.toggle_brush("side", True)
        last_direction = "left"
        while self.is_cleaning:
            # Get the distance
            distance = self.get_distance()

            # Set the speed to self.DRIVE_SPEED (in %) and drive to the front until distance is less than 30cm
            self.set_speed(self.DRIVE_SPEED)
            while distance["front"] > self.FRONT_DISTANCE:
                distance = self.get_distance()
                self.forward()
                await asyncio.sleep(0.01)

            # Turn left or right depending on the last direction and update the last direction
            if last_direction == "left" and distance["right"] >= self.SIDE_DISTANCE:
                smooth = distance["right"] > self.TURN_DISTANCE
                await self.__turn__(
                    180,
                    smooth=smooth,
                    speed=self.TURN_SPEED if smooth else self.DRIVE_SPEED,
                )
                last_direction = "right"
            elif last_direction == "right" and distance["left"] >= self.SIDE_DISTANCE:
                smooth = distance["left"] > self.TURN_DISTANCE
                await self.__turn__(
                    -180,
                    smooth=smooth,
                    speed=self.TURN_SPEED if smooth else self.DRIVE_SPEED,
                )
                last_direction = "left"

            # Wait 10 milliseconds
            await asyncio.sleep(0.01)
