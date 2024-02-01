# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import asyncio

import aioble  # type:ignore
import bluetooth  # type:ignore

from src.config import BoardConfigManager


def setup_connections():
    loop = asyncio.get_event_loop()
    loop.run_until_complete(setup_bluetooth())


async def setup_bluetooth():
    board_config_manager = BoardConfigManager()
    _MICROCONTROLLER_SERVICE_UUID = bluetooth.UUID(
        "57b83ac1-34d0-418a-bf25-bfacd5d9ac3a"
    )
    _MICROCONTROLLER_DATA_UUID = bluetooth.UUID("57b83ac2-34d0-418a-bf25-bfacd5d9ac3a")
    _GENERIC_COMPUTER = const(384)  # type: ignore
    _ADV_INTERVAL_US = const(250000)  # type: ignore

    microcontroller_service = aioble.Service(_MICROCONTROLLER_SERVICE_UUID)
    data_char = aioble.Characteristic(
        microcontroller_service,
        _MICROCONTROLLER_DATA_UUID,
        read=True,
        write=True,
        notify=True,
    )

    aioble.register_services(microcontroller_service)

    while True:
        connection = None

        if board_config_manager.get("last_device") is not None:
            device = aioble.Device(
                aioble.PUBLIC, board_config_manager.get("last_device")
            )
            try:
                connection = await device.connect(timeout_ms=2000)
            except asyncio.TimeoutError:
                print("Timeout connecting to last device")

        if not connection or not connection.is_connected():
            connection = await aioble.advertise(
                _ADV_INTERVAL_US,
                name="SmartSweep GT",
                services=[_MICROCONTROLLER_SERVICE_UUID],
                appearance=_GENERIC_COMPUTER,
                manufacturer=(0xABCD, b"1234"),
            )
            board_config_manager.set("last_device", connection.peer_address)
            asyncio.create_task(handle_connection(connection, data_char))

        # Wait for the connection to disconnect before restarting the loop
        while connection and connection.is_connected():
            await asyncio.sleep(1)


async def handle_connection(connection, data_char):
    await connection.wait_for_connection()

    data = await data_char.read()
    print("Received data:", data)

    await data_char.write(b"Hello, world!")
