POKEY EXPLORER
==============

Pokey Explorer is a tool to explore all possible register combinations of the Atari 8-bit Pokey chip.

![Default Screen](default-screen.png)

TL;DR All INVERSE video characters are keys you can press. Some with SHIFT to go a little faster. By pressing START, you start a sweep determined by the sweep settings.


All values are hexadecimal. Basic understanding of how Pokey works is assumed :)


SOME SORT OF MANUAL
-------------------

There are four rectangles that contain the current values of all AUDF and AUDC registers. The channel number is on top. AUDF is on the left side. AUDC is on the right side.

Below are two lines with INVERSE video characters that indicate which keys you can press to influence the values. The upper line keys increase the value by one, and the lower line keys decrease the value by one. If you hold shift, you can increase or decrease the specific value by $10 (16).
