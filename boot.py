# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of Cleaning-Robot.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import pyb  # type:ignore

from src.connections import setup_connections

# setup_connections()

pyb.main("main.py")
pyb.usb_mode("VCP+MSC")
