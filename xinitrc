#!/bin/bash
echo USING .xsession!!!
echo

xrandr --setprovideroutputsource 1 0
xrandr --fb 4410x2074 --dpi 96 --output DVI-1 --mode 1680x1050 --pos 1688x1024 --rotate normal \
	--output DisplayPort-0 --mode 1680x1050 --pos 0x1024 --rotate normal \
	--output DisplayPort-1-1 --off \
	--output DVI-1-2 --mode 1280x1024 --pos 1680x0 --rotate normal \
	--output HDMI-1-1 --off \
	--output HDMI-0 --mode 1680x1050 --pos 3368x394 --rotate left \
	--output DVI-1-3 --off \
	--output DVI-0 --mode 1280x1024 --pos 400x0 --rotate normal
xrandr --dpi 96

xrdb -merge .Xresources

#trayer --edge top --align right --SetDockType true --SetPartialStrut true \
#       --expand true --width 10 --transparent true --tint 0x191970 --height 12 &


xsetroot -solid midnightblue

# keybindings and g13
xmodmap .Xmodmap

xhost +
exec ck-launch-session xmonad
