# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.


from src.cleaning_robot import (
    CleaningRobot,
)  # Importing the CleaningRobot class and time module
from src.connections import asyncio, setup_bluetooth


async def main():
    robot = CleaningRobot()  # Creating a new instance of the CleaningRobot class

    while True:
        if (
            robot.startstop_button.is_pressed and not robot.is_cleaning
        ):  # If the start/stop button is pressed and the robot is not cleaning
            robot.start_routine()  # Start the cleaning routine
        elif robot.startstop_button.is_pressed and robot.is_cleaning:
            robot.stop_routine()

        await asyncio.sleep(0.01)  # Sleep for 0.01 seconds


# Run the main function and the imported setup_bluetooth function in parallel:
loop = asyncio.get_event_loop()
loop.create_task(main())
loop.create_task(setup_bluetooth())
loop.run_forever()
