# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import json
import os
import shutil
import zipfile
from typing import Annotated

import typer

excl_config = False
app = typer.Typer()
self_file = os.path.basename(__file__)
this_dir = os.path.dirname(os.path.realpath(__file__))


@app.callback()
def main(
    exclude_config: Annotated[
        bool,
        typer.Option(
            ...,
            "--exclude-config",
            "-ec",
            help="Exclude config files when building or syncing the firmware",
        ),
    ] = False,
):
    global excl_config
    excl_config = exclude_config


exclude_files = [
    self_file,
    "README.md",
    ".gitignore",
    "requirements.txt",
    "ble_secrets.json" if excl_config else None,
]
exclude_dirs = [
    "System Volume Information",
    ".vscode",
    ".venv",
    ".git",
    "__pycache__",
    "app",
    "assets",
    "build",
    "config" if excl_config else None,
]


def __change_version__(increase: bool = True):
    with open(os.path.join(this_dir, "info.json")) as f:
        try:
            info = json.load(f)
        except json.JSONDecodeError:
            info = {}
        if info.get("firmware_version", None) is None:
            info["firmware_version"] = "1.0.0"
        else:
            major, minor, patch = map(int, info["firmware_version"].split("."))
            if increase:
                patch += 1
                if patch == 10:
                    patch = 0
                    minor += 1
                    if minor == 10:
                        minor = 0
                        major += 1
            else:
                patch -= 1
                if patch == -1:
                    patch = 9
                    minor -= 1
                    if minor == -1:
                        minor = 9
                        major -= 1
            info["firmware_version"] = f"{major}.{minor}.{patch}"
    with open(os.path.join(this_dir, "info.json"), "w") as f:
        json.dump(info, f, indent=4)


def __get_version__():
    with open(os.path.join(this_dir, "info.json")) as f:
        try:
            info = json.load(f)
        except json.JSONDecodeError:
            info = {}
        return info.get("firmware_version", "1.0.0")


@app.command(help="Sync the firmware to an Arduino drive")
def sync(
    disk: Annotated[
        str,
        typer.Argument(..., help="The drive letter to sync to (e.g. 'P')"),
    ],
):
    arduino_dir = rf"{disk}:"

    if not os.path.exists(arduino_dir):
        typer.echo(f"Drive {disk} does not exist")
        raise typer.Exit(code=1)

    try:
        for root, dirs, files in os.walk(arduino_dir, topdown=False):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]

            for name in files:
                os.remove(os.path.join(root, name))
            for name in dirs:
                os.rmdir(os.path.join(root, name))

        for root, dirs, files in os.walk(this_dir):
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            files[:] = [f for f in files if f not in exclude_files]

            for dir in dirs:
                dir_path = os.path.join(root, dir)
                relative_path = os.path.relpath(dir_path, this_dir)
                shutil.copytree(dir_path, os.path.join(arduino_dir, relative_path))

            for file in files:
                file_path = os.path.join(root, file)
                relative_path = os.path.relpath(file_path, this_dir)
                os.makedirs(
                    os.path.dirname(os.path.join(arduino_dir, relative_path)),
                    exist_ok=True,
                )
                shutil.copy(file_path, os.path.join(arduino_dir, relative_path))

        typer.echo("Sync complete!")

        if excl_config:
            typer.echo("Note: config files were not synced")
    except Exception as e:
        typer.echo(f"Error: {e}")
        raise typer.Exit(code=1)


@app.command(
    help=f"Build the firmware into a zip file (Output directory: build/firmware.zip | Current version: {__get_version__()})"
)
def build():
    try:
        __change_version__()
        shutil.rmtree(os.path.join(this_dir, "build"), ignore_errors=True)
        os.makedirs(os.path.join(this_dir, "build"), exist_ok=True)
        with zipfile.ZipFile(
            os.path.join(this_dir, "build", "firmware.zip"),
            "w",
            compression=zipfile.ZIP_DEFLATED,
            compresslevel=9,
        ) as zipf:
            for root, dirs, files in os.walk(this_dir):
                dirs[:] = [d for d in dirs if d not in exclude_dirs]
                files[:] = [f for f in files if f not in exclude_files]

                for file in files:
                    file_path = os.path.join(root, file)
                    relative_path = os.path.relpath(file_path, this_dir)
                    zipf.write(file_path, relative_path)

        typer.echo("Build complete!")
        typer.echo(f"Output: {os.path.join(this_dir, 'build', 'firmware.zip')}")
    except Exception as e:
        __change_version__(increase=False)
        typer.echo(f"Error: {e}")
        raise typer.Exit(code=1)


@app.command(help="Clean the build directory")
def clean():
    try:
        shutil.rmtree(os.path.join(this_dir, "build"), ignore_errors=True)
        typer.echo("Clean complete!")
    except Exception as e:
        typer.echo(f"Error: {e}")
        raise typer.Exit(code=1)


@app.command(help="Print the current firmware version and exit")
def version():
    typer.echo(f"Firmware Version: {__get_version__()}")


if __name__ == "__main__":
    app()
