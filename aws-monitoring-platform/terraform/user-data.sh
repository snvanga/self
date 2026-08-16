#!/bin/bash

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Minimal bootstrap: update and install basic tooling only
apt-get update -y
apt-get install -y wget curl

# marker so automation can detect that cloud-init ran
touch /var/log/user-data-applied

exit 0