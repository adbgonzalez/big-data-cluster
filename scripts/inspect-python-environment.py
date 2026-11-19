"""Inspect a container without installing packages or accessing the network."""

import importlib.metadata as metadata
import json
import platform
import subprocess
import sys


def run(*command):
    result = subprocess.run(command, capture_output=True, text=True, check=False)
    return {
        "exit_code": result.returncode,
        "stdout": result.stdout.strip(),
        "stderr": result.stderr.strip(),
    }


packages = sorted(
    (
        {
            "name": distribution.metadata["Name"],
            "version": distribution.version,
            "installer": (distribution.read_text("INSTALLER") or "").strip(),
            "direct_url": distribution.read_text("direct_url.json"),
        }
        for distribution in metadata.distributions()
        if distribution.metadata.get("Name")
    ),
    key=lambda package: package["name"].lower(),
)

print(json.dumps({
    "python": platform.python_version(),
    "python_executable": sys.executable,
    "platform": platform.platform(),
    "packages": packages,
    "pip_freeze": run(sys.executable, "-m", "pip", "freeze", "--all"),
    "pip_check": run(sys.executable, "-m", "pip", "check"),
    "java": run("java", "-version"),
}, indent=2))
