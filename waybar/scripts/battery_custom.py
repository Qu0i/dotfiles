#!/usr/bin/env python3
import json
import os
import subprocess

def get_battery_info():
    bat_dir = None
    if os.path.exists('/sys/class/power_supply'):
        for d in os.listdir('/sys/class/power_supply'):
            if d.startswith('BAT'):
                bat_dir = os.path.join('/sys/class/power_supply', d)
                break
    if not bat_dir:
        return 50, "Unknown", ""
    
    try:
        with open(os.path.join(bat_dir, 'capacity'), 'r') as f:
            capacity = int(f.read().strip())
    except Exception:
        capacity = 50
        
    try:
        with open(os.path.join(bat_dir, 'status'), 'r') as f:
            status = f.read().strip()
    except Exception:
        status = "Unknown"

    time_str = ""
    try:
        energy_now = None
        power_now = None
        energy_full = None
        
        if os.path.exists(os.path.join(bat_dir, 'energy_now')):
            with open(os.path.join(bat_dir, 'energy_now'), 'r') as f:
                energy_now = int(f.read().strip())
            with open(os.path.join(bat_dir, 'power_now'), 'r') as f:
                power_now = int(f.read().strip())
            with open(os.path.join(bat_dir, 'energy_full'), 'r') as f:
                energy_full = int(f.read().strip())
        elif os.path.exists(os.path.join(bat_dir, 'charge_now')):
            with open(os.path.join(bat_dir, 'charge_now'), 'r') as f:
                energy_now = int(f.read().strip())
            with open(os.path.join(bat_dir, 'current_now'), 'r') as f:
                power_now = int(f.read().strip())
            with open(os.path.join(bat_dir, 'charge_full'), 'r') as f:
                energy_full = int(f.read().strip())

        if energy_now is not None and power_now is not None and power_now > 0:
            if status == "Discharging":
                mins = int((energy_now / power_now) * 60)
                if mins > 60:
                    h = mins // 60
                    m = mins % 60
                    time_str = f"{h}h {m}m"
                else:
                    time_str = f"{mins}m"
            elif status == "Charging" and energy_full is not None:
                remaining_energy = energy_full - energy_now
                if remaining_energy > 0:
                    mins = int((remaining_energy / power_now) * 60)
                    if mins > 60:
                        h = mins // 60
                        m = mins % 60
                        time_str = f"{h}h {m}m"
                    else:
                        time_str = f"{mins}m"
    except Exception:
        pass
        
    return capacity, status, time_str

def get_power_profile():
    try:
        res = subprocess.run(['asusctl', 'profile', 'get'], capture_output=True, text=True)
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                if "Active profile:" in line:
                    val = line.strip().split()[-1].lower()
                    if val == "quiet":
                        return "power-saver"
                    return val
    except Exception:
        pass

    try:
        res = subprocess.run(['powerprofilesctl', 'get'], capture_output=True, text=True)
        return res.stdout.strip()
    except Exception:
        return "balanced"

def main():
    capacity, status, time_str = get_battery_info()
    profile = get_power_profile()
    
    if profile == "power-saver":
        icon = ""
        css_class = "power-saver"
    else:
        css_class = "normal"
        if status == "Charging" or status == "Full":
            icon = ""
            css_class = "charging"
        else:
            icons = ["", "", "", "", ""]
            idx = min(capacity // 20, 4)
            icon = icons[idx]
            
    if capacity <= 15:
        css_class += " critical"
    elif capacity <= 30:
        css_class += " warning"
        
    text = f"{icon}  {capacity}%"
    
    tooltip_lines = [
        f"Battery: {capacity}%",
        f"Status: {status}"
    ]
    if time_str:
        if status == "Charging":
            tooltip_lines.append(f"Time to Full: {time_str}")
        else:
            tooltip_lines.append(f"Time Remaining: {time_str}")
    tooltip_lines.append(f"Profile: {profile.capitalize()}")
    tooltip = "\n".join(tooltip_lines)
    
    out = {
        "text": text,
        "tooltip": tooltip,
        "class": css_class
    }
    print(json.dumps(out))

if __name__ == "__main__":
    main()
