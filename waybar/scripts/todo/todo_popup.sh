#!/bin/bash
# ---------------------------------------------------------------------------
#  todo_popup.sh  –  Rofi-based popup todo manager for Waybar
#  Supports task-specific timers, start/pause controls, and live active task display.
# ---------------------------------------------------------------------------

TODO_DIR="$HOME/.config/waybar/scripts/todo"
TASK_FILE="$TODO_DIR/tasks.txt"
THEME="$TODO_DIR/todo_rofi.rasi"
touch "$TASK_FILE"

# ── rofi helpers ────────────────────────────────────────────────────────────

rofi_list() {
    # stdin: display lines; $1 = prompt; $2 = message/active_msg; rest = extra args
    local prompt="$1"
    local mesg="$2"
    shift 2
    rofi -dmenu -p "$prompt" -mesg "$mesg" -theme "$THEME" -markup-rows "$@"
}

rofi_input() {
    local prompt="$1"
    rofi -dmenu -p "$prompt" -theme "$THEME" -lines 0 -input /dev/null
}

# ── time helpers ─────────────────────────────────────────────────────────────

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

# ── task actions ─────────────────────────────────────────────────────────────

next_priority() {
    if [[ ! -s "$TASK_FILE" ]]; then echo 1; return; fi
    local max
    max=$(awk -F'|' '{print $1}' "$TASK_FILE" | sort -n | tail -n1)
    echo $(( max + 1 ))
}

add_task() {
    local desc
    desc=$(rofi_input "＋ New task:")
    [[ -z "$desc" ]] && return
    local prio
    prio=$(next_priority)
    echo "${prio}|0|${desc}|0|0" >> "$TASK_FILE"
    sort -n -t'|' -k1 "$TASK_FILE" -o "$TASK_FILE"
}

pause_all_except() {
    local target_prio="$1"
    local now
    now=$(date +%s)
    local tmp_file
    tmp_file=$(mktemp)
    
    while IFS='|' read -r prio status desc accumulated start_time || [[ -n "$prio" ]]; do
        [[ -z "$prio" ]] && continue
        status=${status:-0}
        accumulated=${accumulated:-0}
        start_time=${start_time:-0}
        
        if [[ "$prio" != "$target_prio" ]] && (( start_time > 0 )); then
            local diff=$(( now - start_time ))
            accumulated=$(( accumulated + diff ))
            start_time=0
        fi
        echo "$prio|$status|$desc|$accumulated|$start_time" >> "$tmp_file"
    done < "$TASK_FILE"
    
    mv "$tmp_file" "$TASK_FILE"
}

start_tracking() {
    local target_row="$1"
    local target_prio
    target_prio=$(sed -n "${target_row}p" "$TASK_FILE" | cut -d'|' -f1)
    
    pause_all_except "$target_prio"
    
    local now
    now=$(date +%s)
    local tmp_file
    tmp_file=$(mktemp)
    local idx=1
    while IFS='|' read -r prio status desc accumulated start_time || [[ -n "$prio" ]]; do
        [[ -z "$prio" ]] && continue
        status=${status:-0}
        accumulated=${accumulated:-0}
        start_time=${start_time:-0}
        
        if [[ "$idx" -eq "$target_row" ]]; then
            start_time=$now
        fi
        echo "$prio|$status|$desc|$accumulated|$start_time" >> "$tmp_file"
        idx=$(( idx + 1 ))
    done < "$TASK_FILE"
    
    mv "$tmp_file" "$TASK_FILE"
}

pause_tracking() {
    local target_row="$1"
    local now
    now=$(date +%s)
    local tmp_file
    tmp_file=$(mktemp)
    local idx=1
    while IFS='|' read -r prio status desc accumulated start_time || [[ -n "$prio" ]]; do
        [[ -z "$prio" ]] && continue
        status=${status:-0}
        accumulated=${accumulated:-0}
        start_time=${start_time:-0}
        
        if [[ "$idx" -eq "$target_row" ]]; then
            if (( start_time > 0 )); then
                local diff=$(( now - start_time ))
                accumulated=$(( accumulated + diff ))
            fi
            start_time=0
        fi
        echo "$prio|$status|$desc|$accumulated|$start_time" >> "$tmp_file"
        idx=$(( idx + 1 ))
    done < "$TASK_FILE"
    
    mv "$tmp_file" "$TASK_FILE"
}

toggle_line() {
    local target_row="$1"
    local now
    now=$(date +%s)
    local tmp_file
    tmp_file=$(mktemp)
    local idx=1
    while IFS='|' read -r prio status desc accumulated start_time || [[ -n "$prio" ]]; do
        [[ -z "$prio" ]] && continue
        status=${status:-0}
        accumulated=${accumulated:-0}
        start_time=${start_time:-0}
        
        if [[ "$idx" -eq "$target_row" ]]; then
            if [[ "$status" -eq 0 ]]; then
                if (( start_time > 0 )); then
                    local diff=$(( now - start_time ))
                    accumulated=$(( accumulated + diff ))
                fi
                start_time=0
                status=1
            else
                status=0
            fi
        fi
        echo "$prio|$status|$desc|$accumulated|$start_time" >> "$tmp_file"
        idx=$(( idx + 1 ))
    done < "$TASK_FILE"
    
    mv "$tmp_file" "$TASK_FILE"
}

delete_line() {
    sed -i "${1}d" "$TASK_FILE"
}

# ── main popup ───────────────────────────────────────────────────────────────

show_popup() {
    local -a display_lines
    local running_desc=""
    local running_time_str=""
    local now
    now=$(date +%s)
    
    sort -n -t'|' -k1 "$TASK_FILE" -o "$TASK_FILE"

    while IFS='|' read -r prio status desc accumulated start_time || [[ -n "$prio" ]]; do
        [[ -z "$prio" ]] && continue
        status=${status:-0}
        accumulated=${accumulated:-0}
        start_time=${start_time:-0}
        
        local elapsed=$accumulated
        if (( start_time > 0 )); then
            elapsed=$(( accumulated + now - start_time ))
            running_desc="$desc"
            running_time_str=$(format_seconds $elapsed)
        fi
        
        local time_str=""
        if (( elapsed > 0 )); then
            time_str=" [$(format_seconds $elapsed)]"
        fi
        
        if [[ "$status" -eq 0 ]]; then
            if (( start_time > 0 )); then
                display_lines+=("$(printf '  %-3s  ▶  <b>%s</b> <span foreground=\"#c77dff\">%s</span>' "$prio" "$desc" "$time_str")")
            else
                display_lines+=("$(printf '  %-3s  ☐  %s%s' "$prio" "$desc" "$time_str")")
            fi
        else
            display_lines+=("$(printf '  %-3s  ✔  <span alpha=\"50%%\" strikethrough=\"true\">%s%s</span>' "$prio" "$desc" "$time_str")")
        fi
    done < "$TASK_FILE"
    
    local active_msg
    if [[ -n "$running_desc" ]]; then
        active_msg="⏱  Active: <span foreground=\"#c77dff\"><b>$running_desc</b></span> [<b>$running_time_str</b>]"
    else
        active_msg="⏱  Active: <span foreground=\"#888888\"><i>Idle (No task tracking)</i></span>"
    fi
    
    local task_count=${#display_lines[@]}
    local ADD_LABEL="<span foreground=\"#c77dff\">  ＋  Add task</span>"
    local CLR_LABEL="<span foreground=\"#ff6b6b\">    Clear completed</span>"
    local CLOSE_LABEL="<span foreground=\"#888888\">    Close</span>"
    local SEP="<span foreground=\"#4c0070\">  ─────────────────────────────</span>"
    
    local display_input
    if (( task_count == 0 )); then
        display_input=$(printf '%s\n' \
            "<span foreground=\"#888\" style=\"italic\">    No tasks yet!</span>" \
            "$SEP" \
            "$ADD_LABEL" \
            "$CLOSE_LABEL")
    else
        local task_block
        task_block=$(printf '%s\n' "${display_lines[@]}")
        display_input=$(printf '%s\n%s\n%s\n%s\n%s' \
            "$task_block" \
            "$SEP" \
            "$ADD_LABEL" \
            "$CLR_LABEL" \
            "$CLOSE_LABEL")
    fi
    
    local chosen_idx
    chosen_idx=$(printf '%s\n' "$display_input" | rofi_list "Todo" "$active_msg" -format i)
    
    [[ -z "$chosen_idx" ]] && return 1
    
    if (( task_count == 0 )); then
        case "$chosen_idx" in
            2) add_task; return 0 ;;
            *) return 1 ;;
        esac
    fi
    
    if (( chosen_idx < task_count )); then
        local file_row=$(( chosen_idx + 1 ))
        local raw_line
        raw_line=$(sed -n "${file_row}p" "$TASK_FILE")
        local raw_status=$(echo "$raw_line" | cut -d'|' -f2)
        local raw_desc=$(echo "$raw_line" | cut -d'|' -f3)
        local raw_start_time=$(echo "$raw_line" | cut -d'|' -f5)
        raw_start_time=${raw_start_time:-0}
        
        local timer_action_label
        if (( raw_start_time > 0 )); then
            timer_action_label="<span foreground=\"#ffd166\">  ⏸  Pause tracking</span>"
        else
            timer_action_label="<span foreground=\"#06d6a0\">  ▶  Start tracking</span>"
        fi
        
        local toggle_label
        if [[ "$raw_status" -eq 0 ]]; then
            toggle_label="  ✔  Mark as done"
        else
            toggle_label="    Mark as pending"
        fi
        
        local sub_action
        sub_action=$(printf '%s\n%s\n%s\n%s' \
            "$timer_action_label" \
            "$toggle_label" \
            "<span foreground=\"#ff6b6b\">    Delete</span>" \
            "<span foreground=\"#888\">    Cancel</span>" \
            | rofi_list "Action" "$raw_desc" -format i -lines 4)
            
        case "$sub_action" in
            0)
                if (( raw_start_time > 0 )); then
                    pause_tracking "$file_row"
                else
                    start_tracking "$file_row"
                fi
                ;;
            1) toggle_line "$file_row" ;;
            2) delete_line "$file_row" ;;
        esac
        return 0
    elif (( chosen_idx == task_count + 1 )); then
        add_task; return 0
    elif (( chosen_idx == task_count + 2 )); then
        sed -i '/|1|/d' "$TASK_FILE"; return 0
    else
        return 1
    fi
}

while show_popup; do :; done
