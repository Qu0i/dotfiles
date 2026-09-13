#!/usr/bin/env python3
import os
import time
import sys
import subprocess
import threading


def find_power_supply():
    bat_path = None
    ac_path = None
    if os.path.exists('/sys/class/power_supply'):
        for name in os.listdir('/sys/class/power_supply'):
            if name.startswith('BAT'):
                bat_path = os.path.join('/sys/class/power_supply', name)
            elif name.startswith('AC') or name.startswith('ADP'):
                ac_path = os.path.join('/sys/class/power_supply', name)
    return bat_path, ac_path

def get_battery_info(bat_path):
    if not bat_path:
        return 50, "Unknown"
    
    capacity_file = os.path.join(bat_path, 'capacity')
    status_file = os.path.join(bat_path, 'status')
    
    try:
        with open(capacity_file, 'r') as f:
            capacity = int(f.read().strip())
    except Exception:
        capacity = 50
        
    try:
        with open(status_file, 'r') as f:
            status = f.read().strip()
    except Exception:
        status = "Unknown"
        
    return capacity, status

def is_charger_connected(ac_path, status):
    # Check status first
    if status == "Charging":
        return True
    
    # Check AC online status
    if ac_path:
        online_file = os.path.join(ac_path, 'online')
        try:
            with open(online_file, 'r') as f:
                return f.read().strip() == '1'
        except Exception:
            pass
            
    return False

def send_notification(title, message, urgency="normal", timeout=None, icon=None):
    cmd = ["notify-send"]
    if urgency:
        cmd.extend(["-u", urgency])
    if timeout is not None:
        cmd.extend(["-t", str(timeout)])
    if icon:
        cmd.extend(["-i", icon])
    cmd.extend([title, message])
    try:
        subprocess.run(cmd, check=True)
    except Exception as e:
        print(f"Failed to send notification: {e}", file=sys.stderr)

def kill_process_after_delay(proc, delay):
    time.sleep(delay)
    try:
        if proc.poll() is None:
            proc.terminate()
            proc.wait(timeout=1)
    except Exception:
        pass

def show_rofi_alert(message, duration=5):
    theme_path = "/home/amalskumar/.config/waybar/scripts/battery_rofi.rasi"
    cmd = ["rofi"]
    if os.path.exists(theme_path):
        cmd.extend(["-theme", theme_path])
    cmd.extend(["-e", message])
    try:
        proc = subprocess.Popen(cmd)
        if duration:
            threading.Thread(target=kill_process_after_delay, args=(proc, duration), daemon=True).start()
    except Exception as e:
        print(f"Failed to show rofi alert: {e}", file=sys.stderr)

def get_power_profile():
    try:
        res = subprocess.run(['powerprofilesctl', 'get'], capture_output=True, text=True)
        return res.stdout.strip()
    except Exception:
        return "balanced"

def main():
    bat_path, ac_path = find_power_supply()
    if not bat_path:
        print("No battery detected. Battery monitor exiting.", file=sys.stderr)
        sys.exit(0)
        
    print(f"Starting battery monitor daemon. Battery path: {bat_path}, AC path: {ac_path}")
    
    # Initial state
    capacity, status = get_battery_info(bat_path)
    prev_charging = is_charger_connected(ac_path, status)
    prev_profile = get_power_profile()
    
    low_warning_sent = False
    critical_warning_sent = False
    
    # Thresholds (aligned with waybar configuration)
    LOW_THRESHOLD = 30
    CRITICAL_THRESHOLD = 15
    
    while True:
        try:
            capacity, status = get_battery_info(bat_path)
            charging = is_charger_connected(ac_path, status)
            
            # 0. Power saver brightness control
            profile = get_power_profile()
            if profile == "power-saver" and prev_profile != "power-saver":
                try:
                    subprocess.run(["brightnessctl", "set", "0"], check=True)
                except Exception as e:
                    print(f"Failed to set brightness to 0: {e}", file=sys.stderr)
            prev_profile = profile
            
            # 1. Charger connected detection
            if charging and not prev_charging:
                send_notification(
                    title="Charger Connected",
                    message=f"Battery is charging ({capacity}%)",
                    urgency="normal",
                    timeout=3000, # 3 seconds
                    icon="battery-charging"
                )
                show_rofi_alert(
                    f"   <span color='#c77dff'><b>Charging: {capacity}%</b></span>",
                    duration=3
                )
                # Reset warning flags when plugged in
                low_warning_sent = False
                critical_warning_sent = False
                
            # 2. Charging status changed to disconnected (optional but resets warning states quickly)
            elif not charging and prev_charging:
                # Reset warning flags when unplugged so it will warn immediately if already low
                low_warning_sent = False
                critical_warning_sent = False
                
            # 3. Low/Critical alerts when discharging
            if not charging:
                if capacity <= CRITICAL_THRESHOLD:
                    if not critical_warning_sent:
                        # Show Rofi alert window
                        show_rofi_alert(
                            f"   <span color='#ff5555'><b>Battery Critical: {capacity}%</b></span>",
                            duration=5
                        )
                        critical_warning_sent = True
                        low_warning_sent = True # Don't trigger low warning if critical is triggered
                elif capacity <= LOW_THRESHOLD:
                    if not low_warning_sent:
                        # Show Rofi alert window
                        show_rofi_alert(
                            f"   <span color='#ffd166'><b>Battery Low: {capacity}%</b></span>",
                            duration=5
                        )
                        low_warning_sent = True
                        
                # Hysteresis reset if battery somehow charges/rises while discharging (e.g. calibration or brief replug)
                if capacity > LOW_THRESHOLD + 5:
                    low_warning_sent = False
                if capacity > CRITICAL_THRESHOLD + 5:
                    critical_warning_sent = False
            
            prev_charging = charging
            time.sleep(5)
            
        except KeyboardInterrupt:
            print("Battery monitor daemon terminating.")
            break
        except Exception as e:
            print(f"Error in battery monitor loop: {e}", file=sys.stderr)
            time.sleep(10)

if __name__ == "__main__":
    main()
