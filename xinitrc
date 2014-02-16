#!/bin/bash
echo USING .xsession!!!
echo

xrdb -merge .Xresources

#trayer --edge top --align right --SetDockType true --SetPartialStrut true \
#       --expand true --width 10 --transparent true --tint 0x191970 --height 12 &


xsetroot -solid midnightblue

# keybindings and g13
xmodmap .Xmodmap

exec ck-launch-session xmonad
