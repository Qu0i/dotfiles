#!/usr/bin/env python3
import json
import subprocess

def get_uptime_seconds():
    try:
        with open('/proc/uptime', 'r') as f:
            return float(f.readline().split()[0])
    except Exception:
        return 0.0

def get_running_services(is_user=False):
    cmd = ['systemctl']
    if is_user:
        cmd.append('--user')
    cmd.extend(['list-units', '--type=service', '--state=running', '--no-legend'])
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode('utf-8')
    except Exception:
        return []
    
    services = []
    for line in out.strip().split('\n'):
        if not line:
            continue
        parts = line.split()
        if parts:
            services.append(parts[0])
    return services

def get_service_durations(services, is_user=False):
    if not services:
        return {}
    cmd = ['systemctl']
    if is_user:
        cmd.append('--user')
    cmd.extend(['show'] + services + ['-p', 'Id', '-p', 'ActiveEnterTimestampMonotonic'])
    try:
        out = subprocess.check_output(cmd, stderr=subprocess.DEVNULL).decode('utf-8')
    except Exception:
        return {}
    
    durations = {}
    blocks = out.strip().split('\n\n')
    for block in blocks:
        lines = block.split('\n')
        service_id = None
        mono_time = None
        for line in lines:
            if line.startswith('Id='):
                service_id = line.split('=', 1)[1]
            elif line.startswith('ActiveEnterTimestampMonotonic='):
                val = line.split('=', 1)[1]
                if val:
                    try:
                        mono_time = int(val)
                    except ValueError:
                        pass
        if service_id and mono_time is not None:
            durations[service_id] = mono_time
    return durations

def format_duration(seconds):
    if seconds < 0:
        seconds = 0
    seconds = int(seconds)
    if seconds < 60:
        return f"{seconds}s"
    minutes = seconds // 60
    if minutes < 60:
        return f"{minutes}m {seconds % 60}s"
    hours = minutes // 60
    if hours < 24:
        return f"{hours}h {minutes % 60}m"
    days = hours // 24
    return f"{days}d {hours % 24}h"

def main():
    uptime = get_uptime_seconds()
    
    # Query system services
    sys_services = get_running_services(is_user=False)
    sys_durations = get_service_durations(sys_services, is_user=False)
    
    # Query user services
    user_services = get_running_services(is_user=True)
    user_durations = get_service_durations(user_services, is_user=True)
    
    tooltip_lines = []
    tooltip_lines.append("<span color='#c77dff'><b>󰊠  Running Daemons &amp; Runtimes</b></span>")
    tooltip_lines.append("─────────────────────────────")
    
    if sys_durations:
        tooltip_lines.append("<b>System Services:</b>")
        for s in sorted(sys_durations.keys()):
            mono = sys_durations[s]
            if mono > 0:
                runtime = uptime - (mono / 1000000.0)
                dur_str = format_duration(runtime)
            else:
                dur_str = "unknown"
            name = s.replace('.service', '')
            if len(name) > 35:
                name = name[:32] + "..."
            tooltip_lines.append(f"<tt>  <span color='#b388ff'>%-35s</span> <span color='#06d6a0'>%8s</span></tt>" % (name, dur_str))
            
    if user_durations:
        if sys_durations:
            tooltip_lines.append("")
        tooltip_lines.append("<b>User Services:</b>")
        for s in sorted(user_durations.keys()):
            mono = user_durations[s]
            if mono > 0:
                runtime = uptime - (mono / 1000000.0)
                dur_str = format_duration(runtime)
            else:
                dur_str = "unknown"
            name = s.replace('.service', '')
            if len(name) > 35:
                name = name[:32] + "..."
            tooltip_lines.append(f"<tt>  <span color='#b388ff'>%-35s</span> <span color='#06d6a0'>%8s</span></tt>" % (name, dur_str))
            
    tooltip_text = "\n".join(tooltip_lines)
    
    output = {
        "text": "󰊠",
        "tooltip": tooltip_text,
        "class": "daemons"
    }
    
    print(json.dumps(output))

if __name__ == "__main__":
    main()
