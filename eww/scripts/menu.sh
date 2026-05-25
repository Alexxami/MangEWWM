#!/bin/bash

names=(
  "Brave Browser"
  "Btop"
  "Discord"
  "Minecraft Launcher"
  "Neovim"
  "OBS Studio"
  "Spotify"
  "Steam"
)

execs=(
  "brave"
  "btop"
  "/usr/bin/discord"
  "minecraft-launcher"
  "nvim"
  "obs"
  "spotify-launcher %U"
  "steam"
)

icons=(
  "/usr/share/icons/hicolor/128x128/apps/brave-desktop.png"
  "/usr/share/icons/hicolor/scalable/apps/btop.svg"
  "/usr/share/icons/Dracula/scalable/apps/discord.svg"
  "/usr/share/icons/Dracula/scalable/apps/minecraft-launcher.svg"
  "/usr/share/icons/hicolor/128x128/apps/nvim.png"
  "/usr/share/icons/hicolor/256x256/apps/com.obsproject.Studio.png"
  "/usr/share/icons/hicolor/512x512/apps/spotify-launcher.png"
  "/usr/share/icons/hicolor/256x256/apps/steam.png"
)

terminal=(
  false
  true
  false
  false
  true
  false
  false
  false
)

json="["

for i in "${!names[@]}"; do
  [[ $i -ne 0 ]] && json+=","
  json+="{\"name\":\"${names[$i]}\",\"exec\":\"${execs[$i]}\",\"icon\":\"${icons[$i]}\",\"terminal\":\"${terminal[$i]}\"}"
done

json+="]"
echo "$json"
