import pyb  # type:ignore

from src.connections import setup_connections

# setup_connections()

pyb.main("main.py")
pyb.usb_mode("VCP+MSC")
