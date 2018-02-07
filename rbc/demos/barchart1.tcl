#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo barchart1.tcl
#
#  A conventional barchart with stipple patterns and error bars.
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
    |The barchart has several components:
    |coordinate axes, data elements, legend, crosshairs, grid,
    |postscript, and markers.
    |
    |They each control various aspects of the barchart.  For example,
    |the postscript component lets you generate PostScript output.
}]

CommonHeader .header $HeaderText 9 $DemoDir .bc barchart1.ps
CommonFooter .footer $DemoDir


### Set option defaults for the barchart.

image create photo bgTexture -file $DemoDir/images/rain.gif

option add *tile			bgTexture

option add *Barchart.title		"A Simple Barchart"
option add *Barchart.font		{ Helvetica 12 bold }

option add *Axis.tickFont		{ Courier 10 }
option add *Axis.titleFont		{ Helvetica 12 bold }

option add *x.Rotate			90
option add *x.Command			FormatLabel
option add *x.Title			"X Axis Label"

option add *y.Title			"Y Axis Label"

option add *Element.Background		white
option add *Element.Relief		solid
option add *Element.BorderWidth		1

option add *Grid.dashes			{ 2 4 }
option add *Grid.hide			no
option add *Grid.mapX			""

option add *Legend.hide			yes

proc FormatLabel { w value } {
    # Determine the element name from value (an integer index).

    set names [$w element show]
    set index [expr round($value)]
    if { $index != $value } {
	return $value 
    }
    global elemLabels
    if { [info exists elemLabels($index)] } {
	# In the present example, this text label is returned.
	return $elemLabels($index)
    }
    return $value
}


### Create the barchart.

barchart .bc


### Add a bar to .bc for each bitmap in the list.

proc random {{max 1.0} {min 0.0}} {
    global randomSeed

    set randomSeed [expr (7141*$randomSeed+54773) % 259200]
    set num  [expr $randomSeed/259200.0*($max-$min)+$min]
    return $num
}
set randomSeed 148230

set bitmaps { 
    bdiagonal1 bdiagonal2 checker2 checker3 cross1 cross2 cross3 crossdiag
    dot1 dot2 dot3 dot4 fdiagonal1 fdiagonal2 hline1 hline2 lbottom ltop
    rbottom rtop vline1 vline2
}
set count 1
foreach stipple $bitmaps {
    set label [file tail $stipple]
    set label [file root $label] 
    set y [random -2 10]
    set yhigh [expr $y + 0.5]
    set ylow [expr $y - 0.5]
    .bc element create $label -y $y -x $count \
	-fg brown -bg orange  -stipple @$DemoDir/stipples/${stipple}.xbm -yhigh $yhigh -ylow $ylow 
    set elemLabels($count) $label
    incr count
}


### Map everything, add Rbc_* commands and bindings.

grid .header -sticky ew
grid .bc     -sticky nsew
grid .footer -sticky ew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1


Rbc_ZoomStack .bc
Rbc_Crosshairs .bc
Rbc_ActiveLegend .bc
Rbc_ClosestPoint .bc

.bc axis bind x <Enter> {
    set axis [%W axis get current]
    %W axis configure $axis -color blue3 -titlecolor blue3
}

.bc axis bind x <Leave> {
    set axis [%W axis get current]
    %W axis configure $axis -color black -titlecolor black
}

### FIXME rbc - On X11 the x-axis labels are not correctly sized for their
### text, possibly because they have an unexpected font.
### This code doesn't change the font, but it does
### size (MOST OF) the labels correctly.
### This is the same "Font Size" bug as for the Legend in graph1.tcl
### and other demos.
if {[tk windowingsystem] eq "x11"} {
    .bc xaxis configure -tickfont TkDefaultFont
}

### The code below is not executed and is not part of the demo.
### It remains available for experimentation.

### Unused printing code - rbc does not have the BLT printer command.

if 0 {
set printer [printer open [lindex [printer names] 0]]
printer getattr $printer attrs
set attrs(Orientation) Portrait
printer setattr $printer attrs
after 2000 {
	.bc print2 $printer
	printer close $printer
}
}
