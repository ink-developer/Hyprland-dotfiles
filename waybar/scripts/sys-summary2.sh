#!/usr/bin/env bash
# sys-summary.sh

# ---------- CPU usage (single sample) ----------
cpu_usage() {
    local idle1 total1 idle2 total2 usage
    read -r cpu user nice system idle iowait irq soft irq2 steal guest guest_nice < /proc/stat
    total1=$((user+nice+system+idle+iowait+irq+soft+steal))
    idle1=$idle
    sleep 0.4
    read -r cpu user nice system idle iowait irq soft irq2 steal guest guest_nice < /proc/stat
    total2=$((user+nice+system+idle+iowait+irq+soft+steal))
    idle2=$idle
    local diff_total=$((total2 - total1))
    local diff_idle=$((idle2 - idle1))
    usage=$(( diff_total > 0 ? (100*(diff_total - diff_idle)/diff_total) : 0 ))
    echo "$usage"
}

# ---------- RAM usage ----------
ram_usage() {
    # MemTotal, MemAvailable from /proc/meminfo
    local total avail used
    total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
    avail=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
    used=$((total - avail))
    used_mb=$((used / 1024))
    echo "$used_mb"
}

# ---------- CPU temp ----------
cpu_temp() {
    # ищем hwmon с coretemp
    for hw in /sys/class/hwmon/hwmon*; do
        [ -f "$hw/name" ] || continue
        name=$(cat "$hw/name" 2>/dev/null)
        if [ "$name" = "coretemp" ]; then
            # берём максимум из всех temp*_input
            max=0
            for f in "$hw"/temp*_input; do
                [ -f "$f" ] || continue
                t=$(cat "$f" 2>/dev/null)
                (( t > max )) && max=$t
            done
            [ $max -gt 0 ] && { printf "%d°C" $((max/1000)); return; }
        fi
    done
    echo "--°C"
}
# ---------- Opera process ----------

# ---------- Build line ----------
cpu=$(cpu_usage)
ram=$(ram_usage)
temp=$(cpu_temp)

parts=()
[ -n "$cpu" ] && parts+=(" ${cpu}%")
[ -n "$ram" ] && parts+=(" ${ram}MB")
[ -n "$temp" ] && parts+=(" $temp")

IFS=' · ' ; echo "${parts[*]}"
