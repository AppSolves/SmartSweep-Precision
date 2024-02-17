# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

# Import the `pyboard` library
import pyb  # type:ignore

# Enable USB serial and mass storage, then run `main.py`
pyb.usb_mode("VCP+MSC")
pyb.main("main.py")
