#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo barchart3.tcl
#
#  A conventional barchart with colors and stipple patterns; plotted against y.
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


set HeaderText {This is an example of the barchart widget.}
CommonHeader .header $HeaderText 5 $DemoDir .b barchart3.ps
CommonFooter .footer $DemoDir


### Create and configure barchart.
### Note that the plot is inverted (One to Eleven), and the bars are drawn
### from a baseline at 1.2, not zero.

proc FormatLabel { w value } {
    # Determine the element name from the value
    set displaylist [$w element show]
    set index [expr round($value)-1]
    set name [lindex $displaylist $index]
    if { $name == "" } { 
	return $name
    }
    # Return the element label
    set info [$w element configure $name -label]
    return [lindex $info 4]
}

set graph [barchart .b]
$graph configure \
    -invert true \
    -baseline 1.2
$graph xaxis configure \
    -command FormatLabel \
    -descending true
$graph legend configure \
    -hide yes


### Define names, fgcolors, bgcolors, bitmaps - used to configure elements.

set visual [winfo screenvisual .]
set names { One Two Three Four Five Six Seven Eight }
if { $visual == "staticgray" || $visual == "grayscale" } {
    set fgcolors { white white white white white white white white }
    set bgcolors { black black black black black black black black }
} else {
    set fgcolors { red green blue purple orange brown cyan navy }
    set bgcolors { green blue purple orange brown cyan navy red }
}
set bitmaps { 
    bdiagonal1 bdiagonal2 checker2 checker3 cross1 cross2 cross3 crossdiag
}

### Add elements to barchart.
### Use names, fgcolors, bgcolors, bitmaps to configure each element.

set numColors [llength $names]
for { set i 0} { $i < $numColors } { incr i } {
    $graph element create [lindex $names $i] \
	-data { $i+1 $i+1 } \
	-fg [lindex $fgcolors $i] \
	-bg [lindex $bgcolors $i] \
	-stipple @$DemoDir/stipples/[lindex $bitmaps $i].xbm  \
	-relief raised \
	-bd 2 
}

$graph element create Nine \
    -data { 9 -1.0 } \
    -fg red  \
    -relief sunken 

$graph element create Ten \
    -data { 10 2 } \
    -fg seagreen \
    -stipple @$DemoDir/stipples/hobbes.xbm \
    -background palegreen 

$graph element create Eleven \
    -data { 11 3.3 } \
    -fg blue


### Map everything, add Rbc_* commands.

grid .header -sticky ew -padx 15
grid $graph  -sticky news
grid .footer -sticky ew -padx 15

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1


wm min . 0 0

Rbc_ZoomStack $graph
Rbc_Crosshairs $graph
Rbc_ActiveLegend $graph
Rbc_ClosestPoint $graph







### The code below is not executed and is not part of the demo.
### It remains available for experimentation.

if 0 {
### These bitmaps are unused.

set unusedBitmaps { 
    dot1 dot2 dot3 dot4 fdiagonal1 fdiagonal2 hline1 hline2 lbottom ltop
    rbottom rtop vline1 vline2
}

### These markers from the original BLT demo serve no useful purpose.

$graph marker create bitmap \
    -coords { 11 3.3 } -anchor center \
    -bitmap @$DemoDir/bitmaps/sharky.xbm \
    -name bitmap \
    -fill "" 

$graph marker create polygon \
    -coords { 5 0 7 2  10 10  10 2 } \
    -name poly -linewidth 0 -fill ""

$graph marker bind all <B3-Motion> {
    set coords [%W invtransform %x %y]
    catch { %W marker configure [%W marker get current] -coords $coords }
}

$graph marker bind all <Enter> {
    set marker [%W marker get current]
    catch { %W marker configure $marker -fill green -outline black}
}

$graph marker bind all <Leave> {
    set marker [%W marker get current]
    catch { 
	set default [lindex [%W marker configure $marker -fill] 3]
	%W marker configure $marker -fill "$default"
    }
}


}
