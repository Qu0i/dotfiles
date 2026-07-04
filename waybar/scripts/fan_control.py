#!/usr/bin/env python3
import json
import os
import sys
import subprocess

def get_asus_fans():
    fans = {}
    try:
        for d in os.listdir('/sys/class/hwmon'):
            name_file = os.path.join('/sys/class/hwmon', d, 'name')
            if os.path.exists(name_file):
                with open(name_file, 'r') as f:
                    name = f.read().strip()
                if name == 'asus':
                    hwmon_dir = os.path.join('/sys/class/hwmon', d)
                    for i in range(1, 5):
                        input_file = os.path.join(hwmon_dir, f'fan{i}_input')
                        label_file = os.path.join(hwmon_dir, f'fan{i}_label')
                        if os.path.exists(input_file):
                            with open(input_file, 'r') as f_in:
                                speed = int(f_in.read().strip())
                            label = f"Fan {i}"
                            if os.path.exists(label_file):
                                with open(label_file, 'r') as f_lbl:
                                    label = f_lbl.read().strip().replace('_', ' ').title()
                            fans[label] = speed
                    break
    except Exception:
        pass
    return fans

def get_platform_profile():
    try:
        res = subprocess.run(['asusctl', 'profile', 'get'], capture_output=True, text=True)
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                if "Active profile:" in line:
                    return line.strip().split()[-1].lower()
    except Exception:
        pass

    try:
        if os.path.exists('/sys/firmware/acpi/platform_profile'):
            with open('/sys/firmware/acpi/platform_profile', 'r') as f:
                return f.read().strip().lower()
    except Exception:
        pass
    return "balanced"

def main():
    fans = get_asus_fans()
    profile = get_platform_profile()
    
    cpu_speed = fans.get("Cpu Fan", 0)
    if cpu_speed == 0 and fans:
        cpu_speed = list(fans.values())[0]
        
    text = f"  {cpu_speed} RPM"
    
    is_high = profile in ["performance", "turbo"]
    is_quiet = profile in ["quiet", "power-saver"]
    
    if is_high:
        css_class = "high"
        mode_label = "Performance (High Speed)"
        profile_color = "#ff5555"
    elif is_quiet:
        css_class = "quiet"
        mode_label = "Quiet (Silent Speed)"
        profile_color = "#06d6a0"
    else:
        css_class = "normal"
        mode_label = "Balanced (Normal Speed)"
        profile_color = "#ffd166"
    
    col1 = f"{'Device':<9}"
    col2 = "Speed"
    width = len(f"{col1} {col2}") + 5
    divider = "─" * width
    
    tooltip_lines = [
        "<span color='#7b2cb1'><b>  Fan Speed Control</b></span>",
        divider
    ]
    
    if fans:
        for name, speed in fans.items():
            lbl = f"{name}:"
            tooltip_lines.append(f"<tt>{lbl:<9}</tt><b>{speed} RPM</b>")
        tooltip_lines.append(divider)
        
    tooltip_lines.append(f"Mode: <b><span color='{profile_color}'>{mode_label}</span></b>")
    tooltip_lines.append("<span color='#888888'>Click to toggle speed</span>")
    
    tooltip = "\n".join(tooltip_lines)
    
    out = {
        "text": text,
        "tooltip": tooltip,
        "class": css_class
    }
    print(json.dumps(out))

if __name__ == "__main__":
    main()
