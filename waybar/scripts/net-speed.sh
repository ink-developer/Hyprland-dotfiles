#!/usr/bin/env bash
set -euo pipefail

iface="$(ip -o -4 route show to default 2>/dev/null | awk '{print $5; exit}')"

if [[ -z "${iface:-}" ]] || [[ ! -e "/sys/class/net/$iface" ]]; then
  echo " --"
  exit 0
fi

if [[ "$(cat "/sys/class/net/$iface/operstate" 2>/dev/null || echo down)" != "up" ]]; then
  echo " -- ($iface)"
  exit 0
fi

state="/tmp/waybar-net-${iface}.state"

now=$(date +%s)
rx=$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null || echo 0)
tx=$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null || echo 0)

rx_prev=0; tx_prev=0; t_prev=0
if [[ -f "$state" ]]; then
  read -r rx_prev tx_prev t_prev < "$state" || true
fi

echo "$rx $tx $now" > "$state"

if [[ "${t_prev:-0}" -eq 0 ]]; then
  echo " --/s  --/s ($iface)"
  exit 0
fi

dt=$(( now - t_prev ))
(( dt <= 0 )) && dt=1

down=$(( (rx - rx_prev) / dt ))
up=$(( (tx - tx_prev) / dt ))
(( down < 0 )) && down=0
(( up < 0 )) && up=0

hr() {
  local v=$1
  if (( v >= 1000000 )); then
    printf "%d.%dM" $((v/1000000)) $(((v%1000000)/100000))
  elif (( v >= 1000 )); then
    printf "%d.%dk" $((v/1000)) $(((v%1000)/100))
  else
    printf "%d" "$v"
  fi
}

echo " $(hr "$down")/s  $(hr "$up")/s ($iface)"
