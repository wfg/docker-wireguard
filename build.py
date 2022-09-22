#!/usr/bin/env python3

import datetime
import subprocess


image_tag = 'latest'

docker_build_cmd = [
    'docker', 'build',
    '--build-arg', f'BUILD_DATE={str(datetime.datetime.utcnow())}',
    '--build-arg', f'IMAGE_VERSION={image_tag}',
    '--tag', f'ghcr.io/wfg/wireguard:{image_tag}',
    './build',
]
subprocess.run(docker_build_cmd)
