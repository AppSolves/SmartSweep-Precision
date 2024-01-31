# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

from machine import Pin  # type: ignore
from pyb import Timer  # type: ignore

from src.config import BoardConfigManager


class Motor:
    def __init__(self, pin1: str, pin2: str, enable_pin: str, initial_speed: int = 0):
        self.__board_config_manager__ = BoardConfigManager()
        self.__pin1__ = Pin(self.__board_config_manager__.pin_map[pin1], Pin.OUT)
        self.__pin2__ = Pin(self.__board_config_manager__.pin_map[pin2], Pin.OUT)

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
        self.stop()
        self.speed = initial_speed

    @property
    def speed(self):
        return self.__speed__

    @speed.setter
    def speed(self, speed: int):
        self.__speed__ = 100 if speed > 100 else (0 if speed < 0 else speed)
        self.__enable_pin__.pulse_width_percent(self.__speed__)

    def forward(self):
        self.__pin1__.off()
        self.__pin2__.on()

    def backwards(self):
        self.__pin1__.on()
        self.__pin2__.off()

    def stop(self):
        self.speed = 0
        self.__pin1__.off()
        self.__pin2__.off()
