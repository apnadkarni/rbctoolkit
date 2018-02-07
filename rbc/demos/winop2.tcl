#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo winop2.tcl
#
#  This script demonstrates the rotation facilities of the winop command.
# ------------------------------------------------------------------------------
# restart using wish \
exec wish "$0" "$@"

package require rbc
namespace import rbc::*


### The script can be run from any location.
### It loads the files it needs from the demo directory.
set DemoDir [file normalize [file dirname [info script]]]


set file $DemoDir/images/qv100.t.gif

if { [file exists $file] } {
    set src [image create photo -file $file]  
} else {
    puts stderr "no image file"
    exit 0
}

set width [image width $src]
set height [image height $src]

option add *Label.font TkDefaultFont
option add *Label.background white

set i 0
foreach r { 0 90 180 270 360 45 } {
    set dest [image create photo]
    winop image rotate $src $dest $r
    label .footer$i -text "$r degrees"
    label .l$i -image $dest

    lappend row0 .l$i
    lappend row1 .footer$i

    incr i
}

grid {*}$row0 -padx  5 -pady 5
grid {*}$row1 -padx  5 -pady 5
