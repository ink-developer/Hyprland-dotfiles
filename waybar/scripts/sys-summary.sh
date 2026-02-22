#!/usr/bin/env bash
set -euo pipefail

state="/tmp/waybar-cpu.state"

# ---- CPU usage via delta (no sleep) ----
cpu_usage() {
  # /proc/stat: cpu  user nice system idle iowait irq softirq steal guest guest_nice
  read -r _ user nice system idle iowait irq softirq steal _ _ < /proc/stat

  local idle_all=$((idle + iowait))
  local non_idle=$((user + nice + system + irq + softirq + steal))
  local total=$((idle_all + non_idle))

  local prev_total=0 prev_idle=0
  if [[ -f "$state" ]]; then
    read -r prev_total prev_idle < "$state" || true
  fi

  echo "$total $idle_all" > "$state"

  # first run: can't compute delta reliably
  if [[ "$prev_total" -eq 0 ]]; then
    echo "0"
    return
  fi

  local dt=$((total - prev_total))
  local di=$((idle_all - prev_idle))
  if (( dt <= 0 )); then
    echo "0"
    return
  fi

  local usage=$(( (100 * (dt - di)) / dt ))
  echo "$usage"
}

# ---- RAM usage (MB) ----
ram_usage() {
  local total avail used
  total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
  used=$((total - avail))
  echo $((used / 1024))
}

# ---- CPU temp (max coretemp) ----
cpu_temp() {
  for hw in /sys/class/hwmon/hwmon*; do
    [[ -f "$hw/name" ]] || continue
    [[ "$(cat "$hw/name" 2>/dev/null)" == "coretemp" ]] || continue
    local max=0
    for f in "$hw"/temp*_input; do
      [[ -f "$f" ]] || continue
      local t
      t=$(cat "$f" 2>/dev/null || echo 0)
      (( t > max )) && max=$t
    done
    if (( max > 0 )); then
      printf "%d°C" $((max/1000))
      return
    fi
  done
  echo "--°C"
}

cpu=$(cpu_usage)
ram=$(ram_usage)
temp=$(cpu_temp)

# Build line (same style as you had)
printf " %s%% ·  %sMB ·  %s\n" "$cpu" "$ram" "$temp"
