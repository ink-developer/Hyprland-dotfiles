#!/usr/bin/env bash

ifaces=($(ls /sys/class/net | grep -v lo | while read i; do
  [[ $(cat /sys/class/net/$i/operstate) == "up" ]] && echo $i
done))

[ ${#ifaces[@]} -eq 0 ] && { echo " --"; exit; }

best_iface=""
max_speed=0
best_down=0
best_up=0

for iface in "${ifaces[@]}"; do
  state="/tmp/waybar-net-${iface}.state"
  rx_prev=0; tx_prev=0; t_prev=0
  [ -f "$state" ] && read rx_prev tx_prev t_prev < "$state"

  now=$(date +%s)
  [ "$t_prev" -eq 0 ] && t_prev=$now  # первый запуск

  rx=$(cat /sys/class/net/${iface}/statistics/rx_bytes 2>/dev/null || echo 0)
  tx=$(cat /sys/class/net/${iface}/statistics/tx_bytes 2>/dev/null || echo 0)

  dt=$(( now - t_prev ))
  [ "$dt" -le 0 ] && dt=1

  # Используем bc для точного деления
  down=$(echo "scale=0; ($rx - $rx_prev)/$dt" | bc)
  up=$(echo "scale=0; ($tx - $tx_prev)/$dt" | bc)
  speed=$((down + up))

  if [ "$speed" -gt "$max_speed" ]; then
    max_speed=$speed
    best_iface=$iface
    best_down=$down
    best_up=$up
  fi

  echo "$rx $tx $now" > "$state"
done

hr() {
  local v=$1
  if [ "$v" -ge 1000000 ]; then
    printf "%.1fM" "$(echo "scale=1; $v/1000000" | bc)"
  elif [ "$v" -ge 1000 ]; then
    printf "%.1fk" "$(echo "scale=1; $v/1000" | bc)"
  else
    printf "%d" "$v"
  fi
}

echo " $(hr $best_down)/s  $(hr $best_up)/s ($best_iface)"
