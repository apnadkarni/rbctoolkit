#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo graph4.tcl
#
#  This demo graph plots 39 different signals as colored curves with points.
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
    |To zoom in on a region of the graph, simply click once on the left
    |mouse button to pick one corner of the area to be zoomed.  Move the
    |mouse to the other corner and click again.
}]

CommonHeader .header $HeaderText 6 $DemoDir .graph {} graph4.ppm
CommonFooter .footer $DemoDir IMG



set tcl_precision 15 

image create photo bgTexture -file $DemoDir/images/chalk.gif

### These options apply to the graph.
option add *Graph.Legend.activeBackground white
option add *Graph.height		5i
option add *Graph.plotBackground	black
option add *Graph.width			7i
option add *Graph.tile			bgTexture
option add *Graph.halo			0

option add *Graph.title			"s27.out"
option add *Graph.font			-*-helvetica-bold-r-*-*-18-*

option add *Axis.tickFont		-*-courier-medium-r-*-*-12-*
option add *Axis.titleFont		-*-helvetica-bold-r-*-*-14-*
option add *Axis.titleColor		black
option add *x.title			"Time"
option add *y.title			"Signals"

option add *Crosshairs.Color		white

option add *activeLine.Fill		navyblue
option add *activeLine.LineWidth	2
option add *Element.ScaleSymbols	yes
option add *Element.Smooth		natural

option add *Symbol			square
option add *Element.LineWidth		1
option add *Pen.LineWidth		1
option add *Pixels			1

option add *Grid.color			grey50
option add *Grid.dashes			"2 4"
option add *Grid.hide			no

option add *Legend.ActiveRelief		sunken
option add *Legend.Position		right
option add *Legend.Relief		flat
option add *Legend.font			-*-lucida-medium-r-*-*-12-*-*-*-*-*-*-*
option add *Legend.Pad			0
option add *Legend.hide			no

option add *zoomOutline.outline		yellow


### These options do not apply to the graph, but might be
### useful if it is modified.

option add *Graph.relief		raised
#option add *Graph.borderWidth		2
option add *LineMarker.Dashes		5
option add *LineMarker.Foreground	white
option add *TextMarker.Background	{}
option add *TextMarker.Foreground	white


### Define vectors x and v1 to v39; then load values into vectors.
source $DemoDir/scripts/graph46.tcl

### Define graph and its elements:

set attributes {
    V1	v1	red	red  
    V2  v2	green	red  
    V3	v3	blue	red  
    V4  v4	yellow  red  
    V5  v5	magenta red  
    V6  v6	cyan	red  
    V7	v7	white	red  
    V8  v8	red	green  
    V9  v9	green	green  
    V10 v10	blue	green  
    V11 v11	yellow	green  
    V12 v12	magenta	green  
    V13	v13	cyan	green  
    V14	v14	red	red  
    V15 v15	green	red  
    V16	v16	blue	red  
    V17 v17	yellow  red  
    V18 v18	magenta red  
    V19 v19	cyan	red  
    V20	v20	white	red  
    V21 v21	red	green  
    V22 v22	green	green  
    V23 v23	blue	green  
    V24 v24	yellow	green  
    V25 v25	magenta	green  
    V26	v26	cyan	green  
    V27	v27	red	red  
    V28 v28	green	red  
    V29	v29	blue	red  
    V30 v30	yellow  red  
    V31 v31	magenta red  
    V32 v32	cyan	red  
    V33	v33	white	red  
    V34 v34	red	green  
    V35 v35	green	green  
    V36 v36	blue	green  
    V37 v37	yellow	green  
    V38 v38	magenta	green  
    V39	v39	cyan	green  
}

graph .graph

foreach {label yData outline color} $attributes {
    .graph element create $label -x x -y $yData -outline $outline -color $color
}


### Map everything, add Rbc_* commands and bindings.

grid .header -sticky ew
grid .graph  -sticky nsew
grid .footer -sticky ew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1


Rbc_ZoomStack    .graph
Rbc_Crosshairs   .graph
Rbc_ActiveLegend .graph
Rbc_ClosestPoint .graph
Rbc_PrintKey     .graph

.graph element bind all <Enter> {
    %W legend activate [%W element get current]
}

.graph element bind all <Leave> {
    %W legend deactivate [%W element get current]
}








### The code below is not executed and is not part of the demo.
### It remains available for experimentation.


### (1) Unused Options

if 0 {

option add *default			normal
option add *Button.tile			bgTexture

option add *Htext.font			-*-times*-bold-r-*-*-18-*-*
option add *Text.font			-*-times*-bold-r-*-*-18-*-*
option add *header.font			-*-times*-medium-r-*-*-18-*-*
option add *footer.font			-*-times*-medium-r-*-*-18-*-*

}
