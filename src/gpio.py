# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of Cleaning-Robot.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

from machine import Pin  # type: ignore

from src.config import BoardConfigManager


class Button(Pin):
    def __init__(self, pin: str, pull: int | None = Pin.PULL_UP):
        self.__board_config_manager__ = BoardConfigManager.instance()
        self.__pull__ = pull
        super().__init__(self.__board_config_manager__.pin_map[pin], Pin.IN, pull)

    @property
    def is_pressed(self) -> bool:
        if self.__pull__ is None:
            return self.value() == 1
        elif self.__pull__ == Pin.PULL_UP:
            return self.value() == 0
        elif self.__pull__ == Pin.PULL_DOWN:
            return self.value() == 1
        return False
