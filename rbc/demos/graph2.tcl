#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo graph2.tcl
#
#  Sine and cosine functions with different types of symbol at data points.
# ------------------------------------------------------------------------------
# restart using wish \
exec wish "$0" "$@"

package require rbc
namespace import rbc::*


### The script can be run from any location.
### It loads the files it needs from the demo directory.
set DemoDir [file normalize [file dirname [info script]]]

### Load common commands (MakeSnapshot is used below).
source $DemoDir/scripts/common.tcl


### Create the graph.
set graph [graph .g]


### The configuration of the graph .g is all in this file.
source $DemoDir/scripts/graph2.tcl


### Map everything, add Rbc_* commands.

grid .g -sticky nsew

Rbc_ZoomStack $graph
Rbc_Crosshairs $graph
#Rbc_ActiveLegend $graph
Rbc_ClosestPoint $graph
Rbc_PrintKey $graph


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


### (1) "Fill" experiment 1.
###     Choose "if 1" to add an area fill.
###     The original BLT demo did this, but the fill makes it hard to
###     see other graph features.

if 0 {
    $graph element configure line1 \
	-areapattern solid -areaforeground green
    $graph element configure line3 \
	-areapattern solid -areaforeground red
}


### (2) "Fill" experiment 2.
###     Use the -areatile option to use the image $img.
if 0 {

    set data {
        R0lGODlhEAANAMIAAAAAAH9/f///////AL+/vwAA/wAAAAAAACH5BAEAAAUALAAAAAAQAA0A
        AAM8WBrM+rAEQWmIb5KxiWjNInCkV32AJHRlGQBgDA7vdN4vUa8tC78qlrCWmvRKsJTquHkp
        ZTKAsiCtWq0JADs=
    }
    set data {
        R0lGODlhEAANAMIAAAAAAH9/f///////AL+/vwAA/wAAAAAAACH5BAEAAAUALAAAAAAQAA0A
        AAM1WBrM+rAEMigJ8c3Kb3OSII6kGABhp1JnaK1VGwjwKwtvHqNzzd263M3H4n2OH1QBwGw6
        nQkAOw==
    }
    set img [image create photo -format gif -data $data]


    $graph element configure line1 \
	-areapattern solid -areaforeground green \
	-areatile $img 
    $graph element configure line3 \
	-areapattern @$DemoDir/bitmaps/sharky.xbm \
	-areaforeground red \
	-areabackground "" -areapattern solid
}


### (3) Experiment with markers by placing a JPEG file at this location.
set fileName testImg.jpg
if { [file exists $fileName] } {
    set img2 [image create photo]
    winop readjpeg $fileName $img2
    if 1 { 
	puts stderr [time { 
	    $graph marker create image -image $img2 \
		-coords "-360.0 -1.0 360.0 1.0" \
		-under yes \
		-mapx degrees \
		-name $fileName 
	}]
    }
} 


### (4) Experiment with image snapshots.
### Facilities for PostScript output and an image snapshot can be added to any
### demo by passing suitable arguments to the CommonHeader command.
###
### emf output (also to CLIPBOARD below) is available for Windows only.
if 0 {
bind $graph <Control-ButtonPress-3> [list MakeSnapshot $graph demo2.ppm]
bind $graph <Shift-ButtonPress-3> { 
    %W postscript output demo2.ps
    if {$tcl_platform(platform) eq "windows" } {
        %W snap -format emf demo2.emf
    }
}
}


### (5) Printing.  We do not have the command rbc::printer

if { 0 && $tcl_platform(platform) == "windows" } {
    if 0 {
        set name [lindex [rbc::printer names] 0]
        set printer {Lexmark Optra E310}
	rbc::printer open $printer
	rbc::printer getattrs $printer attrs
	puts $attrs(Orientation)
	set attrs(Orientation) Landscape
	set attrs(DocumentName) "This is my print job"
	rbc::printer setattrs $printer attrs
	rbc::printer getattrs $printer attrs
	puts $attrs(Orientation)
	after 5000 {
	    $graph print2 $printer
	    rbc::printer close $printer
	}
    } else {
	after 5000 {
	    $graph print2 
	}
    }	
    if 1 {
	after 2000 {$graph snap -format emf CLIPBOARD}
    }
}
