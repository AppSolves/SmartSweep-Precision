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
        # If the start/stop button is pressed, start or stop the cleaning routine
        if robot.startstop_button.is_pressed:
            # If the robot is not cleaning, start the cleaning routine
            if not robot.is_cleaning:
                robot.start_routine()
            # If the robot is cleaning, stop the cleaning routine
            else:
                robot.stop_routine()

            # Update the connection manager with the robot's status and send it to the client
            await connection_manager.write({"is_cleaning": robot.is_cleaning})
            # Sleep for 1 second to prevent the button from being pressed multiple times
            await asyncio.sleep(1)

        # Sleep for 10 ms to prevent the loop from running too fast
        await asyncio.sleep(0.01)


# Run the main function and the connection manager in parallel
loop = asyncio.get_event_loop()
loop.create_task(main())
loop.create_task(connection_manager.initialize())
loop.run_forever()
