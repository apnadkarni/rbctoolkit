#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo graph6.tcl
#
#  This demo graph plots 39 different signals as monochrome curves.
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

set text [MakeLine {
    |To zoom in on a region of the graph, simply click once on the left
    |mouse button to pick one corner of the area to be zoomed.  Move the
    |mouse to the other corner and click again.  To zoom back out, click
    |the right mouse button.
}]

CommonHeader .header $text 5 $DemoDir .graph graph6.ps
CommonFooter .footer $DemoDir


### Initialize

set tcl_precision 15 

set logicPlots {}
set leftMargin  0
set rightMargin 0


### Set options for graph.

option add *Graph.Width			10i
option add *Graph.leftMargin		.75i
option add *Graph.Height		6i
option add *Graph.plotBackground	black

option add *Graph.x.hide		yes
option add *Graph.x.title		""
option add *Graph.y.rotate		90
#option add *Graph.y.stepSize		2.0
option add *Graph.title			""
option add *graph.Title			"Example s27" 
option add *graph.x.hide		no
option add *graph.topMargin		0
option add *graph.bottomMargin		0
option add *x.Title			Time
option add *y.Title			Signals
option add *Pixels			1

option add *Reduce			0.5
option add *bufferElements no

option add *Element.color		green4
option add *Element.ScaleSymbols	true
option add *Element.Color		grey70
option add *Element.Symbol		none
option add *Element.LineWidth		1
#option add *Element.Smooth		natural
option add *Element.Smooth		catrom

option add *activeLine.LineWidth	2
option add *activeLine.Color		white
option add *activeLine.Color		green1

#option add *Legend.Hide		yes
option add *Legend.Position		right
option add *Legend.Relief		flat
option add *Legend.activeRelief		sunken
option add *Legend.borderWidth		2
option add *Legend.Font		-*-helvetica-medium-r-*-*-10-*-*-*-*-*-*-*

option add *Grid.hide			no
option add *Grid.dashes			"1 5"

#option add *foreground white
option add *zoomOutline.outline		yellow


### Define vectors x and v1 to v39; then load values into vectors.
source $DemoDir/scripts/graph46.tcl


### Define graph and its elements:

graph .graph -leftmargin $leftMargin -rightmargin $rightMargin

.graph legend configure -anchor nw -position .legend

for { set i 1 } { $i <= 39 } { incr i } {
    .graph element create V$i -x x -y v$i
}


### Map everything, add Rbc_* commands and bindings.

wm min . 0 0 

grid .header -sticky ew
grid .graph  .legend  -sticky nsew
grid .footer -sticky ew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1


Rbc_ZoomStack .graph
Rbc_Crosshairs .graph
Rbc_ClosestPoint .graph
Rbc_PrintKey .graph

.graph legend bind all <ButtonRelease-1> { HighlightTrace %W }
.graph legend bind all <ButtonRelease-3> { 
    %W legend deactivate *
    eval %W element deactivate [%W element activate]
}

proc HighlightTrace { graph } {
    set entry [$graph legend get current]
    set active [$graph legend activate]
    if { [lsearch $active $entry] < 0 } {
	$graph legend activate $entry
	$graph element activate $entry
    } else {
        $graph legend deactivate $entry
	$graph element deactivate $entry
    }
}



### Command to draw and map a separate plot of one or more vectors.
###
### from  - the source of data (Tk window path of the main graph)
### graph - the graph to be drawn or re-drawn (Tk window path)
### args  - the names of the elements of $from to draw

proc LogicPlot { from graph args } {
    if {[llength $args] == 0} {
        destroy $graph
        return
    }
    ### Make gridding easier
    destroy .footer
    ### Create the graph without data
    if { ![winfo exists $graph] } {
	global rightMargin leftMargin
	set yTitle [lindex $args 0]
	graph $graph -title "" -topmargin 1 -bottommargin 1 -height 0.75i \
	    -plotpadx 4 -plotpady 8 -bd 0 \
		-leftmargin $leftMargin -rightmargin $rightMargin
	$graph grid off
	set xMin [$from axis cget x -min]
	set xMax [$from axis cget x -max]
	set yLim [$from axis limits y]
	set yMin [lindex $yLim 0]
	set yMax [lindex $yLim 1]
	$graph axis configure x -title "" -hide yes -min $xMin -max $xMax
	$graph axis configure y -title $yTitle -min $yMin -max $yMax
	$graph legend configure -anchor nw -position ${graph}legend -bg white
	grid $graph ${graph}legend -sticky nsew
	global logicPlots
	lappend logicPlots $graph
    }
    ### Remove any elements that are not in {*}$args
    foreach i [$graph element names] {
	if { [lsearch $args $i] < 0 } {
	    $graph element delete $i
	}
    }
    ### Draw elements {*}$args
    foreach i $args { 
	if { ![$graph element exists $i] } {
	    $graph element create $i
	}
	set pen [$from element cget $i -pen]
	set xData [$from element cget $i -x]
	set yData [$from element cget $i -y]
	$graph element configure $i -x $xData -y $yData -pen $pen
    }
    return
}











### The code below is not executed and is not part of the demo.
### It remains available for experimentation.

### The code below is not used unless you uncomment lines or or edit "if 0" etc.

### Uncomment some of these to produce extra individual plots.
# LogicPlot .graph .g1 V1
# LogicPlot .graph .g2 V5
# LogicPlot .graph .g3 V9 
# LogicPlot .graph .g4 V13
# LogicPlot .graph .g5 V17
# LogicPlot .graph .g6 V22
# LogicPlot .graph .g7 V26

if 0 {

### This experimental code appears to relate to an unfinished feature, the
### options -leftvariable, -rightvariable.
### These (undocumented) options are defined, but appear to do nothing.
### This code can be used (without those options) to alter the margins of
### several plots together.

set changePending "no"
proc EventuallyChangePlots { p1 p2 how } {
    global changePending
    if { $changePending == "no" } {
        after idle ChangePlots
    }
    set changePending "yes"
}

proc ChangePlots { } {
    global changePending
    global logicPlots
    global leftMargin rightMargin
    set from .graph
    set xMin [$from axis cget x -min]
    set xMax [$from axis cget x -max]
    set yLim [$from axis limits y]
    set yMin [lindex $yLim 0]
    set yMax [lindex $yLim 1]
    ### Was foreach g ".graph .g2 .g3"
    foreach g [list .graph {*}$logicPlots] {
	$g configure -leftmargin $leftMargin -rightmargin $rightMargin
	$g axis configure x -min $xMin -max $xMax
	#$g axis configure y -min $yMin -max $yMax
    }
    set changePending "no"
}


LogicPlot .graph .g1 V1
LogicPlot .graph .g2 V5
LogicPlot .graph .g3 V9

#.g1 configure -leftvariable leftMargin -rightvariable rightMargin 
trace variable leftMargin w EventuallyChangePlots
trace variable rightMargin w EventuallyChangePlots

}




### Unused options

if 0 {
option add *LineMarker.color		white
option add *LineMarker.Dashes		5
option add *TextMarker.foreground	white
option add *TextMarker.Background	{}
}
