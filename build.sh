#! /bin/sh

mads -x -d:SYSTEM=0 -d:BATCH=0 -o:pokeyexp-pal.xex pokeyexp.s
mads -x -d:SYSTEM=1 -d:BATCH=0 -o:pokeyexp-ntsc.xex pokeyexp.s

mads -x -d:SYSTEM=0 -d:BATCH=1 -o:pokeyexp-batch-pal.xex pokeyexp.s
mads -x -d:SYSTEM=1 -d:BATCH=1 -o:pokeyexp-batch-ntsc.xex pokeyexp.s
