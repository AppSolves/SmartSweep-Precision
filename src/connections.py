# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import asyncio
import json

import aioble  # type:ignore
import bluetooth  # type:ignore
from micropython import const  # type:ignore

from src.cleaning_robot import CleaningRobot
from src.config import BoardConfigManager, Singleton


@Singleton
class ConnectionManager:
    def __init__(self) -> None:
        self.__MICROCONTROLLER_SERVICE_UUID__ = bluetooth.UUID(
            "57b83ac1-34d0-418a-bf25-bfacd5d9ac3a"
        )
        self.__MICROCONTROLLER_DATA_CHAR_UUID__ = bluetooth.UUID(
            "57b83ac2-34d0-418a-bf25-bfacd5d9ac3a"
        )
        self.__APPEARANCE__ = const(384)  # type: ignore
        self.__ADV_INTERVAL_US__ = const(250000)  # type: ignore

        microcontroller_service = aioble.Service(self.__MICROCONTROLLER_SERVICE_UUID__)
        self.__data_char__ = aioble.Characteristic(
            microcontroller_service,
            self.__MICROCONTROLLER_DATA_CHAR_UUID__,
            read=True,
            write=True,
            notify=True,
            capture=True,
        )

        aioble.register_services(microcontroller_service)
        aioble.core.ble.gatts_set_buffer(self.__data_char__._value_handle, 512)

        self.__board_config_manager__ = BoardConfigManager()
        self.__robot__ = CleaningRobot()

    async def initialize(self):
        await asyncio.gather(
            self.__wait_connections__(),
            self.__listener__(),
        )

    async def write(self, data: dict):
        return await self.__data_char__.write(
            json.dumps(data).encode("utf-8"),
            send_update=True,
        )

    async def __handle_commands__(self, data: str):
        async def __send_cleaning_status__():
            is_cleaning_data = {
                "is_cleaning": self.__robot__.is_cleaning,
                "firmware_version": self.__board_config_manager__.get(
                    "firmware_version", "UNKNOWN"
                ),
            }
            await self.write(is_cleaning_data)

        try:
            command = json.loads(data)
            if command["command"] == "request_initial_info":
                await __send_cleaning_status__()
            elif command["command"] == "start_cleaning":
                self.__robot__.start_routine()
                await __send_cleaning_status__()
            elif command["command"] == "stop_cleaning":
                self.__robot__.stop_routine()
                await __send_cleaning_status__()
            elif command["command"] == "move_forward":
                if self.__robot__.is_cleaning:
                    return
                self.__robot__.forward()
                print("Moving Forward")
            elif command["command"] == "move_backward":
                if self.__robot__.is_cleaning:
                    return
                self.__robot__.backwards()
                print("Moving Backward")
            elif command["command"] == "turn_left":
                if self.__robot__.is_cleaning:
                    return
                self.__robot__.turn_left()
                print("Turning Left")
            elif command["command"] == "turn_right":
                if self.__robot__.is_cleaning:
                    return
                self.__robot__.turn_right()
                print("Turning Right")
            elif command["command"] == "stop":
                if self.__robot__.is_cleaning:
                    return
                self.__robot__.stop()
                print("Stopped")
                await self.write({"stopped": True})
            elif command["command"] == "set_speed":
                if self.__robot__.is_cleaning:
                    return
                self.__robot__.set_speed(command["speed"])
                print(f"Set Speed: {command['speed']}")
                await self.write({"speed_set": command["speed"]})
            else:
                print(f"Unknown Command: {command}")
        except Exception as e:
            if type(e) is not TypeError:
                print(f"Error Handling Command: {e}")

    async def __wait_connections__(self):
        while True:
            try:
                async with await aioble.advertise(
                    self.__ADV_INTERVAL_US__,
                    name="SmartSweep GT",
                    services=[self.__MICROCONTROLLER_SERVICE_UUID__],
                    appearance=self.__APPEARANCE__,
                ) as connection:
                    await connection.disconnected(timeout_ms=None)
            except Exception as e:
                print(f"Error Connection Waiter: {e}")

    async def __listener__(self):
        while True:
            try:
                _, data = await self.__data_char__.written()
                res = data.decode("utf-8")
                await self.__handle_commands__(res)
                await asyncio.sleep(0.01)
            except Exception as e:
                print(f"Error Listener: {e}")
                await asyncio.sleep(1)
