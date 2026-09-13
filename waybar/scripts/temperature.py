#!/usr/bin/env python3
import json
import os
import sys
import subprocess

STATS_FILE = '/tmp/waybar_temp_stats.json'

def get_sensor_temp(target_names):
    try:
        for d in os.listdir('/sys/class/hwmon'):
            name_file = os.path.join('/sys/class/hwmon', d, 'name')
            if os.path.exists(name_file):
                with open(name_file, 'r') as f:
                    name = f.read().strip()
                if name in target_names:
                    hwmon_dir = os.path.join('/sys/class/hwmon', d)
                    for file in os.listdir(hwmon_dir):
                        if file.endswith('_input') and file.startswith('temp'):
                            with open(os.path.join(hwmon_dir, file), 'r') as f:
                                return float(f.read().strip()) / 1000.0
    except Exception:
        pass
    return None

def get_cpu_temp():
    try:
        if os.path.exists('/sys/class/thermal/thermal_zone0/temp'):
            with open('/sys/class/thermal/thermal_zone0/temp', 'r') as f:
                return float(f.read().strip()) / 1000.0
    except Exception:
        pass
    
    val = get_sensor_temp(['k10temp', 'coretemp'])
    if val is not None:
        return val
        
    return 45.0

def get_gpu_temp():
    return get_sensor_temp(['amdgpu', 'radeon', 'nouveau', 'nvidia'])

def get_nvme_temp():
    return get_sensor_temp(['nvme'])


def get_platform_profile():
    try:
        res = subprocess.run(['asusctl', 'profile', 'get'], capture_output=True, text=True)
        if res.returncode == 0:
            for line in res.stdout.splitlines():
                if "Active profile:" in line:
                    return line.strip().split()[-1].title()
    except Exception:
        pass

    try:
        if os.path.exists('/sys/firmware/acpi/platform_profile'):
            with open('/sys/firmware/acpi/platform_profile', 'r') as f:
                return f.read().strip().title()
    except Exception:
        pass
    return "Unknown"

def get_sparkline(history):
    if not history:
        return ""
    blocks = [" ", "▂", "▃", "▄", "▅", "▆", "▇", "█"]
    min_val = min(history)
    max_val = max(history)
    val_range = max_val - min_val
    
    if val_range == 0:
        return "".join(blocks[2] for _ in history)
        
    sparkline = []
    for val in history:
        idx = int(((val - min_val) / val_range) * 7)
        sparkline.append(blocks[idx])
    return "".join(sparkline)

def update_device_stats(stats, device_name, current_temp):
    if current_temp is None:
        return
        
    devices = stats.setdefault('devices', {})
    dev_stats = devices.setdefault(device_name, {
        'min_temp': current_temp,
        'max_temp': current_temp,
        'history': []
    })
    
    dev_stats['min_temp'] = min(dev_stats.get('min_temp', current_temp), current_temp)
    dev_stats['max_temp'] = max(dev_stats.get('max_temp', current_temp), current_temp)
    
    history = dev_stats.get('history', [])
    if not isinstance(history, list):
        history = []
    history.append(current_temp)
    if len(history) > 10:
        history = history[-10:]
    dev_stats['history'] = history

def main():
    cpu_temp = get_cpu_temp()
    gpu_temp = get_gpu_temp()
    nvme_temp = get_nvme_temp()
    
    parent_pid = os.getppid()
    
    stats = {}
    if os.path.exists(STATS_FILE):
        try:
            with open(STATS_FILE, 'r') as f:
                stats = json.load(f)
        except Exception:
            pass
            
    # Reset stats if waybar restarted or file is corrupt/old format
    if stats.get('parent_pid') != parent_pid or 'devices' not in stats:
        stats = {
            'parent_pid': parent_pid,
            'devices': {}
        }
        
    # Update stats for active devices
    update_device_stats(stats, 'CPU', cpu_temp)
    if gpu_temp is not None:
        update_device_stats(stats, 'GPU', gpu_temp)
    if nvme_temp is not None:
        update_device_stats(stats, 'NVMe', nvme_temp)
        
    try:
        temp_file = STATS_FILE + '.tmp'
        with open(temp_file, 'w') as f:
            json.dump(stats, f)
        os.replace(temp_file, STATS_FILE)
    except Exception:
        pass
        
    # Collect and format devices data for the table
    devices_data = []
    
    # 1. CPU
    cpu_stats = stats['devices']['CPU']
    cpu_history = cpu_stats['history']
    cpu_spark = get_sparkline(cpu_history)
    cpu_trend, cpu_trend_color = "→", "#888888"
    if len(cpu_history) >= 2:
        diff = cpu_temp - cpu_history[-2]
        if diff > 0.2:
            cpu_trend, cpu_trend_color = "↗", "#ff5555"
        elif diff < -0.2:
            cpu_trend, cpu_trend_color = "↘", "#06d6a0"
    devices_data.append(("CPU", cpu_temp, cpu_stats, cpu_trend, cpu_trend_color, cpu_spark))
    
    # 2. GPU
    if gpu_temp is not None and 'GPU' in stats['devices']:
        gpu_stats = stats['devices']['GPU']
        gpu_history = gpu_stats['history']
        gpu_spark = get_sparkline(gpu_history)
        gpu_trend, gpu_trend_color = "→", "#888888"
        if len(gpu_history) >= 2:
            diff = gpu_temp - gpu_history[-2]
            if diff > 0.2:
                gpu_trend, gpu_trend_color = "↗", "#ff5555"
            elif diff < -0.2:
                gpu_trend, gpu_trend_color = "↘", "#06d6a0"
        devices_data.append(("GPU", gpu_temp, gpu_stats, gpu_trend, gpu_trend_color, gpu_spark))
        
    # 3. NVMe
    if nvme_temp is not None and 'NVMe' in stats['devices']:
        nvme_stats = stats['devices']['NVMe']
        nvme_history = nvme_stats['history']
        nvme_spark = get_sparkline(nvme_history)
        nvme_trend, nvme_trend_color = "→", "#888888"
        if len(nvme_history) >= 2:
            diff = nvme_temp - nvme_history[-2]
            if diff > 0.2:
                nvme_trend, nvme_trend_color = "↗", "#ff5555"
            elif diff < -0.2:
                nvme_trend, nvme_trend_color = "↘", "#06d6a0"
        devices_data.append(("NVMe", nvme_temp, nvme_stats, nvme_trend, nvme_trend_color, nvme_spark))

    # Construct clean monospace columns
    col1 = f"{'Device':<8}"
    col2 = f"{'Current':<12}"
    col3 = f"{'Min':<8}"
    col4 = f"{'Max':<8}"
    col5 = "History"
    
    width = len(f"{col1} {col2} {col3} {col4} {col5}")-15
    divider = "─" * width
    
    tooltip_lines = [
        "<span color='#7b2cb1'><b>  Hardware Thermals</b></span>",
        divider,
        f"<tt><b>{col1} {col2} {col3} {col4} {col5}</b></tt>",
        divider
    ]
    
    for name, curr, d_stats, tr_arr, tr_col, spark in devices_data:
        raw_name = f"{name:<8}"
        raw_curr_temp = f"{curr:.1f}°C"
        
        # Format current temperature with colored arrow and exact spacing
        arrow_part = f"<span color='{tr_col}'>{tr_arr}</span>"
        visible_curr_len = len(raw_curr_temp) + 2
        spaces_curr = " " * max(0, 12 - visible_curr_len)
        curr_markup = f"{raw_curr_temp} {arrow_part}{spaces_curr}"
        
        # Min
        raw_min = f"{d_stats['min_temp']:.1f}°C"
        spaces_min = " " * max(0, 8 - len(raw_min))
        min_markup = f"<span color='#06d6a0'>{raw_min}</span>{spaces_min}"
        
        # Max
        raw_max = f"{d_stats['max_temp']:.1f}°C"
        spaces_max = " " * max(0, 8 - len(raw_max))
        max_markup = f"<span color='#ff5555'>{raw_max}</span>{spaces_max}"
        
        # Spark
        spark_markup = f"<span color='#b388ff'><b>[{spark}]</b></span>"
        
        row = f"<tt><span color='#b388ff'><b>{raw_name}</b></span> {curr_markup} {min_markup} {max_markup} {spark_markup}</tt>"
        tooltip_lines.append(row)
        
    tooltip_lines.append(divider)
    
    # Platform Profile
    profile = get_platform_profile()
    
    profile_color = "#888888"
    if profile.lower() == "performance":
        profile_color = "#ff5555"
    elif profile.lower() == "balanced":
        profile_color = "#ffd166"
    elif profile.lower() == "quiet":
        profile_color = "#06d6a0"
        
    tooltip_lines.append(f"<tt>Profile: </tt><b><span color='{profile_color}'>{profile}</span></b>")
            
    tooltip = "\n".join(tooltip_lines)
    
    # CSS classes based on CPU temp
    css_class = "normal"
    if cpu_temp >= 80:
        css_class = "critical"
    elif cpu_temp >= 65:
        css_class = "warning"
        
    out = {
        "text": f"  {int(round(cpu_temp))}°C {cpu_trend}",
        "tooltip": tooltip,
        "class": css_class
    }
    print(json.dumps(out))

if __name__ == "__main__":
    main()
