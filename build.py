#!/usr/bin/env python3

import subprocess


docker_build_cmd = [
    "docker", "build",
    "--pull", "--no-cache",
    "--tag", "ghcr.io/wfg/wireguard:latest",
    "./build",
]
subprocess.run(docker_build_cmd)
