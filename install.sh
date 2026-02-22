#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"
BACKUP_DIR="${HOME}/.dotfiles-backup/${TS}"
LOGFILE="${BACKUP_DIR}/install.log"
WALL_DST="${HOME}/Pictures/Wallpapers"

mkdir -p "$BACKUP_DIR"
touch "$LOGFILE"

# ---------- pretty logs ----------
if command -v tput >/dev/null 2>&1; then
  BOLD="$(tput bold)"; DIM="$(tput dim)"; RST="$(tput sgr0)"
  RED="$(tput setaf 1)"; GRN="$(tput setaf 2)"; YLW="$(tput setaf 3)"; BLU="$(tput setaf 4)"; CYA="$(tput setaf 6)"
else
  BOLD=""; DIM=""; RST=""
  RED=""; GRN=""; YLW=""; BLU=""; CYA=""
fi

ts() { date +"%H:%M:%S"; }

info() { printf "%s %sℹ%s %s\n" "$(ts)" "$BLU" "$RST" "$*" | tee -a "$LOGFILE"; }
ok()   { printf "%s %s✔%s %s\n" "$(ts)" "$GRN" "$RST" "$*" | tee -a "$LOGFILE"; }
warn() { printf "%s %s⚠%s %s\n" "$(ts)" "$YLW" "$RST" "$*" | tee -a "$LOGFILE"; }
err()  { printf "%s %s✖%s %s\n" "$(ts)" "$RED" "$RST" "$*" | tee -a "$LOGFILE"; }

die() { err "$*"; exit 1; }

step_start() { _STEP="$1"; _T0="$(date +%s%3N 2>/dev/null || date +%s)"; info "${BOLD}${_STEP}${RST}"; }
step_end() {
  local t1
  t1="$(date +%s%3N 2>/dev/null || date +%s)"
  if [[ "$_T0" =~ ^[0-9]+$ && "$t1" =~ ^[0-9]+$ ]]; then
    ok "${_STEP} ${DIM}(${t1}-${_T0})${RST}"
  else
    ok "${_STEP}"
  fi
}

trap 'err "Failed at line ${LINENO}: ${BASH_COMMAND} (exit $?)"; err "Log: $LOGFILE"' ERR

# ---------- backup ----------
backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local dest="${BACKUP_DIR}${target}"
    mkdir -p "$(dirname "$dest")"
    mv -f "$target" "$dest"
    ok "Backup: $target -> $dest"
  fi
}

# ---------- copy helpers ----------
copy_dir() {
  local src="$1"
  local dst="$2"

  if [[ ! -d "$src" ]]; then
    warn "Missing dir in repo, skip: ${DIM}${src}${RST}"
    return 0
  fi

  backup_path "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  ok "Copied dir: ${dst}  <=  ${DIM}${src}${RST}"
}

copy_file() {
  local src="$1"
  local dst="$2"

  if [[ ! -f "$src" ]]; then
    warn "Missing file in repo, skip: ${DIM}${src}${RST}"
    return 0
  fi

  backup_path "$dst"
  mkdir -p "$(dirname "$dst")"
  cp -a "$src" "$dst"
  ok "Copied file: ${dst} <= ${DIM}${src}${RST}"
}

install_bin_dir() {
  local src_dir="$1"
  local dst_dir="$2"

  if [[ ! -d "$src_dir" ]]; then
    warn "Missing bin dir in repo, skip: ${DIM}${src_dir}${RST}"
    return 0
  fi

  mkdir -p "$dst_dir"

  while IFS= read -r -d '' f; do
    local base
    base="$(basename "$f")"
    local dst="${dst_dir}/${base}"

    backup_path "$dst"
    cp -a "$f" "$dst"
    chmod +x "$dst" || true
    ok "Installed bin: ${dst} <= ${DIM}${f}${RST}"
  done < <(find "$src_dir" -maxdepth 1 -type f -print0)
}

# ---------- header ----------
printf "%s\n" "${BOLD}Dotfiles installer (copy mode)${RST}" | tee -a "$LOGFILE"
info "Repo:   ${DIM}${REPO_DIR}${RST}"
info "Backup: ${DIM}${BACKUP_DIR}${RST}"
info "Log:    ${DIM}${LOGFILE}${RST}"
echo | tee -a "$LOGFILE"

# ---------- install configs ----------
step_start "Install ~/.config (copy)"
copy_dir "$REPO_DIR/hypr"      "$HOME/.config/hypr"
copy_dir "$REPO_DIR/waybar"    "$HOME/.config/waybar"
copy_dir "$REPO_DIR/wofi"      "$HOME/.config/wofi"
copy_dir "$REPO_DIR/kitty"     "$HOME/.config/kitty"
copy_dir "$REPO_DIR/btop"      "$HOME/.config/btop"
copy_dir "$REPO_DIR/gtk-3.0"   "$HOME/.config/gtk-3.0"
copy_dir "$REPO_DIR/gtk-4.0"   "$HOME/.config/gtk-4.0"
copy_dir "$REPO_DIR/fastfetch" "$HOME/.config/fastfetch"
step_end

step_start "Install shell files (zsh)"
copy_file "$REPO_DIR/.zshrc"     "$HOME/.zshrc"
copy_file "$REPO_DIR/.zprofile"  "$HOME/.zprofile"
copy_file "$REPO_DIR/.p10k.zsh"  "$HOME/.p10k.zsh"
step_end

step_start "Install ~/.local/bin"
install_bin_dir "$REPO_DIR/bin" "$HOME/.local/bin"
step_end

# ---------- wallpapers (copy, no symlinks) ----------
step_start "Install wallpapers (copy)"
if [[ -d "$REPO_DIR/wallpapers" ]]; then
  mkdir -p "$WALL_DST"
  # copy/update; do not delete user wallpapers
  cp -an "$REPO_DIR/wallpapers/." "$WALL_DST/" || true
  ok "Wallpapers copied to: ${DIM}${WALL_DST}${RST}"
else
  warn "No wallpapers directory in repo (skip)"
fi
step_end

echo | tee -a "$LOGFILE"
ok "Install complete."

# ---------- optional: apply theme now ----------
if command -v theme-from-wallpaper >/dev/null 2>&1; then
  echo | tee -a "$LOGFILE" 
  read -r -p "Run theme-from-wallpaper now? [y/N] " ans || true
  if [[ "${ans,,}" == "y" ]]; then
    step_start "Apply theme-from-wallpaper"
    # point it to the installed wallpapers folder
    WALLDIR="$WALL_DST" theme-from-wallpaper || warn "theme-from-wallpaper failed (see ~/.cache/theme-from-wallpaper.log)"
    step_end
  fi
else
  warn "theme-from-wallpaper not found in PATH (skip theme apply)."
fi

echo | tee -a "$LOGFILE"
ok "Done."
info "If needed: reload hyprland (hyprctl reload) and restart waybar."
