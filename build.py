#!/usr/bin/env python3

import datetime
import subprocess


docker_build_cmd = [
    'docker', 'build',
    '--build-arg', f'BUILD_DATE={str(datetime.datetime.utcnow())}',
    '--build-arg', f'IMAGE_VERSION=testing',
    '--tag', f'ghcr.io/wfg/wireguard:latest',
    './build',
]
subprocess.run(docker_build_cmd)
