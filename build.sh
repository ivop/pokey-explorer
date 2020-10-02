#! /bin/sh

mads -d:SYSTEM=0 -o:pokeyexp-pal.xex pokeyexp.s
mads -d:SYSTEM=1 -o:pokeyexp-ntsc.xex pokeyexp.s
