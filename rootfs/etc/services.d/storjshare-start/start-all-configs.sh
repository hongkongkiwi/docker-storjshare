#!/bin/bash

for config in /config/*.json; do
  exec "/usr/bin/storjshare-start" -c $config
done
