#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo graph1.tcl
#
#  Demonstrates multiple features of the graph widget.
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

### To use the demo's "PostScript Options" dialog, source the file
### scripts/ps.tcl. If this is not done, the "Print" button will print to a
### file without offering an options dialog.  See command CommonPrint in
### scripts/common.tcl for choices, including the stock dialog
### Rbc_PostScriptDialog which is not used in these demos.
source $DemoDir/scripts/ps.tcl

set HeaderText {This\
is an example of the graph widget.  It displays two-variable data\
with assorted line attributes and symbols.}

CommonHeader .header $HeaderText 6 $DemoDir .g graph1.ps
CommonFooter .footer $DemoDir

proc MultiplexView { args } { 
    eval .g axis view y $args
    eval .g axis view y2 $args
}

scrollbar .xbar \
    -command { .g axis view x } \
    -orient horizontal -relief flat \
    -highlightthickness 0 -elementborderwidth 2 -bd 0
scrollbar .ybar \
    -command MultiplexView \
    -orient vertical -relief flat \
    -highlightthickness 0 -elementborderwidth 2 -bd 0


### Set option defaults for $graph, related to the tile image.

if { [winfo screenvisual .] != "staticgray" } {
    set image [image create photo -file $DemoDir/images/rain.gif]
    option add *Graph.Tile $image
    option add *Label.Tile $image
    option add *Frame.Tile $image
    option add *TileOffset 0
}


### Create the graph.
set graph [graph .g]


### This file defines the data values (as lists), options for
### graph elements, and the graph elements themselves.
source $DemoDir/scripts/graph1.tcl


### Configuration of .g (apart from its elements)

.g postscript configure \
    -center yes \
    -maxpect yes \
    -landscape no \
    -preview yes

.g axis configure x \
    -scrollcommand { .xbar set } \
    -scrollmax 10 \
    -scrollmin 2 

.g axis configure y \
    -scrollcommand { .ybar set }

.g axis configure y2 \
    -scrollmin 0.0 -scrollmax 1.0 \
    -hide no \
    -title "Y2" 

.g legend configure \
    -activerelief flat \
    -activeborderwidth 1  \
    -position top -anchor ne

.g pen configure "activeLine" \
    -showvalues y

.g configure -plotpady { 1i 0 } 

.g configure -title [pwd]


### Configure the "Fill" images for elements "line2" and "line3" -
### the bees and sharks.

set image2 [image create photo -file $DemoDir/images/blt98.gif]
.g element configure line2 -areapattern @$DemoDir/bitmaps/sharky.xbm \

#	-areaforeground blue -areabackground ""
.g element configure line3 -areatile $image2


### Map everything, add Rbc_* commands and bindings.

grid .header -columnspan 2 -sticky ew
grid .g .ybar -sticky news
grid .xbar -sticky ew
grid .footer -columnspan 2 -sticky ew

grid .ybar -sticky ns

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1

Rbc_ZoomStack $graph
Rbc_Crosshairs $graph
Rbc_ActiveLegend $graph
Rbc_ClosestPoint $graph


.g element bind all <Enter> {
    %W legend activate [%W element get current]
}

.g element bind all <Leave> {
    %W legend deactivate [%W element get current]
}

.g axis bind all <Enter> {
    set axis [%W axis get current]
    %W axis configure $axis -background lightblue2
}

.g axis bind all <Leave> {
    set axis [%W axis get current]
    %W axis configure $axis -background "" 
}


### FIXME rbc - On X11 the legend is not correctly sized for its
### text, possibly because it has an unexpected font.
### On X11 this code doesn't change the font, but it does
### size the legend correctly.
###
### Do this also for win32 (for which it does resize the font)
### because on win32 the legend font is too small.
if {[tk windowingsystem] in {x11 win32}} {
    .g legend configure -font TkDefaultFont
}











### The code below is not executed and is not part of the demo.
### It remains available for experimentation.


### (1) The -leftvariable option appears not to work.
###     See graph6.tcl for further discussion.

if 0 {

.g configure -leftvariable left 

trace variable left w "UpdateTable .g"
proc UpdateTable { graph p1 p2 how } {
    table configure . c0 -width [$graph extents leftmargin]
    table configure . c2 -width [$graph extents rightmargin]
    table configure . r1 -height [$graph extents topmargin]
    table configure . r3 -height [$graph extents bottommargin]
}

}


### (2) Unused options.

if 0 {

set configOptions {
    Axis.TitleFont		{Times 18 bold}
    Legend.ActiveBackground	khaki2
    Legend.ActiveRelief		sunken
    Legend.Background		""
    Title			"A Simple X-Y Graph"
    activeLine.Color		yellow4
    activeLine.Fill		yellow
    background			khaki3
    x.Descending		no
    x.Loose			no
    x.Title			"X Axis Label"
    y.Rotate			90
    y.Title			"Y Axis Label" 
}

}
