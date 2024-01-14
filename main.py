# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of Cleaning-Robot.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

from src.classes import (  # Importing the CleaningRobot class and time module
    CleaningRobot,
    time,
)

robot = CleaningRobot()  # Creating a new instance of the CleaningRobot class

while True:
    if (
        robot.startstop_button.is_pressed and not robot.is_cleaning
    ):  # If the start/stop button is pressed and the robot is not cleaning
        robot.start_routine()  # Start the cleaning routine

    time.sleep(0.01)  # Sleep for 0.01 seconds
