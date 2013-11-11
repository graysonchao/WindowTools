WindowTools
===========

Resize and move windows using a hotkey - you can click anywhere on the window, instead of
being forced to perform the onerous task of visually locating the top bar and sides of a
window.

How to use
----------

Step 1. Download and build (I build on a mid-2009 MBP in Xcode 5, YMMV but I can't see why it would)

Step 2. Command left drag to move, command right drag to resize. Double tap command to toggle normal 
command key functionality (enable/disable WindowTools).

Step 3. Report bugs to me at github.com/graysonc/WindowTools

Enormous thanks to:

* Jigish Patel for wrapping the Accessibility API for Cocoa in Slate:  
  https://github.com/jigish/slate/
  (specifically, the AccessibilityWrapper class)
* Nolan Waite for demonstrating EventTaps:  
  https://github.com/nolanw/Ejectulate/
  (specifically, in the EJEjectKeyWatcher class)
* Oscar Del Ben for writing handy multi-monitor support functions:  
  https://github.com/oscardelben/NSScreen-PointConversion
