# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import the necessary libraries
from machine import Pin  # type: ignore
from pyb import Timer  # type: ignore

from src.config import BoardConfigManager


# Define the `Motor` class
class Motor:
    # Define the `__init__` method
    def __init__(self, pin1: str, pin2: str, enable_pin: str, initial_speed: int = 0):
        # Initialize the `BoardConfigManager` class
        self.__board_config_manager__ = BoardConfigManager()
        # Define the `__pin1__` and `__pin2__` attributes
        self.__pin1__ = Pin(self.__board_config_manager__.pin_map[pin1], Pin.OUT)
        self.__pin2__ = Pin(self.__board_config_manager__.pin_map[pin2], Pin.OUT)

        # Define the enable pin and the timer used to control the motor
        ena_pin = Pin(self.__board_config_manager__.pin_map[enable_pin], Pin.OUT)
        timer2 = Timer(
            self.__board_config_manager__.timer_map[enable_pin]["timer"],
            freq=1000,
        )

        self.__enable_pin__ = timer2.channel(
            self.__board_config_manager__.timer_map[enable_pin]["channel"],
            Timer.PWM,
            pin=ena_pin,
        )
        # Set the initial speed and stop the motor
        self.stop()
        self.speed = initial_speed

    # Define the `speed` property
    @property
    def speed(self):
        return self.__speed__

    # Define the `speed` setter
    @speed.setter
    def speed(self, speed: int):
        # Set the speed of the motor
        self.__speed__ = 100 if speed > 100 else (0 if speed < 0 else speed)
        self.__enable_pin__.pulse_width_percent(self.__speed__)

    # Define the `forward` method
    def forward(self):
        self.__pin1__.off()
        self.__pin2__.on()

    # Define the `backwards` method
    def backwards(self):
        self.__pin1__.on()
        self.__pin2__.off()

    # Define the `stop` method
    def stop(self):
        self.speed = 0
        self.__pin1__.off()
        self.__pin2__.off()
