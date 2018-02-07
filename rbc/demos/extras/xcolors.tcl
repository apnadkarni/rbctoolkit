#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo graph1.tcl
#
#  Tk version of xcolors - rbc not required
# ------------------------------------------------------------------------------
# restart using wish \
exec wish "$0" "$@"

### The script can be run from any location.
### It loads the files it needs from this directory.
set ThisDir [file normalize [file dirname [info script]]]


if {[tk windowingsystem] eq "aqua"} {
    set Right 2
} else {
    set Right 3
}


set numCols 0
set numRows 0
set maxCols 15
set cellWidth 40
set cellHeight 20
set numCells 0
set lastCount 0
set beginInput(0) 0
set map 0
set entryCount 0
set lastTagId {}

frame .area

scrollbar .xscroll -command { .area.canvas xview } -orient horizontal
scrollbar .area.yscroll -command { .area.canvas yview }

label .sample \
    -font -*-new*century*schoolbook*-bold-r-*-*-24-*-*-*-*-*-*-* \
    -text {"Bisque is Beautiful".}

button .name -font -*-helvetica-medium-r-*-*-18-*-*-*-*-*-*-* \
    -command "AddSelection name"
button .rgb -font -*-courier-medium-r-*-*-18-*-*-*-*-*-*-* \
    -command "AddSelection rgb"

canvas .area.canvas \
    -confine 1 \
    -yscrollcommand { .area.yscroll set } \
    -width [expr 16*$cellWidth] -height 400  \
    -scrollregion [list 0 0 [expr 16*$cellWidth] 800]

frame .border -bd 2 -relief raised

label .status \
    -anchor w \
    -font -*-helvetica-medium-r-*-*-14-*-*-*-*-*-*-* 

button .quit -text "Quit" -command "exit"
button .next -text "Next" -command "DisplayColors next"
button .prev -text "Previous" -command "DisplayColors last"

selection handle .name GetColor
selection handle .rgb GetValue

bind .name <Enter> { 
    .status config -text \
	"Press button to write color name into primary selection"
}

bind .rgb <Enter> { 
    .status config -text \
	"Press button to write RGB value into primary selection"
}
bind .name <Leave> { 
    .status config -text ""
}

bind .rgb <Leave> { 
    .status config -text ""
}

bind .area.canvas <Enter> { 
    .status config -text \
	"Press left button to change background; right button changes foreground"
}

grid .sample -columnspan 2 -sticky nsew ;# -reqheight 1i
grid .name .rgb  -sticky nsew

grid .area -columnspan 2 -sticky nsew

grid .border -columnspan 2 -sticky ew ;# -reqheight 8

grid .status .quit

grid configure .status -columnspan 2 -sticky nsew
grid configure .quit -sticky ns -padx 10 -pady 4 ;# -reqwidth 1i

grid .prev .next -sticky ns -padx 10 -pady 4 ;#  -reqwidth 1i

grid columnconfigure . 0 -weight 1
grid columnconfigure . 1 -weight 1

grid    rowconfigure . 2 -weight 1


grid .area.canvas .area.yscroll -sticky ns
grid configure .area.canvas -sticky nsew

grid columnconfigure .area 0 -weight 1

grid    rowconfigure .area 0 -weight 1


proc AddSelection { what } {
    selection own .$what
    if {$what == "name" } {
	set mesg "Color name written into primary selection"
    } else {
	set mesg "RGB value written into primary selection"
    }
    .status config -text $mesg
}

proc GetColor { args } {
    return [lindex [.name config -text] 4]
}

proc GetValue { args } {
    return [lindex [.rgb config -text] 4]
}

proc ShowInfo { tagId what info } {
    global lastTagId

    if { $lastTagId != {} } {
	.area.canvas itemconfig $lastTagId -width 1
    }
    .area.canvas itemconfig $tagId -width 3
    set lastTagId $tagId

    set name [lindex $info 3]
    .name config -text $name 
    set value [format "#%0.2x%0.2x%0.2x" \
	       [lindex $info 0] [lindex $info 1] [lindex $info 2]]
    .rgb config -text $value
    .sample config $what $name
    .status config -bg $name
}


proc MakeCell { info } {
    global numCols numRows maxCols cellWidth cellHeight numCells 

    set x [expr $numCols*$cellWidth]
    set y [expr $numRows*$cellHeight]
    set color [lindex $info 3]

    if [catch {winfo rgb . $color}] {
	return "ok"
    }
#    if { [tk colormodel .] != "color" } {
#	bind . <Leave> { 
#	    .status config -text "Color table full after $numCells entries."
#	}
#	.status config -text "Color table full after $numCells entries."
#	return "out of colors"
#    }
    set id [.area.canvas create rectangle \
	    $x $y [expr $x+$cellWidth] [expr $y+$cellHeight] \
		-fill $color -outline black]
    if { $color == "white" } {
	global whiteTagId
	set whiteTagId $id
    }

    .area.canvas bind $id <1> [list ShowInfo $id -bg $info]
    .area.canvas bind $id <$::Right> [list ShowInfo $id -fg $info]
    
    incr numCols
    if { $numCols > $maxCols } {
	set numCols 0
	incr numRows
    }
    return "ok"
}

proc DisplayColors { how } {
    global lastCount numCells cellHeight numRows numCols rgbText 
    global map beginInput
    
#    tk colormodel . color
    set initialized no

    if { $how == "last" } {
	if { $map == 0 } {
	    return
	}
	set map [expr $map-1]
    } else {
	incr map
	if ![info exists beginInput($map)] {
	    set beginInput($map) $lastCount
	}
    }

    set start $beginInput($map)

    if { $numCells > 0 } {
	.area.canvas delete all
	set numRows 0
	set numCols 0
	set initialized yes
    }

    set input [lrange $rgbText $start end]
    set lineCount $start
    set entryCount 0
    foreach i $input {
	incr lineCount
	if { [llength $i] == 4 } {
	    if { [MakeCell $i] == "out of colors"  } {
		break
	    }
	    incr entryCount
	}
    }
    if { $entryCount == 0 } {
	bind . <Leave> { 
	    .status config -text "No more entries in RGB database"
	}
	.status config -text "No more entries in RGB database"
    } 
    set lastCount $lineCount
    proc tkerror {args} { 
	#dummy procedure
    }

    if { $initialized == "no" } {
	global cellWidth

	set height [expr $cellHeight*($numRows+1)]
	.area.canvas config -scrollregion [list 0 0 [expr 16*$cellWidth] $height]
	if { $height < 800 } {
	    .area.canvas config -height $height
	}
	global whiteTagId
	if [info exists whiteTagId] {
	    ShowInfo $whiteTagId -bg {255 255 255 white}
	}
    }
    update idletasks
    update
    rename tkerror {}
}

wm min . 0 0

set gotFile 0
foreach location {
	/usr/X11R6/lib
	/util/X11R6/lib
	/usr/openwin/lib
	/usr/dt/lib
	/usr/share
} {
    set file [file join $location X11 rgb.txt]
    if { [file exists $file] } {
       set gotFile 1
       break
    }
}
if {!$gotFile} {
    set file [file join $ThisDir rgb.txt]
}

set in [open $file "r"]
set rgbText [read $in]
close $in
set rgbText [split $rgbText \n]
DisplayColors next
wm min . 0 0

if {!$gotFile} {
    set file [file join $ThisDir rgb.txt]
	.status config -text "Data from demo - cannot find X11 file \"rgb.txt\"."
} else {
	.status config -text "Data read from X11 file \"rgb.txt\"."
}
