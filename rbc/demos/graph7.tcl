#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo graph7.tcl
#
#  This demo graph displays a scatter plot with a large number of points.
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
    |At this scale the 250,000 plotted points overlap.
    |
    |To zoom in on a region of the graph, simply click once on the left
    |mouse button to pick one corner of the area to be zoomed.  Move the
    |mouse to the other corner and click again.  To zoom back out, click
    |the right mouse button.
}]

CommonHeader .header $HeaderText 7 $DemoDir .graph
CommonFooter .footer $DemoDir


### Colors and other options for the graph:

image create photo bgTexture -file $DemoDir/images/buckskin.gif

option add *Graph.Tile			bgTexture
option add *HighlightThickness		0
option add *Element.ScaleSymbols	no
option add *activeLine.Color		yellow4
option add *activeLine.Fill		yellow
option add *activeLine.LineWidth	0


### Define graph and its elements:

set graph .graph

set length 250000
graph $graph -title "Scatter Plot\n$length points" 
$graph xaxis configure \
	-loose no \
	-title "X Axis Label"
$graph yaxis configure \
	-title "Y Axis Label" 
$graph legend configure \
	-activerelief sunken \
	-background ""

$graph element create line3 -symbol square -color green4 -fill green2 \
    -linewidth 0 -outlinewidth 1 -pixels 4


### Map everything

grid .header -sticky ew
grid .graph  -sticky nsew
grid .footer -sticky ew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1

wm min . 0 0


### FIXME rbc - On X11 the legend is not correctly sized for its
### text, possibly because it has an unexpected font.
### On X11 this code doesn't change the font, but it does
### size the legend correctly.
###
### Do this also for win32 (for which it does resize the font)
### because on win32 the legend font is too small.
if {[tk windowingsystem] in {x11 win32}} {
    .graph legend configure -font TkDefaultFont
}

### Warn of delay calculating and drawing points:
label .lab7 -text "Calculating ..." -bg yellow -fg red
place .lab7 -relx 0.5 -rely 0.0 -anchor n
update


### Now add the data points.
vector create x($length) y($length)
x expr random(x)
y expr random(y)
x sort y
$graph element configure line3 -x x -y y

### Disable the GUI while the points are being drawn.

### FIXME rbc - rbc::busy segfaults ...
#::rbc::busy hold $graph
#update
#::rbc::busy release $graph

### ... so instead use a grab.
### Catch so the grab is always released.
grab .lab7
catch update
grab release .lab7
destroy .lab7


### Add Rbc_* commands

Rbc_ZoomStack $graph
Rbc_Crosshairs $graph
Rbc_ActiveLegend $graph
Rbc_ClosestPoint $graph
