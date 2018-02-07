#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo barchart4.tcl
#
#  A long series of values plotted with different colors and patterns.
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

set HeaderText [MakeLine {
    |This is an example of the barchart widget.
    |The barchart has many components; x and y axis, legend, crosshairs,
    |elements, etc.
}]

set graph .graph
CommonHeader .header $HeaderText 6  $DemoDir $graph barchart4.ps
CommonFooter .footer $DemoDir IMG


### Set option defaults for the barchart.

option add *Barchart.title		"A Simple Barchart"
option add *Barchart.relief 		raised
option add *Barchart.borderWidth 	2
option add *Barchart.plotBackground 	white
option add *Barchart.baseline   	57.299

option add *x.Title			"X Axis"
option add *x.Font			*Times-Medium-R*10*
option add *y.Title			"Y Axis"

set visual [winfo screenvisual .]
if { $visual != "staticgray" && $visual != "grayscale" } {
    option add *graph.background palegreen
}


### Create and configure barchart.

barchart $graph
$graph xaxis configure -rotate 90 -stepsize 0

set attributes { 
    red		bdiagonal1
    orange	bdiagonal2
    yellow	fdiagonal1
    green	fdiagonal2
    blue	hline1 
    cyan	hline2
    magenta	vline1 
    violetred	vline2
    purple	crossdiag
    lightblue 	hobbes	
}

set count 0
foreach { color stipple } $attributes {
    $graph pen create pen$count -fg ${color}1 -bg ${color}4 -stipple @$DemoDir/stipples/${stipple}.xbm
    lappend styles [list pen$count $count $count]
    incr count
}


### Define and compute vectors.

proc random {{max 1.0} {min 0.0}} {
    global randomSeed

    set randomSeed [expr (7141*$randomSeed+54773) % 259200]
    set num  [expr $randomSeed/259200.0*($max-$min)+$min]
    return $num
}
set randomSeed 14823


vector create x y w

x seq 0 1000
y expr random(x)*90.0
w expr round(y/10.0)%$count
y expr y+10.0


### Add elements to barchart.

$graph element create data -label {} \
    -x x -y y -weight w -styles $styles


### Map everything, add Rbc_* commands.

grid .header -sticky ew
grid .graph  -sticky nsew
grid .footer -sticky ew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1

wm min . 0 0

Rbc_ZoomStack $graph
Rbc_Crosshairs $graph
Rbc_ActiveLegend $graph
Rbc_ClosestPoint $graph
