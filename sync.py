# Copyright (c) 2024 Kaan Gönüldinc
# This file is part of SmartSweep Precision.
# It is subject to the terms and conditions of the CC BY-NC-ND 4.0 license.

import os
import shutil
from typing import Annotated, Optional

import typer

app = typer.Typer()
self_file = os.path.basename(__file__)


@app.command()
def sync(
    disk: Annotated[
        str,
        typer.Argument(..., help="The drive letter to sync to (e.g. 'P')"),
    ],
    exclude_config: Annotated[
        Optional[bool],
        typer.Option(..., "--exclude-config", "-ec", help="Exclude config files"),
    ] = False,
):
    this_dir = os.path.dirname(os.path.realpath(__file__))
    arduino_dir = rf"{disk}:"

    if not os.path.exists(arduino_dir):
        typer.echo(f"Drive {disk} does not exist")
        raise typer.Exit(code=1)

    try:
        exclude_files = [
            self_file,
            "README.md",
            ".gitignore",
            "requirements.txt",
            "ble_secrets.json" if exclude_config else None,
        ]
        exclude_dirs = [
            "System Volume Information",
            ".vscode",
            ".venv",
            ".git",
            "__pycache__",
            "app",
            "assets",
            "config" if exclude_config else None,
        ]

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

        if exclude_config:
            typer.echo("Note: config files were not synced")
    except Exception as e:
        typer.echo(f"Error: {e}")
        raise typer.Exit(code=1)


if __name__ == "__main__":
    app()
