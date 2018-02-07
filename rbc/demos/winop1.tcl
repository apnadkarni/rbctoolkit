#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo winop1.tcl
#
#  This script demonstrates the scaling facilities of the winop command.
# ------------------------------------------------------------------------------
# restart using wish \
exec wish "$0" "$@"

package require rbc
namespace import rbc::*


### The script can be run from any location.
### It loads the files it needs from the demo directory.
set DemoDir [file normalize [file dirname [info script]]]


if { [ file exists $DemoDir/images/sample.gif] } {
    set src [image create photo -file $DemoDir/images/sample.gif]
} else {
    puts stderr "no image file"
    exit 0
}

set width [image width $src]
set height [image height $src]

#option add *Label.font TkDefaultFont
option add *Label.background white
label .l0 -image $src
label .header0 -text "$width x $height"
label .footer0 -text "100%"
. configure -bg white

for { set i 2 } { $i <= 10 } { incr i } {
    set iw [expr $width / $i]
    set ih [expr $height / $i]
    set r [format %6g [expr 100.0 / $i]]
    image create photo r$i -width $iw -height $ih
    winop image resample $src r$i sinc
    label .header$i -text "$iw x $ih"
    label .footer$i -text "$r%"
    label .l$i -image r$i
    lappend row0 .header$i
    lappend row1 .l$i
    lappend row2 .footer$i
}

grid {*}$row0
grid {*}$row1
grid {*}$row2
