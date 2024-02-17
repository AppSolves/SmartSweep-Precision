# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import the necessary libraries
from machine import Pin  # type: ignore

from src.config import BoardConfigManager


# Define the `Button` class
class Button(Pin):
    # Define the `__init__` method
    def __init__(self, pin: str, pull: int | None = Pin.PULL_UP):
        # Initialize the `BoardConfigManager` instance
        self.__board_config_manager__ = BoardConfigManager()
        # Set the pin and the pull-up/pull-down resistor
        self.__pull__ = pull
        super().__init__(self.__board_config_manager__.pin_map[pin], Pin.IN, pull)

    # Define the `is_pressed` property
    @property
    def is_pressed(self) -> bool:
        # Check if the button is pressed and return the result
        if self.__pull__ is None or self.__pull__ == Pin.PULL_DOWN:
            return self.value() == 1
        elif self.__pull__ == Pin.PULL_UP:
            return self.value() == 0
        else:
            return False
