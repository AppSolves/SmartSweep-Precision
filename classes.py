# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

from enum import Enum


class Color(Enum):
    HEADER = "\033[95m"
    WHITE = "\033[37m"
    YELLOW = "\033[33m"
    GREEN = "\033[32m"
    BLUE = "\033[34m"
    CYAN = "\033[36m"
    PURPLE = "\033[35m"
    RED = "\033[31m"
    MAGENTA = "\033[35m"
    GREY = "\033[30m"
    LIGHTBLUE = "\033[94m"
    LIGHTCYAN = "\033[96m"
    LIGHTGREEN = "\033[92m"
    WARNING = "\033[93m"
    FAIL = "\033[91m"
    ENDC = "\033[0m"
    BOLD = "\033[1m"
    UNDERLINE = "\033[4m"

    @classmethod
    def colorize(cls, text: str, color: "Color"):
        return color.value + text + cls.ENDC.value
