# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import asyncio
import json

import aioble  # type:ignore
import bluetooth  # type:ignore
from micropython import const  # type:ignore

from src.cleaning_robot import CleaningRobot


async def setup_bluetooth():
    _MICROCONTROLLER_SERVICE_UUID = bluetooth.UUID(
        "57b83ac1-34d0-418a-bf25-bfacd5d9ac3a"
    )
    _MICROCONTROLLER_DATA_CHAR_UUID = bluetooth.UUID(
        "57b83ac2-34d0-418a-bf25-bfacd5d9ac3a"
    )
    _APPEARANCE = const(384)  # type: ignore
    _ADV_INTERVAL_US = const(250000)  # type: ignore

    microcontroller_service = aioble.Service(_MICROCONTROLLER_SERVICE_UUID)
    data_char = aioble.Characteristic(
        microcontroller_service,
        _MICROCONTROLLER_DATA_CHAR_UUID,
        read=True,
        write=True,
        notify=True,
        capture=True,
    )

    aioble.register_services(microcontroller_service)
    aioble.core.ble.gatts_set_buffer(data_char._value_handle, 512)

    robot = CleaningRobot()

    async def __handle_commands__(data: str):
        try:
            command = json.loads(data)
            if command["command"] == "start_cleaning":
                robot.start_routine()
                if robot.is_cleaning:
                    is_cleaning_data = {"is_cleaning": robot.is_cleaning}
                    await data_char.write(
                        json.dumps(is_cleaning_data).encode("utf-8"),
                        send_update=True,
                    )
            elif command["command"] == "stop_cleaning":
                robot.stop_routine()
                if not robot.is_cleaning:
                    is_cleaning_data = {"is_cleaning": robot.is_cleaning}
                    await data_char.write(
                        json.dumps(is_cleaning_data).encode("utf-8"),
                        send_update=True,
                    )
        except Exception as e:
            print(f"Error Handling Command: {e}")

    async def __wait_connections__():
        while True:
            try:
                async with await aioble.advertise(
                    _ADV_INTERVAL_US,
                    name="SmartSweep GT",
                    services=[_MICROCONTROLLER_SERVICE_UUID],
                    appearance=_APPEARANCE,
                ) as connection:
                    is_cleaning_data = {"is_cleaning": robot.is_cleaning}
                    await data_char.write(
                        json.dumps(is_cleaning_data).encode("utf-8"),
                        send_update=True,
                    )
                    await connection.disconnected()
            except Exception as e:
                if type(e) is not TypeError:
                    print(f"Error Connection Waiter: {e}")

    async def __listener__():
        while True:
            try:
                _, data = await data_char.written()
                res = data.decode("utf-8")
                await __handle_commands__(res)
                await asyncio.sleep(0.1)
            except Exception as e:
                print(f"Error Listener: {e}")
                await asyncio.sleep(1)

    await asyncio.gather(__wait_connections__(), __listener__())
