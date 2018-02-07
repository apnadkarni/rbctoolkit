#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo busy1.tcl
#
#  This demo tests the busy command.
#  With rbc 0.1 the busy command causes a segfault.
# ------------------------------------------------------------------------------
# restart using wish \
exec wish "$0" "$@"

package require rbc
namespace import rbc::*


### The script can be run from any location.
### It loads the files it needs from the demo directory.
set DemoDir [file normalize [file dirname [info script]]]

#
# General widget class resource attributes
#
option add *Button.padX 	10
option add *Button.padY 	2
option add *Scale.relief 	sunken
#option add *Scale.orient	horizontal
option add *Entry.relief 	sunken
option add *Frame.borderWidth 	2

set visual [winfo screenvisual .] 
if { $visual == "staticgray"  || $visual == "grayscale" } {
    set activeBg black
    set normalBg white
    set bitmapFg black
    set bitmapBg white
    option add *f1.background 		white
} else {
    set activeBg red
    set normalBg springgreen
    set bitmapFg blue
    set bitmapBg green
    option add *Button.background       khaki2
    option add *Button.activeBackground khaki1
    option add *Frame.background        khaki2
    option add *f2.tile		textureBg
#    option add *Button.tile		textureBg

    option add *releaseButton.background 		limegreen
    option add *releaseButton.activeBackground 	springgreen
    option add *releaseButton.foreground 		black

    option add *holdButton.background 		red
    option add *holdButton.activeBackground	pink
    option add *holdButton.foreground 		black
    option add *f1.background 		springgreen
}

#
# Instance specific widget options
#
option add *f1.relief 		sunken
option add *f1.background 	$normalBg
option add *testButton.text 	"Test"
option add *quitButton.text 	"Quit"
option add *newButton.text 	"New button"
option add *holdButton.text 	"Hold"
option add *releaseButton.text 	"Release"
option add *buttonLabel.text	"Buttons"
option add *entryLabel.text	"Entries"
option add *scaleLabel.text	"Scales"
option add *textLabel.text	"Text"

proc LoseFocus {} { 
    focus -force . 
}

set file $DemoDir/images/chalk.gif
image create photo textureBg -file $file

#
# This never gets used; it's reset by the Animate proc. It's 
# here to just demonstrate how to set busy window options via
# the host window path name
#
#option add *f1.busyCursor 	bogosity 


#
# Counter for new buttons created by the "New button" button
#
set numWin 0

menu .menu 
.menu add cascade -label "First"  -menu .menu.nothing
.menu add cascade -label "Second" -menu .menu.nothing
.menu add cascade -label "Third"  -menu .menu.nothing
.menu add cascade -label "Fourth" -menu .menu.nothing
. configure -menu .menu

menu .menu.nothing -tearoff 0
.menu.nothing add command -label "Nothing"

#
# Create two frames. The top frame will be the host window for the
# busy window.  It'll contain widgets to test the effectiveness of
# the busy window.  The bottom frame will contain buttons to 
# control the testing.
#
frame .f1
frame .f2

#
# Create some widgets to test the busy window and its cursor
#
label .buttonLabel
button .testButton -command { 
    puts stdout "Not busy." 
}
button .quitButton -command { exit }
entry .entry 
scale .scale
text .text -width 20 -height 4

#
# The following buttons sit in the lower frame to control the demo
#
button .newButton -command {
    global numWin
    incr numWin
    set name button#${numWin}
    button .f1.$name -text "$name" \
	-command [list .f1 configure -bg blue]
    grid .f1.$name -padx 10 -pady 10
}

button .holdButton -command {
    if { [busy isbusy .f1] == "" } {
        global activeBg
	.f1 configure -bg $activeBg
    }
    busy .f1 
    busy .#menu
    LoseFocus
}
button .releaseButton -command {
    if { [busy isbusy .f1] == ".f1" } {
        busy release .f1
        busy release .#menu
    }
    global normalBg
    .f1 configure -bg $normalBg
}

#
# Notice that the widgets packed in .f1 and .f2 are not their children
#

grid .testButton .entry -in .f1
grid .scale .text -in .f1
grid .quitButton -in .f1 -columnspan 2

grid configure .entry -sticky ew -padx 10 -pady 10
grid configure .scale -sticky ns -padx 10 -pady 10
grid configure .text  -sticky nsew

grid configure .quitButton       -padx 10 -pady 10

grid columnconfigure .f1 0 -weight 1
grid columnconfigure .f1 1 -weight 2
grid    rowconfigure .f1 1 -weight 1



grid .newButton     -in .f2 -padx 10 -pady 10
grid .holdButton    -in .f2 -padx 10 -pady 10
grid .releaseButton -in .f2 -padx 10 -pady 10

grid    rowconfigure .f2 0 -weight 1
grid    rowconfigure .f2 1 -weight 1
grid    rowconfigure .f2 2 -weight 1
grid columnconfigure .f2 0 -weight 1


#
# Finally, realize and map the top level window
#

grid .f1 -sticky nsew
grid .f2 -sticky nsew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 0 -weight 1


# Initialize a list of bitmap file names which make up the animated 
# fish cursor. The bitmap mask files have a "m" appended to them.

set bitmapList { left left1 mid right1 right }

#
# Simple cursor animation routine: Uses the "after" command to 
# circulate through a list of cursors every 0.075 seconds. The
# first pass through the cursor list may appear sluggish because 
# the bitmaps have to be read from the disk.  Tk's cursor cache
# takes care of it afterwards.
#
proc StartAnimation { widget count } {
    global bitmapList
    global DemoDir
    set prefix "$DemoDir/bitmaps/fish/[lindex $bitmapList $count]"
    set cursor [list @${prefix}.xbm ${prefix}m.xbm black white ]
    busy configure $widget -cursor $cursor

    incr count
    set limit [llength $bitmapList]
    if { $count >= $limit } {
	set count 0
    }
    global afterId
    set afterId($widget) [after 125 StartAnimation $widget $count]
}

proc StopAnimation { widget } {    
    global afterId
    after cancel $afterId($widget)
}

proc TranslateBusy { window } {
    #set widget [string trimright $window "_Busy"]
    set widget [string trimright $window "Busy"]
    set widget [string trimright $widget "_"]
#    if { [winfo toplevel $widget] != $widget } {
#        set widget [string trimright $widget "."]
#    }
    return $widget
}

if { [info exists tcl_platform] && $tcl_platform(platform) == "unix" } {
    bind Busy <Map> { 
	StartAnimation [TranslateBusy %W] 0
    }
    bind Busy <Unmap> { 
	StopAnimation  [TranslateBusy %W] 
    }
}

#
# For testing, allow the top level window to be resized 
#
wm min . 0 0




### The code below is not executed and is not part of the demo.
### It remains available for experimentation.

### "KeepRaised" does not work.

if 0 {

bind keepRaised <Visibility> { raise %W } 

proc KeepRaised { w } {
    bindtags $w keepRaised
}

#
# Force the demo to stay raised
#

raise .
KeepRaised .

}
