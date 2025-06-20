import os

c = get_config()  # noqa

if os.getenv("CULL_TIMEOUT"):
    # shutdown the server after no activity
    c.ServerApp.shutdown_no_activity_timeout = int(os.getenv("CULL_TIMEOUT"))

if os.getenv("CULL_KERNEL_TIMEOUT"):
    # shutdown kernels after no activity
    c.MappingKernelManager.cull_idle_timeout = int(os.getenv("CULL_KERNEL_TIMEOUT"))

if os.getenv("CULL_INTERVAL"):
    # check for idle kernels this often
    c.MappingKernelManager.cull_interval = int(os.getenv("CULL_INTERVAL"))

# a kernel with open connections but no activity still counts as idle
# this is what allows us to shutdown servers when people leave a notebook open and wander off
if os.getenv("CULL_CONNECTED") not in {"", "0"}:
    c.MappingKernelManager.cull_connected = True

c.ContentsManager.hide_globs.extend(["lost+found"])


# set windowing-mode: none because default windowing mode is super broken
import json
from pathlib import Path

tracker_settings = (
    Path.home()
    / ".jupyter/lab/user-settings/@jupyterlab/notebook-extension/tracker.jupyterlab-settings"
)

settings = {"windowingMode": "none"}
if not tracker_settings.exists():
    print(f"Writing windowing mode to {tracker_settings}")
    tracker_settings.parent.mkdir(parents=True, exist_ok=True)

    with tracker_settings.open("w") as f:
        json.dump({"windowingMode": "none"}, f)
