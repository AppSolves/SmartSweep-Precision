# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import the necessary libraries
import json
import os


# Define the `Singleton` decorator
def Singleton(cls):
    __instance__ = None

    def __get_instance__(*args, **kwargs):
        nonlocal __instance__
        if __instance__ is None:
            __instance__ = cls(*args, **kwargs)
        return __instance__

    return __get_instance__


# Define the `BoardConfigManager` class
@Singleton
class BoardConfigManager:
    # Define the `__init__` method
    def __init__(self):
        # Define the `__config_file__` and `__info_file__` attributes and initialize the configuration
        self.__config_file__ = "../config/board_config.json"
        self.__info_file__ = "../info.json"
        if not self.isdir("../config"):
            os.mkdir("../config")

        self.reinit()

    # Define the `isdir` method
    @staticmethod
    def isdir(filename):
        # Check if the `filename` is a directory at low-level
        try:
            return (os.stat(filename)[0] & 0x4000) != 0
        except OSError:
            return False

    # Define the `__json_dump__` method
    @staticmethod
    def __json_dump__(data, f, indent=4):
        # Dump the `data` to the file `f` with the given `indent`
        # This method is used because in MicroPython, the `json.dump` method has no `indent` parameter
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

    # Define the `get_immutables` method
    @staticmethod
    def get_immutables():
        # Return the immutable keys that cannot be changed
        return ["firmware_version"]

    # Define the `reinit` method
    def reinit(self):
        # Reinitialize the configuration and update it with the info
        try:
            with open(self.__config_file__, "r", encoding="utf-8") as f:
                self.__config__ = json.load(f)

            with open(self.__info_file__, "r", encoding="utf-8") as f:
                info = json.load(f)
                self.__config__.update(info)
        except:
            self.__config__ = {}

    # Define the `has` method
    def has(self, key, check_none: bool = False):
        # Check if the configuration has the given key
        if check_none:
            return key in self.__config__ and self.__config__[key] is not None
        return key in self.__config__

    # Define the `get` method
    def get(self, key, default=None):
        # Get the value of the given key from the configuration, with the given default value if not found
        return self.__config__.get(key, default)

    # Define the `set` method
    def set(self, key, value):
        # Set the value of the given key in the configuration (if it is not immutable) and save the configuration to the file
        if key in self.get_immutables():
            return

        self.__config__[key] = value
        try:
            with open(self.__config_file__, "w", encoding="utf-8") as f:
                self.__json_dump__(self.__config__, f)
        except:
            pass

    # Define the `delete` method
    def delete(self, key):
        # Delete the given key from the configuration if it exists and save the configuration to the file
        if key in self.get_immutables():
            return

        if self.has(key):
            del self.__config__[key]
            try:
                with open(self.__config_file__, "w", encoding="utf-8") as f:
                    self.__json_dump__(self.__config__, f)
            except:
                pass

    # Define the `pin_map` property
    @property
    def pin_map(self):
        return {
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

    # Define the `timer_map` property
    @property
    def timer_map(self):
        return {
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
