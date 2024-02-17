# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import modules
import asyncio

from src.cleaning_robot import CleaningRobot
from src.connections import ConnectionManager

# Create instances of the `ConnectionManager` and `CleaningRobot` classes
connection_manager = ConnectionManager()
robot = CleaningRobot()


# Define the main function
async def main():
    # Run the robot's main loop
    while True:
        # If the start/stop button is pressed and the robot is not cleaning, start the cleaning routine and send the new state to the client
        if robot.startstop_button.is_pressed and not robot.is_cleaning:
            robot.start_routine()
            await connection_manager.write({"is_cleaning": robot.is_cleaning})
        # If the start/stop button is pressed and the robot is cleaning, stop the cleaning routine and send the new state to the client
        elif robot.startstop_button.is_pressed and robot.is_cleaning:
            robot.stop_routine()
            await connection_manager.write({"is_cleaning": robot.is_cleaning})

        # Sleep for 10 ms to prevent the loop from running too fast
        await asyncio.sleep(0.01)


# Run the main function and the connection manager in parallel
loop = asyncio.get_event_loop()
loop.create_task(main())
loop.create_task(connection_manager.initialize())
loop.run_forever()
