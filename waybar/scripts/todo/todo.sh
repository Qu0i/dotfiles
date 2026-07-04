#!/bin/bash

# Directory and file paths
TODO_DIR="$HOME/.config/waybar/scripts/todo"
TASK_FILE="$TODO_DIR/tasks.txt"
CONF_FILE="$TODO_DIR/todo.conf"
touch "$TASK_FILE"
touch "$CONF_FILE"

# Source the configuration file
[ -s "$CONF_FILE" ] && source "$CONF_FILE"

# --- Function to format seconds to MM:SS or HH:MM:SS ---
format_seconds() {
    local sec=$1
    if (( sec <= 0 )); then
        echo "00:00"
        return
    fi
    local h=$(( sec / 3600 ))
    local m=$(( (sec % 3600) / 60 ))
    local s=$(( sec % 60 ))
    if (( h > 0 )); then
        printf "%02d:%02d:%02d" $h $m $s
    else
        printf "%02d:%02d" $m $s
    fi
}

# --- Handle Click Actions ---
case "$1" in
    middle_click)
        if [[ "$MIDDLE_CLICK_ACTION" == "all" ]]; then
            > "$TASK_FILE"
        elif [[ "$MIDDLE_CLICK_ACTION" == "completed" ]]; then
            sed -i '/|1|/d' "$TASK_FILE"
        fi
        exit 0
        ;;
esac

# --- Generate Waybar JSON Output ---

# Find running task if any
running_task_line=""
while IFS='|' read -r prio status desc accumulated start_time || [[ -n "$prio" ]]; do
    [[ -z "$prio" ]] && continue
    status=${status:-0}
    start_time=${start_time:-0}
    if [[ "$status" -eq 0 ]] && (( start_time > 0 )); then
        running_task_line="$prio|$status|$desc|$accumulated|$start_time"
        break
    fi
done < <(sort -n -t'|' -k1 "$TASK_FILE")

tooltip=""
full_bar_text=""

if [[ ! -s "$TASK_FILE" ]]; then
    bar_text="Add a task!"
    tooltip="Click to manage tasks"
else
    if [[ -n "$running_task_line" ]]; then
        IFS='|' read -r prio status desc accumulated start_time <<< "$running_task_line"
        now=$(date +%s)
        elapsed=$(( accumulated + now - start_time ))
        timer_str=$(format_seconds $elapsed)
        full_bar_text="⏱  $desc ($timer_str)"
    else
        top_pending_line=$(grep '^[^|]*|0|' "$TASK_FILE" | sort -n -t'|' -k1 | head -n 1)
        if [[ -n "$top_pending_line" ]]; then
            IFS='|' read -r prio status desc accumulated start_time <<< "$top_pending_line"
            full_bar_text="📋  $desc"
        else
            full_bar_text="✔ All Done!"
        fi
    fi

    # Truncation Logic
    if (( ${#full_bar_text} > 26 )); then
        bar_text="$(echo "$full_bar_text" | cut -c1-23)..."
    else
        bar_text="$full_bar_text"
    fi

    tooltip="<b><u>Todo List\n</u></b>\n"
    pending_tasks=""
    completed_tasks=""

    while IFS='|' read -r prio status desc accumulated start_time || [[ -n "$prio" ]]; do
        [[ -z "$prio" ]] && continue
        status=${status:-0}
        accumulated=${accumulated:-0}
        start_time=${start_time:-0}
        
        # Calculate current elapsed
        elapsed=$accumulated
        if (( start_time > 0 )); then
            now=$(date +%s)
            elapsed=$(( accumulated + now - start_time ))
        fi

        time_suffix=""
        if (( elapsed > 0 )); then
            time_suffix=" [$(format_seconds $elapsed)]"
        fi

        if [[ "$status" -eq 1 ]]; then
            completed_tasks+="<s>$desc</s>$time_suffix\n"
        else
            if (( start_time > 0 )); then
                pending_tasks+="▶ <b>$desc</b> <span foreground='#c77dff'>$time_suffix</span>\n"
            else
                pending_tasks+="$desc$time_suffix\n"
            fi
        fi
    done < <(sort -n -t'|' -k1 "$TASK_FILE")

    tooltip+="$pending_tasks"
    tooltip+="$completed_tasks"

    if [[ -n "$running_task_line" ]]; then
        tooltip+="\n<b>Currently tracking:</b> $desc"
    elif [[ -n "$top_pending_line" ]]; then
        IFS='|' read -r prio status desc accumulated start_time <<< "$top_pending_line"
        tooltip+="\n<b>Next task:</b> $desc"
    else
        tooltip+="\n<b>All tasks cleared. Great job!</b>"
    fi
fi

# --- Final JSON Output ---
bar_text_json=$(echo "\u00a0\u00a0$bar_text" | sed 's/"/\\"/g')
tooltip_json=$(echo -e "$tooltip" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"text": "%s", "tooltip": "%s"}\n' "$bar_text_json" "$tooltip_json"