# DUNST  
  
A lightweight notification daemon  
  
See https://wiki.archlinux.org/title/Dunst  
See https://github.com/dunst-project/dunst  
See https://github.com/dunst-project/dunst/wiki  
  
Add command to autostart:  
hyprland `~/.config/hypr/hyprland.conf`: `exec-once dunst`  
  
Add config to ~/.config/dunst/dunstrc  
  
Manually emitting notifications for testing:  
   
```
notify-send "Message"
notify-send "Title" "Message"
notify-send -u low "Title" "Message"
notify-send -u normal "Title" "Message"
notify-send -u critical "Title" "Message"
```  
   
```
dunstify "Message"
dunstify "Title" "Message"
dunstify -u low "Title" "Message"
dunstify -u normal "Title" "Message"
dunstify -u critical "Title" "Message"
```  
