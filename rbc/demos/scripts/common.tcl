# ------------------------------------------------------------------------------
#  RBC Demos - file demos/scripts/common.tcl
# ------------------------------------------------------------------------------
#  This file is a script fragment that is sourced by
#  several demo files.
# ------------------------------------------------------------------------------

# The text widget is being used as a large read-only label with word wrap.
# We need to set its -background and -font appropriately.
option add *Text.Background [. cget -bg]
option add *Text.Font       TkDefaultFont

# This is true by default in X11, but not in Win32, where it is the same
# as TkDefaultFont!
font configure TkHeadingFont -weight bold


# ------------------------------------------------------------------------------
#  Proc MakeLine
# ------------------------------------------------------------------------------
# Command to generate multi-line strings with long lines from readable
# indented code.
#
# Example:
#   set blurb [makeLine "
#            |This command allows multi-line strings with long lines to be
#            |created with readable code, and without breaking the rules for
#            |indentation.
#            |
#            |The command shifts the entire block of text to the left, omitting
#            |the pipe character and the spaces to its left. Then it replaces
#            |each newline with a space, with the exception that double
#            |newlines are preserved.
#   "]
# ------------------------------------------------------------------------------

proc MakeLine {in} {
    set halfway [regsub -all -line {^\s*\|} [string trim $in] {}]
    string map [list \n\n \n\n \n { }] $halfway
    # N.B. Implicit Return.
}


# ------------------------------------------------------------------------------
#  Proc CommonHeader
# ------------------------------------------------------------------------------
# Command to create a header window for an RBC demo.  The window is a text
# widget, and may have embedded buttons to request printing to a PostScript file
# or generation of a snapshot image.
#
# - The optional argument win is required if the buttons for
#   PostScript or image output are requested.
# - To request the Print button, also supply a non-empty value for psFile.
# - To request the snapshot button, also supply a non-empty value for imgFile.
#
# This command replaces an htext command in the BLT demos. RBC does not include
# BLT's htext.
#
# Arguments:
# w           - Tk window path requested for the new window
# txt         - text string to be shown in the window
# lines       - number of text display lines (allowing for word wrap and the
#               height of embedded buttons.
# DemoDir     - demo directory (used for loading button images)
# win         - (optional) the window to be printed or snapshotted (an RBC widget)
# psFile      - (optional) filename for PostScript file
# imgFile     - (optional) filename for snapshot image file
#
# Return Value: Tk window path of the header window
# ------------------------------------------------------------------------------

proc CommonHeader {w txt lines DemoDir {win {}} {psFile {}} {imgFile {}}} {
    set visual [winfo screenvisual .]
    if { $visual != "staticgray" && $visual != "grayscale" } {
        set colors {-bg yellow -activebackground yellow3}
    } else {
        set colors {}
    }

    text $w            \
        -wrap   word   \
        -width  1      \
        -height 1      \
        -relief flat   \
        -padx   15     \
        -pady    5     \
        -highlightthickness 0

    ### Main Message
    $w insert end $txt

    ### Print to PostScript File
    if {($psFile ne {}) && ($win ne {})} {

        button $w.print \
                -pady 0 \
                -text Print \
                -command [list CommonPrint $win $psFile] \
                {*}$colors

        set msg "\n\nTo create a PostScript file \"$psFile\", press the "
        $w insert end $msg
        $w window create end -window $w.print
        $w insert end { button.}
    }

    ### Snapshot to Image File
    if {($imgFile ne {}) && ($win ne {})} {
        set im [image create photo -file $DemoDir/images/qv100.t.gif]
        button $w.snap \
                -image $im \
                -activebackground black \
                -command [list MakeSnapshot $win $imgFile]

        $w insert end "\nYou can click on the "
        $w window create end -window $w.snap
        $w insert end { button to see a photo image snapshot.}
    }

    bind $w <Configure> {AdjustHeight %W 20}

    $w configure -state disabled
    return $w
}


# ------------------------------------------------------------------------------
#  Proc AdjustHeight
# ------------------------------------------------------------------------------
# Command to adjust the height of a text widget to fit its contents.
#
# Usage in this file: bound to <Configure> to ensure that the widget is large
# enough, even if the text or font changes.
#
# Arguments:
# w           - Tk window path of a text widget
# maxLines    - maximum permitted widget height (in text lines)
#
# Return Value: none
# ------------------------------------------------------------------------------

proc AdjustHeight {w maxLines} {
    # $w has no extra spacings per line.
    set lineSpace [font metrics [$w cget -font] -linespace]
    set yPixels   [$w count -update -ypixels 1.0 end]
    set needLines [expr { ($yPixels + $lineSpace - 1) / $lineSpace }]

    if {$needLines <= $maxLines} {
        $w configure -height $needLines
    } else {
        # Ignore large demands during startup.
        # In 8.5 it's only the first call for each widget.
    }
    return
}


# ------------------------------------------------------------------------------
#  Proc CommonFooter
# ------------------------------------------------------------------------------
# Command to create a footer window for an RBC demo.  The window is a text
# widget, and has an embedded "Quit" button to close the demo, and the "BLT"
# logo from the original BLT demos.
#
# This command replaces an htext command in the BLT demos. RBC does not include
# BLT's htext.
#
# Arguments:
# w           - Tk window path requested for the new window
# DemoDir     - demo directory (used for loading button images)
# style       - (optional) TXT (the default) for a text button; anything else
#               for an image button.
#
# Return Value: Tk window path of the footer window
# ------------------------------------------------------------------------------

proc CommonFooter {w DemoDir {style TXT}} {

    set visual [winfo screenvisual .]
    if { $visual != "staticgray" && $visual != "grayscale" } {
        set txtColors {-bg red -activebackground red2}
        set imgColors {-bg red}
    } else {
        set txtColors {}
        set imgColors {}
    }

    text $w          \
        -wrap   word \
        -width   0   \
        -height  3   \
        -relief flat \
        -padx   15   \
        -pady    5   \
        -highlightthickness 0

    button $w.quit -command exit -pady 0
    label  $w.logo -bitmap @$DemoDir/bitmaps/BLT.xbm

    $w insert end {Hit the }
    $w window create end -window $w.quit
    $w insert end { button when you've seen enough. }
    $w window create end -window $w.logo -padx 20

    if {$style eq {TXT}} {
        $w.quit configure -text Quit {*}$txtColors
    } else {
        set im [image create photo -file $DemoDir/images/stopsign.gif]
        $w.quit configure -image $im {*}$imgColors
    }

    bind $w <Configure> {AdjustHeight %W 20}

    $w configure -state disabled

    return $w
}


# ------------------------------------------------------------------------------
#  Proc CommonPrint
# ------------------------------------------------------------------------------
# Command to print an RBC widget to a PostScript file.
#
# Adapted from BLT demos graph1.tcl, barchart*.tcl.
#
# Arguments:
# graph       - the window to be printed (an RBC widget)
# psFile      - the filename for output
#
# Return Value: none
# ------------------------------------------------------------------------------

proc CommonPrint {graph psFile} {

    # If the demo's PostScript dialog has been loaded, use it.
    if {[info commands ::rbc::ps::psDialog] ne {}} {
        ::rbc::ps::psDialog $graph $psFile
        return
    }

    # This is a simple dialog that lets the user directly set the
    # "configure" options of the graph's postscript component.
    if 0 {
        Rbc_PostScriptDialog $graph
        return
    }

    ### FIXME rbc - rbc::busy segfaults, so instead use a grab.
    ### This gives a "busy" warning and also prevents the user+GUI
    ### from changing the graph while it is printing.
    ###rbc::busy hold .
    set lab .temporaryLabelInRBCDemoCommonPrint
    destroy $lab
    label $lab -text "Printing ..." -bg yellow -fg red
    place $lab -relx 0.5 -rely 0.0 -anchor n
    grab  $lab

    ### Catch so the grab is always released.
    set catchValue [catch {
        update idletasks
        $graph postscript output $psFile
        update idletasks
    } catchRes catchDict]

    ###rbc::busy release .
    grab release $lab
    destroy $lab

    update idletasks

    if {$catchValue == 1} {
        return -code error -errorinfo [dict get $catchDict -errorinfo] $catchRes
    }

    return
}


# ------------------------------------------------------------------------------
#  Proc MakeSnapshot
# ------------------------------------------------------------------------------
# Command to print an RBC widget to a PostScript file.
#
# Adapted (with dependencies) from BLT demos graph4.tcl
#
# Arguments:
# graph       - the window to be snapshotted (an RBC widget)
# filename    - the filename for output
#
# Return Value: none
# ------------------------------------------------------------------------------

proc MakeSnapshot {graph filename} {
    update idletasks
    global unique

    # Set to 1 to create a second thumbnail that tests the "winop snap" command.
    set TestWinop 0

    set top ".snapshot[incr unique]"
    set im1 [image create photo]
    set im2 [image create photo]
    $graph snap $im1

    set thumb1 [image create photo -width 210 -height 150 -gamma 1.8]
    winop resample $im1 $thumb1 sinc 
    #Sharpen $thumb1

    if {$TestWinop} {
        rbc::winop snap $graph $im2 
        set thumb2 [image create photo -width 210 -height 150 -gamma 1.8]
        winop resample $im2 $thumb2 sinc 
    }

    toplevel $top
    wm title $top "Snapshot \#$unique of \"[$graph cget -title]\""
    wm protocol $top WM_DELETE_WINDOW [list DestroySnapshot $top $im1 $im2]
    label $top.l1 -image $thumb1
    frame $top.bb

    if {$TestWinop} {
        label $top.l2 -image $thumb2
    }

    # Uses PPM format. Too many colors for GIF.
    # Tk has no other image formats unless img::* or Img is loaded.
    button $top.bb.ppm0 \
            -text "Save Full-Size as PPM File" \
            -command [list $im1 write $filename -format ppm]
    button $top.bb.ppm1 \
            -text "Save Thumbnail as PPM File" \
            -command [list $thumb1 write $filename -format ppm]
    button $top.bb.but \
            -text "Dismiss" \
            -command [list DestroySnapshot $top $im1 $im2]

    if {$TestWinop} {
        grid $top.l1 $top.l2
    } else {
        grid $top.l1 -columnspan 2
    }

    grid $top.bb -sticky ew -columnspan 2

    grid $top.bb.ppm0 $top.bb.ppm1 $top.bb.but -pady 4 -padx 10

    focus $top.bb.but
    return
}

proc DestroySnapshot {win im1 im2} {
    image delete $im1
    image delete $im2

    set thumb1 [$win.l1 cget -image]
    image delete $thumb1
    if {[winfo exists $win.l2]} {
        set thumb2 [$win.l2 cget -image]
        image delete $thumb2
    }
    destroy $win
    return
}


# Unused: commented out in MakeSnapshot (including BLT original)

proc Sharpen { photo } {
    #set kernel { -1 -1 -1 -1  16 -1 -1 -1 -1 } 
    set kernel { 0 -1 0 -1  4.9 -1 0 -1 0 }
    winop convolve $photo $photo $kernel
    return
}
