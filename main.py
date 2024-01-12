from src.classes import CleaningRobot, time

robot = CleaningRobot()

while True:
    if robot.startstop_button.is_pressed and not robot.is_cleaning:
        robot.start_routine()

    time.sleep(0.01)
