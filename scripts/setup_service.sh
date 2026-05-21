#!/bin/bash
# Setup script for Hospital Report Service

echo "Setting up Wandikweza Hospital Report Service..."

# Copy service files to systemd directory
sudo cp hospital-report.service /etc/systemd/system/
sudo cp hospital-report.timer /etc/systemd/system/

# Reload systemd to recognize new service
sudo systemctl daemon-reload

# Enable and start the timer
sudo systemctl enable hospital-report.timer
sudo systemctl start hospital-report.timer

# Show timer status
echo ""
echo "Service setup complete!"
echo ""
echo "Timer status:"
sudo systemctl status hospital-report.timer --no-pager
echo ""
echo "Next scheduled run:"
sudo systemctl list-timers hospital-report.timer --no-pager
echo ""
echo "Useful commands:"
echo "  - Check timer status: sudo systemctl status hospital-report.timer"
echo "  - View logs: sudo journalctl -u hospital-report.service"
echo "  - Run manually now: sudo systemctl start hospital-report.service"
echo "  - Stop timer: sudo systemctl stop hospital-report.timer"
echo "  - Disable timer: sudo systemctl disable hospital-report.timer"
