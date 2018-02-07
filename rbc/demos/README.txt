BLT DEMOS REVISED FOR RBC

Many thanks to George Howlett for the BLT toolkit, and to the RBC developers for
adapting parts of BLT to run under Tcl/Tk 8.5 and 8.6.

These demos for RBC are based on the BLT demos for the parts of BLT that are
included in RBC.


FEATURES

* Demos have been modified to run from any working directory.
* The demos include the debugged command ::rbc::ps::psDialog which provides a
  useful dialog for the "print to PostScript" facility of BLT/RBC widgets.
* BLT commands removed if not available in RBC:
** BLT bitmaps converted to .xbm files for use by Tk
** BLT table command replaced with Tk grid
** BLT htext command replaced with Tk text
* Demo launcher "demos.tcl" added, showing a thumbnail image of each demo

FILES IN MAIN DIRECTORY

(a) COPIED WITH MODIFICATIONS FROM BLT DEMOS
barchart1.tcl
barchart2.tcl
barchart3.tcl
barchart4.tcl
barchart5.tcl
busy1.tcl
busy2.tcl
graph1.tcl
graph2.tcl
graph3.tcl
graph4.tcl
graph5.tcl
graph6.tcl
graph7.tcl
stripchart1.tcl
winop1.tcl
winop2.tcl

(b) NEW FILES
demos.tcl     - launcher showing thumbnail of each demo
README.txt    - this file


FILES IN DIRECTORY scripts

(a) COPIED WITH MODIFICATIONS FROM BLT DEMOS
scripts/graph1.tcl
scripts/graph2.tcl
scripts/graph3.tcl
scripts/ps.tcl

(b) NEW FILES
scripts/common.tcl  - common code for all RBC demos (header, footer, printing,
                      snapshot)
scripts/graph46.tcl - common code for demos graph4.tcl, graph6.tcl (data sets)


FILES IN NEW DIRECTORY scripts/other - MOVED WITH MODIFICATIONS

scripts/other/graph5.tcl    - moved from scripts/graph5.tcl, it is a different
                              form of graph5.tcl
scripts/other/graph8.tcl    - moved from scripts/graph8.tcl, it is a different
                              form of scripts/graph1.tcl
scripts/other/barchart2.tcl - moved from scripts/barchart2.tcl, it is a
                              different form of barchart2.tcl

                              
FILES IN NEW DIRECTORY extras - MOVED WITH MODIFICATIONS

extras/clone.tcl     - moved from scripts/clone.tcl - useful script to clone a
                       graph.  Could be converted to a command.
extras/globe.tcl     - a small animation of a rotating globe (does not need RBC)
extras/page.tcl      - moved from scripts/page.tcl - tile postscript files in a
		       grid (does not need RBC)
extras/rgb.txt       - new file - X11 named colors, for use by
                       extras/xcolors.tcl on non-X11 systems
extras/send.tcl      - Tk "send" command for Windows (does not need RBC)
extras/xcolors.tcl   - moved from scripts/xcolors.tcl is a demo of X11 named
                       colors (does not need RBC or X11)


FILES IN DIRECTORY bitmaps and its subdirectories

(a) COPIED FROM BLT DEMOS
all files

(b) NEW FILES
bitmaps/BLT.xbm    - abstracted from bltBitmap.c
bitmaps/bigBLT.xbm - abstracted from bltBitmap.c


FILES IN DIRECTORY images

COPIED FROM BLT DEMOS
all files


FILES IN NEW DIRECTORY stipples

stipples/*.xbm - bitmap images abstracted from scripts/stipple.tcl,
                 scripts/patterns.tcl and scripts/globe.tcl, since RBC does not
                 have BLT's bitmap command.


FILES IN NEW DIRECTORY thumbnails

thumbnails/*.ppm - thumbnail images used by demos.tcl.  These were created by
                   BLT widgets' snapshot facility (with postprocessing for the
                   thumbnails of the winop demos).

FILES NOT COPIED FROM BLT DEMOS

bgexec1.tcl
bgexec2.tcl
bgexec3.tcl
bgexec4.tcl
bitmap.tcl
dnd1.tcl
dnd2.tcl
dragdrop1.tcl
dragdrop2.tcl
eps.tcl
hierbox1.tcl
hierbox2.tcl
hierbox3.tcl
hierbox4.tcl
hiertable1.tcl
hiertable2.tcl
htext1.tcl
htext.txt
spline.tcl
tabnotebook1.tcl
tabnotebook2.tcl
tabnotebook3.tcl
tabset1.tcl
tabset2.tcl
tabset3.tcl
tabset4.tcl
treeview1.tcl
scripts/bgtest.tcl
scripts/demo.tcl

