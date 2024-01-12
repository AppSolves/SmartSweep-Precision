import os
import shutil
from typing import Annotated, Optional

import typer

app = typer.Typer()


@app.command()
def sync(
    disk: Annotated[
        str,
        typer.Argument(..., help="The drive to sync to (e.g. 'P:')"),
    ],
    include_config: Annotated[
        Optional[bool],
        typer.Option(..., "--include-config", "-i", help="Include config files"),
    ] = False,
):
    if not os.path.exists(disk):
        typer.echo(f"Drive {disk} does not exist")
        raise typer.Exit(code=1)

    try:
        this_dir = os.path.dirname(os.path.realpath(__file__))
        arduino_dir = rf"{disk}:"

        exclude_files = ["sync.py"]
        exclude_dirs = [
            "System Volume Information",
            ".vscode",
            ".venv",
            "app",
            "config" if not include_config else None,
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

        if not include_config:
            typer.echo("Note: config files were not synced")
    except Exception as e:
        typer.echo(f"Error: {e}")
        raise typer.Exit(code=1)


if __name__ == "__main__":
    app()
