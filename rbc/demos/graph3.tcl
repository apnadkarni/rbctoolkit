#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo graph3.tcl
#
#  Sine and cosine functions as curves with data points, and a background image.
# ------------------------------------------------------------------------------
# restart using wish \
exec wish "$0" "$@"

package require rbc
namespace import rbc::*


### The script can be run from any location.
### It loads the files it needs from the demo directory.
set DemoDir [file normalize [file dirname [info script]]]


### Load common commands and create non-rbc GUI elements.
source $DemoDir/scripts/common.tcl

set HeaderText [MakeLine {
    |This is an example of a bitmap marker.  Try zooming in on
    |a region by clicking the left button, moving the pointer,
    |and clicking again.  Notice that the bitmap scales too.
    |To restore the last view, click on the right button.
}]

CommonHeader .header $HeaderText 4 $DemoDir .g
CommonFooter .footer $DemoDir IMG


### Set option defaults for $graph.
set visual [winfo screenvisual .]
if { $visual != "staticgray" && $visual != "grayscale" } {
    option add *activeLine.Color	red4
    option add *activeLine.Fill		red2
}


image create photo bgTexture \
    -file $DemoDir/images/chalk.gif

option add *Tile		bgTexture
option add *HighlightThickness		0


### Define graph:

set graph [graph .g]

### The construction of the graph .g is in this file:
# (1) Define and compute the vectors.
# (2) Add the graph elements.
source $DemoDir/scripts/graph3.tcl


### Now add a bitmap marker (background image) and configure
### the postscript component.

$graph marker create bitmap \
    -name bg \
    -coords "-360 -1 360 1" \
    -bitmap @$DemoDir/bitmaps/greenback.xbm \
    -bg darkseagreen1 \
    -fg darkseagreen3 \
    -under yes \
    -rotate 45

$graph postscript configure \
    -maxpect yes \
    -landscape yes


### Map everything, add Rbc_* commands.

grid .header -sticky ew -padx 4 -pady 4
grid $graph -sticky nsew
grid .footer -sticky ew -padx 4 -pady 4

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1

Rbc_ZoomStack $graph
Rbc_Crosshairs $graph
Rbc_ActiveLegend $graph
Rbc_ClosestPoint $graph
#Blt_PrintKey $graph

### FIXME rbc - On X11 the legend is not correctly sized for its
### text, possibly because it has an unexpected font.
### On X11 this code doesn't change the font, but it does
### size the legend correctly.
###
### Do this also for win32 (for which it does resize the font)
### because on win32 the legend font is too small.
if {[tk windowingsystem] in {x11 win32}} {
    $graph legend configure -font TkDefaultFont
}




### The code below is not executed and is not part of the demo.
### It remains available for experimentation.


### (1) Experiment with a PostScript options dialog.
if 0 {
source $DemoDir/scripts/ps.tcl

### This dialog exists (from scripts/ps.tcl)
after 2000 {
    ::rbc::ps::psDialog $graph
}

}


### (2) Unported print operations.

if 0 {
bind $graph <Shift-ButtonPress-1> { 
    ### The MakePsLayout command is missing, even in original BLT.
    MakePsLayout $graph
}
}

if 0 {
### The blt::printer command is not ported to rbc.
set printer [printer open [lindex [printer names] 0]]
after 2000 {
	$graph print2 $printer
}
}


### (3) Unused options (there are more in scripts/graph3.tcl)
if 0 {

if { $visual != "staticgray" && $visual != "grayscale" } {
    option add *Button.Background		red
    option add *TextMarker.Foreground	black
    option add *TextMarker.Background	yellow
    option add *LineMarker.Foreground	black
    option add *LineMarker.Background	yellow
    option add *PolyMarker.Fill		yellow2
    option add *PolyMarker.Outline	""
    option add *PolyMarker.Stipple	fdiagonal1
    option add *Element.Color		purple
}

option add *Button.Tile		""
option add *Text.font			-*-times*-bold-r-*-*-18-*-*
option add *header.font			-*-times*-medium-r-*-*-18-*-*
option add *footer.font			-*-times*-medium-r-*-*-18-*-*

}
