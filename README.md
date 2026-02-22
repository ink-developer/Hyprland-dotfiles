# Dotfiles — Hyprland Setup

Минималистичный сетап на Arch Linux с Hyprland, динамической темой от обоев и модульной структурой конфигов.

---

## Что входит

- Hyprland (разделённая конфигурация)
- Waybar + кастомные скрипты
- Kitty
- Wofi
- Fastfetch
- btop
- zsh + powerlevel10k
- Скрипт `theme-from-wallpaper` (динамическая палитра через pywal)
- Подборка обоев (опционально)

---

## Установка

```bash
git clone https://github.com/ink-developer/Hyprland-dotfiles/ ~/dotfiles
cd ~/dotfiles
chmod +x install.sh
./install.sh
```

Скрипт:

- делает бэкап текущих конфигов в `~/.dotfiles-backup/`
- копирует конфиги в `~/.config`
- копирует `.zshrc`, `.zprofile`, `.p10k.zsh`
- устанавливает скрипты в `~/.local/bin`
- копирует обои в `~/Pictures/Wallpapers`

После установки рекомендуется:

```
hyprctl reload
```

или перелогиниться.

---

## Динамическая тема

theme-from-wallpaper

Использует:

- swww
- pywal
- jq

Генерирует палитру и применяет её к:

- Hyprland
- Waybar
- Kitty
- Wofi

Можно указать свою папку с обоями:

```
WALLDIR=~/Pictures/Wallpapers theme-from-wallpaper
```

---

## Зависимости

Минимально требуется:

- hyprland
- waybar
- kitty
- wofi
- fastfetch
- btop
- zsh
- swww
- pywal
- jq

---

## Бэкапы

Перед установкой старые конфиги сохраняются в:

```
~/.dotfiles-backup/<дата>/
```
---
