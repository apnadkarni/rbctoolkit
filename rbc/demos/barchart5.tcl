#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo barchart5.tcl
#
#  A sine wave plotted as a barchart.
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

set graph .graph
set HeaderText [MakeLine {
    |This is an example of the barchart widget.
    |The barchart has many components; x and y axis, legend, crosshairs,
    |elements, etc.
}]

CommonHeader .header $HeaderText 6 $DemoDir $graph barchart5.ps
CommonFooter .footer $DemoDir


### Set option defaults for the graph.
option add *graph.title "A Simple Barchart"
option add *graph.x.Font { Times 10 }
option add *graph.x.Title "X Axis Label"
option add *graph.y.Title "Y Axis Label"
option add *graph.Element.Relief raised

set visual [winfo screenvisual .] 
if { ($visual != "staticgray") && ($visual != "grayscale") } {
    option add *graph.Element.Background white
    option add *graph.Legend.activeForeground pink
    option add *graph.background palegreen
    option add *graph.plotBackground lightblue
}


### Create and configure barchart.
barchart $graph

$graph configure \
    -relief raised \
    -bd 2
$graph xaxis configure \
    -rotate 90 \
    -stepsize 0 


### Define and compute vectors.

set tcl_precision 15
vector create x
vector create y
x seq -5.0 5.0 0.2 
y expr sin(x)
set barWidth 0.19


### Add barchart element.
$graph element create sin -relief raised -bd 1 -x x -y y  -barwidth $barWidth


### Map everything, add Rbc_* commands.

grid .header -sticky ew
grid $graph  -sticky nsew -padx 4
grid .footer -sticky ew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1

wm min . 0 0

Rbc_ZoomStack $graph
Rbc_Crosshairs $graph
Rbc_ActiveLegend $graph
Rbc_ClosestPoint $graph


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

if 0 {

set names { One Two Three Four Five Six Seven Eight }
if { $visual == "staticgray" || $visual == "grayscale" } {
    set fgcolors { white white white white white white white white }
    set bgcolors { black black black black black black black black }
} else {
    set fgcolors { yellow orange red magenta purple blue cyan green }
    set bgcolors { yellow4 orange4 red4 magenta4 purple4 blue4 cyan4 green4 }
}

set numColors [llength $names]

}
