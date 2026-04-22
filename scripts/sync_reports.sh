#!/bin/bash

REMOTE="root@198.251.76.216:~/DevApps/Wandikweza/Billing/scripts/reports/"
LOCAL="$HOME/Desktop/Git/Billing/scripts/reports/"

echo "Syncing reports from virtual server..."

rsync -avz \
  --ignore-existing \
  $REMOTE \
  $LOCAL

echo "Done."
