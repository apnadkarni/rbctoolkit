#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo demos/extras/globe.tcl
#
#  Abstracted from demos/bgexec4.tcl and demos/scripts/globe.tcl
#  Animation of a small globe.  rbc not required.
# ------------------------------------------------------------------------------
# restart using wish \
exec wish "$0" "$@"


### The script can be run from any location.
### It loads the files it needs from the demo directory.
set DemoDir [file normalize [file dirname [file dirname [info script]]]]

array set animate {
    index	 -1
    interval	200
    numBitmaps	 30
    iprefix	globe
}

set animate(fprefix) $DemoDir/stipples/globe

### Commands

proc Animate {} {
    global animate
    if { [info commands .logo] != ".logo" } {
	set animate(index) 0
	return
    }
    if { $animate(index) >= 0 } {
	.logo configure -image $animate(iprefix).$animate(index)
	incr animate(index)
	if { $animate(index) >= $animate(numBitmaps) } {
	    set animate(index) 0
	}
	after $animate(interval) Animate
    }
}


proc Start {} {
    global animate
    if { $animate(index) < 0 } {
        set animate(index) 0
        Animate
    }
}

proc Stop { } {
    global animate
    set animate(index) -1
}


### Load images

for {set i 0} {$i < $animate(numBitmaps)} {incr i} {
    image create bitmap $animate(iprefix).$i -file $animate(fprefix).$i.xbm \
        -maskfile $animate(fprefix).mask.xbm \
        -foreground green4 \
        -background lightblue
}


### Create GUI

option add *HighlightThickness 0

set visual [winfo screenvisual .] 
if { [string match *color $visual] } {
    option add *stop.background yellow
    option add *stop.activeBackground yellow2
    option add *stop.foreground navyblue
    option add *start.background green
    option add *start.activeBackground green2
    option add *start.foreground navyblue
    option add *logo.background white
    option add *logo.foreground black
}
. configure -bg white


button .start -text "Start" -command Start
button .stop -text "Stop" -command Stop
label .logo  -image $animate(iprefix).0

grid .logo .start .stop -sticky ew -padx 10 -pady 4
grid configure .logo -padx 10 -pady 4 ;#  -reqheight .6i
