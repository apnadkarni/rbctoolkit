# ------------------------------------------------------------------------------
#  RBC Demo scripts/ps.tcl
#
#  A dialog to configure the postscript® component of RBC widgets.
# ------------------------------------------------------------------------------
#
# Usage:
#    namespace import ::rbc::ps::*
#    psDialog graph ?filename?
#
# Arguments:
#    graph    is the Tk window path of an rbc widget with postscript capability
#             (i.e. a graph, barchart, or stripchart)
#    filename is the name of the output file (default value out.ps)
#
# Return Value: none
# ------------------------------------------------------------------------------
#
# Landscape Orientation
#
# 1. ON THE PAGE
# In "landscape mode" (option -landscape 1), the image is rotated 90 degrees
# relative to the page, and the page itself is unchanged.  The postscript
# component's options
#   -height
#   -width
# refer to the rotated image of the widget, but the options
#   -padx
#   -pady
#   -paperheight
#   -paperwidth
# refer to the unchanged page, i.e. for these four options the meaning of
# x, y, height and width is the same as in portrait orientation.
#
# 2. ON THE CANVAS
# The canvas represents the sheet of paper, but in "landscape mode" the
# paper is rotated by 270 degrees, so the image is upright on the canvas.
#
# 3. PRINTOUT
# To convert a PostScript® file filename.ps to a PDF file filename.pdf using
# Ghostscript®, and preserve the landscape/portrait orientation, use:
#     ps2pdf -sPAPERSIZE=a4 -dAutoRotatePages=/None  filename.ps
# (replace "a4" with your paper size).
# Ghostscript® is a registered trademark of Artifex Software Inc.
# PostScript® is a registered trademark of Adobe Systems Inc.
# ------------------------------------------------------------------------------
#
#      ELEMENTS OF ARRAY pageInfo - (1) postscript configure options
#
# -center        - (boolean) true iff plot is centred rather than in top left
# -colormap      - (if not {}) name of array that holds X11 to postscript
#                  color map
# -colormode     - color|gray|mono
# -decorations   - (boolean) true iff postscript will show color backgrounds and
#                  decorations
# -fontmap       - (if not {}) name of array that holds X11 to postscript
#                  font map
# -footer        - (boolean) iff true, print a footer
# -height        - Tk distance for height of the plot (0 for same as widget)
# -landscape     - (boolean) iff true, print in landscape mode
# -maxpect       - (boolean) iff true, print at largest possible size that
#                  preserves the aspect ratio
# -padx          - one or two Tk distances for left and right padding
# -pady          - one or two Tk distances for top and bottom padding
# -paperheight   - as a Tk distance
# -paperwidth    - as a Tk distance
# -preview       - (not supported)
# -previewformat - (not supported)
# -width         - width of the plot in Tk distance units (0 for same as widget)
#
#      ELEMENTS OF ARRAY pageInfo - (2) other
#
# afterId        - event id used by size adjustors when held down
# dialogInit     - initial page size for the dialog. letter|legal|large|a3|a4|a5
# direction      - undecided|x|y (used in constrained move)
# graph          - Tk window path of rbc widget to be printed
# grip           - the identity of the grip used in a resize operation
# gripSize       - (integer) size in pixels of the grips
# image          - the command for the image drawn on the canvas
# labelFont      - font used for dialog labels
# largeImage     - the command for the unscaled image of the graph
# lastX          - value of %x from last triggered binding
# lastY          - value of %y from last triggered binding
# oldPadX        - value of -padx (two numbers) stored for possible reuse
# oldPadY        - value of -pady (two numbers) stored for possible reuse
# paperHeight    - (canvas units) floating point pixels
# paperSize      - (page units) two screen distances, measured in cm or inches
# paperWidth     - (canvas units) floating point pixels
# plotSize       - default|maxpect|resize (radiobutton variable)
# position       - move|1|0 (radiobutton variable)
# printCmd       - (not used) command to use for printing
# printFile      - filename for output
# printTo        - printFile|printCmd
# radioFont      - font used for radiobuttons
# scale          - floating point scale factor, canvas/paper
# units          - c|i - units to use (cm, inches)
# uscale         - screen dots per inch or dots per cm, depending on units
# xMax           - image corner, canvas units, floating point pixels
# xMin           - image corner, canvas units, floating point pixels
# yMax           - image corner, canvas units, floating point pixels
# yMin           - image corner, canvas units, floating point pixels
# ------------------------------------------------------------------------------



##### (1) Initialization.

namespace eval ::rbc::ps {
    variable ApplyPsCounter 0
    variable cursors
    variable pageInfo

    array set cursors {
	w left_side
	e right_side
	n top_side
	s bottom_side
	sw bottom_left_corner
	ne top_right_corner
	se bottom_right_corner
	nw top_left_corner
    }

    array set pageInfo {
	gripSize   8
	scale      0.25
	radioFont  TkDefaultFont
	labelFont  TkHeadingFont
	dialogInit a4
	printCmd   "nlp -d2a211"
	printFile  "out.ps"
	debug      1
    }

    image create photo ::rbc::ps::up -data {
	R0lGODlhCwAGAKECAAAAAICAgP///////yH5BAEKAAIALAAAAAALAAYAAAIRlB2nCLkS
	gHQnylmvTlbfUAAAOw==
    }

    image create photo ::rbc::ps::down -data {
	R0lGODlhCwAGAKECAAAAAICAgP///////yH5BAEKAAIALAAAAAALAAYAAAIQDI4YYnkr
	mINRvooNxXGLAgA7
    }

    namespace export psDialog
}



##### (2) Commands to build the GUI dialog.

# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::psDialog (EXPORTED)
# ------------------------------------------------------------------------------
# Command to post a "PostScript Options" dialog for printing an rbc widget.
# This is the only exported command.
#
# Arguments:
# graph       - is the Tk window path of an rbc widget with postscript
#               capability (i.e. a graph, barchart, or stripchart)
# filename    - is the name of the output file (default value out.ps)
#
# Return Value: none
# ------------------------------------------------------------------------------

proc ::rbc::ps::psDialog { graph {filename {}} } {
    variable pageInfo

    option add *graph.top*Radiobutton.font $pageInfo(radioFont)

    # Initialize pageInfo
    set pageInfo(graph) $graph
    GetPsOptions $graph
    ComputeCanvasGeometryFromPs $graph
    foreach name [lsort [array names pageInfo]] {
	catch {puts "$name $pageInfo($name)"}
    }

    set pageInfo(oldPadX) [winfo pixels $graph 1i]
    set pageInfo(oldPadY) [winfo pixels $graph 1i]
    if {$filename ne {}} {
	set pageInfo(printFile) $filename
    }

    # Now draw the GUI
    set top $graph.top
    toplevel $top
    wm title $top "PostScript options for RBC graph"

    set canvas $top.layout
    canvas $canvas -confine yes \
	    -width $pageInfo(paperWidth) -height $pageInfo(paperHeight) \
	    -bg gray -bd 2 -relief sunken 

    # Create and lay out the canvas "outline" items;
    CreateOutline $canvas

    label $top.titleLabel -text "PostScript Options"
    grid $top.titleLabel -columnspan 4
    grid $canvas -columnspan 4

    set row 2
    label $top.paperLabel -text "Paper"
    radiobutton $top.letter -text "Letter 8 1/2 x 11 in." -value "8.5i 11i" \
	    -variable ::rbc::ps::pageInfo(paperSize) \
	    -command "::rbc::ps::SetPaperSize i"
    radiobutton $top.a3 -text "A3 29.7 x 42 cm." -value "28.7c 41c" \
	    -variable ::rbc::ps::pageInfo(paperSize) \
	    -command "::rbc::ps::SetPaperSize c"
    radiobutton $top.a4 -text "A4 21 x 29.7 cm." -value "21c 29.7c" \
	    -variable ::rbc::ps::pageInfo(paperSize) \
	    -command "::rbc::ps::SetPaperSize c"
    radiobutton $top.a5 -text "A5 14.85 x 21 cm." -value "14.85c 21c" \
	    -variable ::rbc::ps::pageInfo(paperSize) \
	    -command "::rbc::ps::SetPaperSize c"
    radiobutton $top.legal -text "Legal 8 1/2 x 14 in." -value "8.5i 14i" \
	    -variable ::rbc::ps::pageInfo(paperSize) \
	    -command "::rbc::ps::SetPaperSize i"
    radiobutton $top.large -text "Large 11 x 17 in." -value "11i 17i" \
	    -variable ::rbc::ps::pageInfo(paperSize) \
	    -command "::rbc::ps::SetPaperSize i"


    grid $top.paperLabel -sticky e -row $row -column 0 -pady {4 0} -padx {10 0}
    grid $top.letter     -sticky w -row $row -column 1 -pady {4 0}
    grid $top.a3         -sticky w -row $row -column 2 -pady {4 0}
    incr row

    grid $top.legal      -sticky w -row $row -column 1
    grid $top.a4         -sticky w -row $row -column 2
    incr row

    grid $top.large      -sticky w -row $row -column 1
    grid $top.a5         -sticky w -row $row -column 2
    incr row

    label $top.orientLabel -text "Orientation"
    radiobutton $top.portrait -text "Portrait" -value "0" \
	    -variable ::rbc::ps::pageInfo(-landscape) \
	    -command "::rbc::ps::ApplyPs"
    radiobutton $top.landscape -text "Landscape" -value "1" \
	    -variable ::rbc::ps::pageInfo(-landscape) \
	    -command "::rbc::ps::ApplyPs"


    grid $top.orientLabel -sticky e -row $row -column 0 -pady {4 0} -padx {10 0}
    grid $top.portrait    -sticky w -row $row -column 1 -pady {4 0}
    grid $top.landscape   -sticky w -row $row -column 2 -pady {4 0}
    incr row 6

    label $top.plotLabel -text "Plot Options"

    grid $top.plotLabel -row $row -column 0 -columnspan 3
    incr row

    label $top.sizeLabel -text "Size"
    radiobutton $top.default -text "Default" -value "default" \
	    -variable ::rbc::ps::pageInfo(plotSize) \
	    -command "::rbc::ps::SetPlotSize"
    radiobutton $top.maxpect -text "Max Aspect" -value "maxpect" \
	    -variable ::rbc::ps::pageInfo(plotSize) \
	    -command "::rbc::ps::SetPlotSize"
    radiobutton $top.resize -text "Resize" -value "resize" \
	    -variable ::rbc::ps::pageInfo(plotSize) \
	    -command "::rbc::ps::SizeDialog $graph {Adjust Plot Size}"


    grid $top.sizeLabel -sticky e -row $row -column 0 -pady {4 0} -padx {10 0}
    grid $top.default   -sticky w -row $row -column 1 -pady {4 0}
    incr row

    grid $top.maxpect   -sticky w -row $row -column 1
    incr row

    grid $top.resize    -sticky w -row $row -column 1
    incr row -2
    
    label $top.posLabel -text "Position"
    set pageInfo(position) $pageInfo(-center)
    radiobutton $top.center -text "Center" -value "1" \
	    -variable ::rbc::ps::pageInfo(position) \
	    -command {
	        set ::rbc::ps::pageInfo(-center) 1
	        ::rbc::ps::CenterPlot
	    }
    radiobutton $top.origin -text "Origin" -value "0" \
	    -variable ::rbc::ps::pageInfo(position) \
	    -command {
	        set ::rbc::ps::pageInfo(-center) 0
	        ::rbc::ps::ApplyPs
	    }
    radiobutton $top.move -text "Move" -value "move" \
	    -variable ::rbc::ps::pageInfo(position) \
	    -command {
	        set ::rbc::ps::pageInfo(-center) 0
	        # ::rbc::ps::MoveDialog
	        # This command does not exist.
	    }


    grid $top.posLabel -sticky e -row $row -column 2 -pady { 4 0 }
    grid $top.center   -sticky w -row $row -column 3 -pady { 4 0 } -padx {0 10}
    incr row

    grid $top.origin   -sticky w -row $row -column 3 -padx {0 10}
    incr row

    grid $top.move     -sticky w -row $row -column 3 -padx {0 10}
    incr row

    label $top.printLabel -text "Print To"
    radiobutton $top.toFile -text "File" -value "printFile" \
	-variable ::rbc::ps::pageInfo(printTo) -command "
	   $top.fileEntry configure -textvariable ::rbc::ps::pageInfo(printFile)
	"
    radiobutton $top.toCmd -text "Command" -value "printCmd" \
	-variable ::rbc::ps::pageInfo(printTo) -command "
	   $top.fileEntry configure -textvariable ::rbc::ps::pageInfo(printCmd)
	" -state disabled
    entry $top.fileEntry -bg white -width 36
    # The "Command" option does nothing.
    grid $top.printLabel -sticky e -row $row -column 0 -pady {4 0} -padx {10 0}
    grid $top.toFile     -sticky w -row $row -column 1 -pady {4 0}
    incr row

    grid $top.toCmd      -sticky w -row $row -column 1 -pady {4 0}
    incr row

    grid $top.fileEntry  -sticky w -row $row -column 1 -pady {4 0} -padx 10 \
	    -columnspan 3
    incr row

    button $top.cancel -text "Cancel" -command "destroy $top" -font TkHeadingFont
    button $top.print -text "Print" -command "::rbc::ps::PrintPs $graph $top" -font TkHeadingFont
    button $top.opts -text "Options" -command "::rbc::ps::OptionsDialog $graph" -font TkHeadingFont

    grid $top.print    -row $row -column 1 -pady {6 2} -padx 10 -sticky w
    grid $top.opts     -row $row -column 2 -pady {6 2}
    grid $top.cancel   -row $row -column 3 -pady {6 2} -padx {0 10}

    foreach label [info commands $top.*Label] {
	$label configure -font $pageInfo(labelFont) -padx 4
    }


    # Set radiobutton defaults if this has not already been done.
    if {    (![info exists $pageInfo(paperSize)])
	 && ($pageInfo(dialogInit) in {letter a3 a4 a5 legal large})
    } {
	$top.$pageInfo(dialogInit) invoke
    } elseif {(![info exists $pageInfo(paperSize)])} {
	SetUnits inches
    }

    if {![info exists $pageInfo(plotSize)]} {
	$top.maxpect invoke
    }
    # Not needed:
    # $top.landscape invoke
    # $top.center invoke
    $top.toFile invoke

    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::CreateOutline
# ------------------------------------------------------------------------------
# Command to create and lay out the 9 canvas items and 2 images, using values
# from pageInfo elements gripSize xMin yMin xMax yMax.
#
# Called once by psDialog.
#
# Image details:
# The two images are a snapshot image from the graph, and a scaled version for
# use in the canvas. The command stores their command names in
# pageInfo(largeImage) and pageInfo(image) respectively.
#
# Item details:
# All canvas items are tagged "outline".
# The canvas items are one image (also tagged "image"), and 8 rectangles (also
# tagged "grip" and with a unique id).
# ------------------------------------------------------------------------------

proc ::rbc::ps::CreateOutline { canvas } {
    variable pageInfo
    foreach var { graph gripSize xMin yMin xMax yMax } {
	set $var $pageInfo($var)
    }

    $canvas create image $xMin $yMin -tags "outline image" -anchor nw

    $canvas bind image <ButtonPress-1>   "::rbc::ps::StartMove $canvas %x %y"
    $canvas bind image <B1-Motion>       "::rbc::ps::DragMove $canvas %x %y"
    $canvas bind image <Shift-B1-Motion> "::rbc::ps::DragMoveBut $canvas %x %y"
    $canvas bind image <ButtonRelease-1> "::rbc::ps::EndMove $canvas"
    $canvas bind image <Enter>           "::rbc::ps::EnterImage $canvas"
    $canvas bind image <Leave>           "::rbc::ps::LeaveImage $canvas"
    focus $canvas
    $canvas create rectangle \
	    $xMin $yMin [expr {$xMin + $gripSize}] [expr {$yMin + $gripSize}] \
	    -tags "outline grip nw" 
    $canvas create rectangle \
	    [expr {$xMax - $gripSize}] [expr {$yMax - $gripSize}] $xMax $yMax \
	    -tags "outline grip se" 
    $canvas create rectangle \
	    [expr {$xMax - $gripSize}] [expr {$yMin + $gripSize}] $xMax $yMin \
	    -tags "outline grip ne" 
    $canvas create rectangle \
	    $xMin $yMax [expr {$xMin + $gripSize}] [expr {$yMax - $gripSize}] \
	    -tags "outline grip sw" 

    set xMid [expr {($xMax + $xMin - $gripSize) * 0.5}]
    set yMid [expr {($yMax + $yMin - $gripSize) * 0.5}]
    $canvas create rectangle \
	    $xMid $yMin [expr {$xMid + $gripSize}] [expr {$yMin + $gripSize}] \
	    -tags "outline grip n" 
    $canvas create rectangle \
	    $xMid [expr {$yMax - $gripSize}] [expr {$xMid + $gripSize}] $yMax \
	    -tags "outline grip s" 
     $canvas create rectangle \
	    [expr {$xMax - $gripSize}] $yMid $xMax [expr {$yMid + $gripSize}] \
	    -tags "outline grip e" 
     $canvas create rectangle \
	    $xMin $yMid [expr {$xMin + $gripSize}] [expr {$yMid + $gripSize}] \
	    -tags "outline grip w" 
    foreach grip { e w s n sw ne se nw } {
	$canvas bind $grip <ButtonPress-1>   "::rbc::ps::StartResize %W $grip %x %y"
	$canvas bind $grip <B1-Motion>       "::rbc::ps::DragResize %W %x %y"
	$canvas bind $grip <Shift-B1-Motion> "::rbc::ps::DragResizeBut %W %x %y"
	$canvas bind $grip <ButtonRelease-1> "::rbc::ps::EndResize %W $grip %x %y"
	$canvas bind $grip <Enter>           "::rbc::ps::EnterGrip %W $grip %x %y"
	$canvas bind $grip <Leave>           "::rbc::ps::LeaveGrip %W $grip"
    }
    $canvas raise grip
    $canvas itemconfigure grip -fill red -outline black

    set pageInfo(largeImage) [image create photo]
    $graph snap -format photo $pageInfo(largeImage)

    set pageInfo(image) [image create photo \
	-width  [expr {int($xMax - $xMin)}] \
	-height [expr {int($yMax - $yMin)}] \
    ]

    winop image resample $pageInfo(largeImage) $pageInfo(image) sinc

    $canvas itemconfigure image -image $pageInfo(image)
    return
}



##### (3) Conversion between units.

# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::SetUnits
# ------------------------------------------------------------------------------
# Choose units inches or centimetres.
# This sets pageInfo(uscale) and pageInfo(units) for subsequent use.
# ------------------------------------------------------------------------------

proc ::rbc::ps::SetUnits { units }  {
    variable pageInfo
    switch -glob $units {
	"i*"    { set pageInfo(uscale) [winfo fpixels $pageInfo(graph) 1i] }
	"c*"    { set pageInfo(uscale) [winfo fpixels $pageInfo(graph) 1c] }
	default { error "unknown unit \"$units\"" }
    }
    set pageInfo(units) [string index $units 0]
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::ConvertUnits
# ------------------------------------------------------------------------------
# This command converts a valid Tk screen distance in pixels to one in inches or
# cm, to the nearest 0.1 unit.
# ------------------------------------------------------------------------------

proc ::rbc::ps::ConvertUnits { value } {
    variable pageInfo
    set value [expr {double($value) / $pageInfo(uscale)}]
    return [format "%.1f%s" $value $pageInfo(units)]
}



##### (4) Commands to synchronize information.

### ----------------------------------------------------------------------------
### Information in four places must be synchronized when appropriate.
### 0. $graph postscript configure
### 1. "pageInfo1" - pageInfo element names -*
### 2. "pageInfo2" - pageInfo element names [A-Za-z]*
### 3. the canvas layout
###
### The comments below document the flow of information between these places.
### In each comment block:
### - the first line identifies the command described by the block
### - lines in brackets are descriptive
### - a line with numerals connected by an arrow describes a flow of
###   information; if commands are named to the right, the flow occurs when
###   these commands are called.
###
###
### Command GetPsOptions
### 0 -> 1
###
###
### Command ComputeCanvasGeometryFromPs
### (recomputes a consistent pageInfo: 2' means 2 with consistency adjustments)
### (calls GetPsOptions)
### 0 -> 1       GetPsOptions
### 1 -> 2 -> 2'
###
###
### Command AdjustCanvas
### 2 -> 3
###
###
### Commands bound to canvas drag events
### (bindings alter pageInfo2, then call AdjustCanvas)
### 2 -> 2'
### 2 -> 3       AdjustCanvas
###
###
### Commands bound to canvas button-release events
### (call CanvasToPs and thus ApplyPs)
### (ApplyPs is overkill - unless ApplyPs is needed to make a consistency
###  correction, e.g. if the item has been dragged out of the viewport)
### 2 -> 1       CanvasToPs
### 1 -> 0       CanvasToPs ApplyPs
### 0 -> 1       CanvasToPs ApplyPs ComputeCanvasGeometryFromPs GetPsOptions
### 1 -> 2 -> 2' CanvasToPs ApplyPs ComputeCanvasGeometryFromPs
### 2 -> 3       CanvasToPs ApplyPs AdjustCanvas
###
###
### CanvasToPs
### (calls ApplyPs)
### 2 -> 1
### 1 -> 0       ApplyPs
### 0 -> 1       ApplyPs ComputeCanvasGeometryFromPs GetPsOptions
### 1 -> 2 -> 2' ApplyPs ComputeCanvasGeometryFromPs
### 2 -> 3       ApplyPs AdjustCanvas
###
###
### ApplyPs
### (calls ComputeCanvasGeometryFromPs which calls GetPsOptions)
### (calls AdjustCanvas)
### 1 -> 0
### 0 -> 1       ComputeCanvasGeometryFromPs GetPsOptions
### 1 -> 2 -> 2' ComputeCanvasGeometryFromPs
### 2 -> 3       AdjustCanvas
### ----------------------------------------------------------------------------


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::GetPsOptions
# ------------------------------------------------------------------------------
# Copy postscript options from $graph to pageInfo.
# ------------------------------------------------------------------------------

proc ::rbc::ps::GetPsOptions { graph } {
    variable pageInfo

    foreach opt [$graph postscript configure] {
	set pageInfo([lindex $opt 0]) [lindex $opt 4]
    }
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::ComputeCanvasGeometryFromPs
# ------------------------------------------------------------------------------
# Command to convert postscript options to canvas dimensions
# (a) copies the postscript options into pageInfo
# (b) computes page layout (in local variables) from postscript options only -
#     adjusts values if the options request -maxpect 1 or -center 1, or if the
#     image plus padding is too large for the page.
# (c) sets pageInfo elements xMin xMax yMin yMax paperHeight paperWidth
#     (which are all in canvas units), using the layout calculated above, and
#     the canvas scale factor pageInfo(scale).  The first four describe the
#     corners of the canvas image item, the last two the dimensions of the
#     canvas itself.
# ------------------------------------------------------------------------------

proc ::rbc::ps::ComputeCanvasGeometryFromPs { graph } {
    variable pageInfo

    GetPsOptions $graph
    if { $pageInfo(-width) > 0 } {
	set width $pageInfo(-width)
    } else {
	# This is what the postscript option value 0 means.
	set width [winfo width $graph]
    }
    if { $pageInfo(-height) > 0 } {
	set height $pageInfo(-height)
    } else {
	# This is what the postscript option value 0 means.
	set height [winfo height $graph]
    }

    if {$pageInfo(-landscape)} {
	set left   [winfo fpixels $graph [lindex $pageInfo(-pady) 1]]
	set right  [winfo fpixels $graph [lindex $pageInfo(-pady) 0]]
	set top    [winfo fpixels $graph [lindex $pageInfo(-padx) 0]]
	set bottom [winfo fpixels $graph [lindex $pageInfo(-padx) 1]]
    } else {
	set left   [winfo fpixels $graph [lindex $pageInfo(-padx) 0]]
	set right  [winfo fpixels $graph [lindex $pageInfo(-padx) 1]]
	set top    [winfo fpixels $graph [lindex $pageInfo(-pady) 0]]
	set bottom [winfo fpixels $graph [lindex $pageInfo(-pady) 1]]
    }

    set padx [expr {$left + $right}]
    set pady [expr {$top + $bottom}]

    if { $pageInfo(-paperwidth) > 0 } {
	set paperWidth $pageInfo(-paperwidth)
    } else {
	set paperWidth [expr {$width + $padx}]
    }
    if { $pageInfo(-paperheight) > 0 } {
	set paperHeight $pageInfo(-paperheight)
    } else {
	set paperHeight [expr {$height + $pady}]
    }
    if { $pageInfo(-landscape) } {
	set temp $paperWidth
	set paperWidth $paperHeight
	set paperHeight $temp
    }

    if { $pageInfo(-maxpect) } {
	# Determine the maximum size that preserves the aspect ratio.
	set mScale 1.0
	set xScale [expr {($paperWidth - $padx) / double($width)}]
	set yScale [expr {($paperHeight - $pady) / double($height)}]
	set mScale [expr {min($xScale,$yScale)}]
	set bboxWidth [expr {round($width * $mScale)}]
	set bboxHeight [expr {round($height * $mScale)}]
    } else {
	# Reduce dimensions if they exceed the paper size.
	if { ($width + $padx) > $paperWidth } {
	    set width [expr {$paperWidth - $padx}]
	}
	if { ($height + $pady) > $paperHeight } {
	    set height [expr {$paperHeight - $pady}]
	}
	set bboxWidth $width
	set bboxHeight $height
    }

    # Apply centering if requested.
    set x $left
    set y $top
    if { $pageInfo(-center) } {
	if { $paperWidth > $bboxWidth }  {
	    set x [expr {($paperWidth - $bboxWidth) / 2}]
	}
	if { $paperHeight > $bboxHeight } {
	    set y [expr {($paperHeight - $bboxHeight) / 2}]
	}
    }

    # All the dimensions above are those of the page.  Now they are scaled to
    # those of the canvas.
    set pageInfo(xMin) [expr {$x * $pageInfo(scale)}]
    set pageInfo(yMin) [expr {$y * $pageInfo(scale)}]
    set pageInfo(xMax) [expr {($x + $bboxWidth) * $pageInfo(scale)}]
    set pageInfo(yMax) [expr {($y + $bboxHeight) * $pageInfo(scale)}]
    set pageInfo(paperHeight) [expr {$paperHeight * $pageInfo(scale)}]
    set pageInfo(paperWidth) [expr {$paperWidth * $pageInfo(scale)}]
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::AdjustCanvas
# ------------------------------------------------------------------------------
# Update the size and position of canvas items tagged "outline" - the image
# and the grips - using data already in pageInfo
# ------------------------------------------------------------------------------

proc ::rbc::ps::AdjustCanvas { canvas } {
    variable pageInfo
    foreach var { paperWidth paperHeight graph gripSize xMin yMin xMax yMax } {
	set $var $pageInfo($var)
    }

    set width  [winfo pixels $graph $paperWidth]
    set height [winfo pixels $graph $paperHeight]
    $canvas configure -width $width -height $height

    set xMid [expr {($xMax + $xMin - $gripSize) * 0.5}]
    set yMid [expr {($yMax + $yMin - $gripSize) * 0.5}]
    $canvas coords image $xMin $yMin 

    # Resize and resample the image itself.
    $pageInfo(image) configure \
	-width  [expr {int($pageInfo(xMax) - $pageInfo(xMin))}] \
	-height [expr {int($pageInfo(yMax) - $pageInfo(yMin))}]
    winop image resample $pageInfo(largeImage) $pageInfo(image) sinc

    $canvas coords nw \
	$xMin $yMin [expr {$xMin + $gripSize}] [expr {$yMin + $gripSize}]
    $canvas coords se \
	[expr {$xMax - $gripSize}] [expr {$yMax - $gripSize}] $xMax $yMax 
    $canvas coords ne \
	[expr {$xMax - $gripSize}] [expr {$yMin + $gripSize}] $xMax $yMin 
    $canvas coords sw \
	$xMin $yMax [expr {$xMin + $gripSize}] [expr {$yMax - $gripSize}]

    $canvas coords n \
	$xMid $yMin [expr {$xMid + $gripSize}] [expr {$yMin + $gripSize}]
    $canvas coords s \
	$xMid [expr {$yMax - $gripSize}] [expr {$xMid + $gripSize}] $yMax
     $canvas coords e \
 	[expr {$xMax - $gripSize}] $yMid $xMax [expr {$yMid + $gripSize}]
     $canvas coords w \
 	$xMin $yMid [expr {$xMin + $gripSize}] [expr {$yMid + $gripSize}]
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::CanvasToPs
# ------------------------------------------------------------------------------
# Convert canvas measurements to postscript options by processing elements of
# pageInfo.
# - Read canvas measurements xMin yMin xMax yMax scale paperWidth paperHeight
#   and the common canvas/postscript option -landscape.
# - Write postscript options -width -height -padx -pady -maxpect
# ------------------------------------------------------------------------------

proc ::rbc::ps::CanvasToPs {} {
    variable pageInfo

    set width [expr {($pageInfo(xMax) - $pageInfo(xMin)) / $pageInfo(scale)}]
    set pageInfo(-width) [ConvertUnits $width]

    set height [expr {($pageInfo(yMax) - $pageInfo(yMin)) / $pageInfo(scale)}]
    set pageInfo(-height) [ConvertUnits $height]

    set padXL [expr {$pageInfo(xMin) / $pageInfo(scale)}]
    set padXR [expr {   ($pageInfo(paperWidth) - $pageInfo(xMax))
                      / $pageInfo(scale)}]

    set padYU [expr {$pageInfo(yMin) / $pageInfo(scale)}]
    set padYD [expr {   ($pageInfo(paperHeight) - $pageInfo(yMax))
                      / $pageInfo(scale)}]

    if {$pageInfo(-landscape)} {
	set pageInfo(-padx) "[ConvertUnits $padYU] [ConvertUnits $padYD]"
	set pageInfo(-pady) "[ConvertUnits $padXR] [ConvertUnits $padXL]"
    } else {
	set pageInfo(-padx) "[ConvertUnits $padXL] [ConvertUnits $padXR]"
	set pageInfo(-pady) "[ConvertUnits $padYU] [ConvertUnits $padYD]"
    }

    set pageInfo(-maxpect) 0

    ApplyPs
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::ApplyPs
# ------------------------------------------------------------------------------
# Converts pageInfo values to postscript options and canvas layout.
# 1. Transfer configuration from pageInfo to "$graph postscript configure" where
#    appropriate.
# 2. Copy postscript options back to pageInfo, and compute further elements of
#    pageInfo.
# 3. Convert some postscript options from pixels to in/cm
# 4. Configure the canvas to reflect these values.
# ------------------------------------------------------------------------------

proc ::rbc::ps::ApplyPs { } {
    variable pageInfo

    set graph $pageInfo(graph)
    ## puts "\n"
    if {$pageInfo(debug)} {
        # Debugging: use this 'puts' to check that ApplyPs is called whenever a
        # change made in the GUI should be converted to a change in postscript
        # options.
        puts "ApplyPs [incr ::rbc::ps::ApplyPsCounter]"
    }
    foreach option [$graph postscript configure] {
	set var [lindex $option 0]
	set old [lindex $option 4]
	## puts "$option -- $pageInfo($var)"
	lappend configKeys $var
	# Don't set -preview or -previewformat -- rbc can't do a preview
	if {($var ni "-preview -previewformat") &&
	   ([catch {$graph postscript configure $var $pageInfo($var)}] != 0)
	} {
	    $graph postscript configure $var $old
	    set pageInfo($var) $old
	}
    }
    foreach name [lsort [array names pageInfo]] {
	if {$name ni $configKeys} {
	    ## puts "$name $pageInfo($name)"
	}
    }
    ComputeCanvasGeometryFromPs $graph
    # This copies the postscript options into pageInfo, and then
    # computes pageInfo elements xMin xMax yMin yMax paperHeight paperWidth
    # The first four are canvas corners.

    # Convert these values from pixels to a Tk screen distance in inches or cm.
    # These are postscript options.
    # We pass the values to postscript configure in inches or cm, it gives them
    # back to us as pixels; we convert back to preserve the physical units.
    foreach var { -paperheight -paperwidth -width -height } {
	set pageInfo($var) [ConvertUnits $pageInfo($var)]
    }
    foreach var { -padx -pady } {
	set newVal {}
	foreach frag $pageInfo($var) {
	    lappend newVal [ConvertUnits $frag]
	}
	set pageInfo($var) $newVal
    }

    # Configure canvas items tagged "outline" - the image and its grip handles.
    AdjustCanvas $graph.top.layout
    return
}



##### (5)  Commands bound to elements of the GUI (and their dependencies)
##### (5a) Commands bound to canvas items

# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::EnterImage
# ------------------------------------------------------------------------------
# Command to add cursor-key bindings to the image.
# Bound to <Enter> on canvas item "image"
# ------------------------------------------------------------------------------

proc ::rbc::ps::EnterImage  { canvas } {
    variable cursors
    variable pageInfo
    bind $canvas <KeyPress-Left>  {
	::rbc::ps::DragMove %W [expr {$::rbc::ps::pageInfo(lastX) - 1}] \
		$::rbc::ps::pageInfo(lastY)
    }
    bind $canvas <KeyPress-Right> {
	::rbc::ps::DragMove %W [expr {$::rbc::ps::pageInfo(lastX) + 1}] \
		$::rbc::ps::pageInfo(lastY)
    }
    bind $canvas <KeyPress-Up>   {
	::rbc::ps::DragMove %W $::rbc::ps::pageInfo(lastX) \
		[expr {$::rbc::ps::pageInfo(lastY) - 1}]
    }
    bind $canvas <KeyPress-Down> {
	::rbc::ps::DragMove %W $::rbc::ps::pageInfo(lastX) \
		[expr {$::rbc::ps::pageInfo(lastY) + 1}]
    }
    focus $canvas
    $canvas configure -cursor fleur
    set pageInfo(lastX) 0
    set pageInfo(lastY) 0
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::LeaveImage
# ------------------------------------------------------------------------------
# Command to remove cursor-key bindings from the image.
# Bound to <Leave> on canvas item "image"
# ------------------------------------------------------------------------------

proc ::rbc::ps::LeaveImage { canvas } {    
    bind $canvas <KeyPress-Left> ""
    bind $canvas <KeyPress-Right> ""
    bind $canvas <KeyPress-Up> ""
    bind $canvas <KeyPress-Down> ""
    $canvas configure -cursor ""
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::EnterGrip
# ------------------------------------------------------------------------------
# Command to add cursor-key bindings to the grip.
# Bound to <Enter> on a canvas grip item.
# This is almost useless because pressing the key usually makes the pointer
# leave the grip.
# ------------------------------------------------------------------------------

proc ::rbc::ps::EnterGrip  { canvas grip x y } {
    variable cursors
    variable pageInfo
    $canvas itemconfigure $grip -fill blue -outline black
    set pageInfo(grip) $grip
    bind $canvas <KeyPress-Left>  {
	::rbc::ps::DragResize %W [expr {$::rbc::ps::pageInfo(lastX) - 1}] \
                $::rbc::ps::pageInfo(lastY)
    }
    bind $canvas <KeyPress-Right> {
	::rbc::ps::DragResize %W [expr {$::rbc::ps::pageInfo(lastX) + 1}] \
                $::rbc::ps::pageInfo(lastY)
    }
    bind $canvas <KeyPress-Up> {
	::rbc::ps::DragResize %W $::rbc::ps::pageInfo(lastX) \
		[expr {$::rbc::ps::pageInfo(lastY) - 1}]
    }
    bind $canvas <KeyPress-Down> {
	::rbc::ps::DragResize %W $::rbc::ps::pageInfo(lastX) \
		[expr {$::rbc::ps::pageInfo(lastY) + 1}]
    }
    focus $canvas
    $canvas configure -cursor $cursors($grip)
    set pageInfo(lastX) $x
    set pageInfo(lastY) $y
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::LeaveGrip
# ------------------------------------------------------------------------------
# Command to remove cursor-key bindings from the grip.
# Bound to <Leave> on a grip item.
# ------------------------------------------------------------------------------

proc ::rbc::ps::LeaveGrip { canvas grip } {    
    $canvas itemconfigure $grip -fill red -outline black
    bind $canvas <KeyPress-Left> ""
    bind $canvas <KeyPress-Right> ""
    bind $canvas <KeyPress-Up> ""
    bind $canvas <KeyPress-Down> ""
    $canvas configure -cursor ""
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::StartMove
# ------------------------------------------------------------------------------
# Command to begin a "Move" operation on the canvas items tagged "outline".
# Those items are the image and its grips.
# Bound to <ButtonPress-1> on the image.
# ------------------------------------------------------------------------------

proc ::rbc::ps::StartMove { canvas x y } {
    variable pageInfo
    set pageInfo(lastX) $x
    set pageInfo(lastY) $y
    set pageInfo(direction) "undecided"
    $canvas configure -cursor fleur
    $pageInfo(graph).top.move invoke
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::DragMove
# ------------------------------------------------------------------------------
# Command to increment a "Move" operation on the canvas items tagged "outline".
# Those items are the image and its grips.
# Bound to <B1-Motion> on the image.
# ------------------------------------------------------------------------------

proc ::rbc::ps::DragMove { canvas x y } {
    variable pageInfo
    $canvas move outline \
            [expr {$x - $pageInfo(lastX)}] [expr {$y - $pageInfo(lastY)}]
    set pageInfo(lastX) $x
    set pageInfo(lastY) $y
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::DragMoveBut
# ------------------------------------------------------------------------------
# Command to increment a "Move" operation on the canvas items tagged "outline".
# The move is constrained to up/down or left/right only.
# Those items are the image and its grips.
# Bound to <Shift-B1-Motion> on the image.
# ------------------------------------------------------------------------------

proc ::rbc::ps::DragMoveBut { canvas x y } {
    variable pageInfo

    set dx [expr {$x - $pageInfo(lastX)}]
    set dy [expr {$y - $pageInfo(lastY)}]

    if { $pageInfo(direction) == "undecided" } {
	if { abs($dx) > abs($dy) } {
	    set pageInfo(direction) x
	    $canvas configure -cursor sb_h_double_arrow
	} else {
	    set pageInfo(direction) y
	    $canvas configure -cursor sb_v_double_arrow
	}
    }
    switch $pageInfo(direction) {
	x { set dy 0 ; set pageInfo(lastX) $x } 
	y { set dx 0 ; set pageInfo(lastY) $y }
    }
    $canvas move outline $dx $dy
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::EndMove
# ------------------------------------------------------------------------------
# Command to end a "Move" operation on the canvas items tagged "outline".
# Those items are the image and its grips.
# Bound to <ButtonRelease-1> on the image.
# ------------------------------------------------------------------------------

proc ::rbc::ps::EndMove { canvas } {
    variable pageInfo

    $canvas configure -cursor ""

    set coords [$canvas coords image]
    set x [lindex $coords 0]
    set y [lindex $coords 1]
    set w [image width  [$canvas itemcget image -image]]
    set h [image height [$canvas itemcget image -image]]

    set pageInfo(xMin) $x
    set pageInfo(yMin) $y
    set pageInfo(xMax) [expr {$x + $w}]
    set pageInfo(yMax) [expr {$y + $h}]

    CanvasToPs
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::StartResize
# ------------------------------------------------------------------------------
# Command to begin a "Resize" operation on the canvas items tagged "outline".
# Those items are the image and its grips.
# Bound to <ButtonPress-1> on a grip.
# ------------------------------------------------------------------------------

proc ::rbc::ps::StartResize { canvas grip x y } {
    variable cursors
    variable pageInfo
    set pageInfo(grip) $grip
    $canvas itemconfigure $grip -fill red -outline black 
    $canvas raise grip
    $canvas configure -cursor $cursors($grip)
    set pageInfo(lastX) $x
    set pageInfo(lastY) $y
    $pageInfo(graph).top.resize invoke
    $pageInfo(graph).top.move invoke
    destroy $pageInfo(graph).top.plotsize
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::EndResize
# ------------------------------------------------------------------------------
# Command to end a "Resize" operation on the canvas items tagged "outline".
# Those items are the image and its grips.
# Bound to <ButtonRelease-1> on a grip.
# ------------------------------------------------------------------------------

proc ::rbc::ps::EndResize { canvas grip x y } {
    $canvas itemconfigure $grip -fill "" -outline ""
    $canvas configure -cursor ""
    CanvasToPs
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::DragResize
# ------------------------------------------------------------------------------
# Command to increment a "Resize" operation on the canvas items tagged
# "outline".
# Those items are the image and its grips.
# Bound to <B1-Motion> on a grip.
# ------------------------------------------------------------------------------

proc ::rbc::ps::DragResize { canvas x y } {
    variable pageInfo

    foreach var { gripSize xMin yMin xMax yMax } {
	set $var $pageInfo($var)
    }
    set buff [expr {$gripSize * 5}]
    switch $pageInfo(grip) {
	n {
	    if {$y < $yMax - $buff} {set yMin $y}
	}
	s {
	    if {$y > $yMin + $buff} {set yMax $y}
	}
	e {
	    if {$x > $xMin + $buff} {set xMax $x}
	}
	w {
	    if {$x < $xMax - $buff} {set xMin $x}
	}
	sw {
	    if {$x < $xMax - $buff} {set xMin $x}
	    if {$y > $yMin + $buff} {set yMax $y}
	}
	ne {
	    if {$x > $xMin + $buff} {set xMax $x}
	    if {$y < $yMax - $buff} {set yMin $y}
	}
	se {
	    if {$x > $xMin + $buff} {set xMax $x}
	    if {$y > $yMin + $buff} {set yMax $y}
	}
	nw {
	    if {$x < $xMax - $buff} {set xMin $x}
	    if {$y < $yMax - $buff} {set yMin $y}
	}
    }

    set width  [expr {$xMax - $xMin}]
    set height [expr {$yMax - $yMin}]
    if { ($width < 1) || ($height < 1) } {
	return
    }

    foreach var { xMin yMin xMax yMax } {
	set pageInfo($var) [set $var]
    }

    AdjustCanvas $canvas
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::DragResizeBut
# ------------------------------------------------------------------------------
# Command to increment a "Resize" operation on the canvas items tagged
# "outline".
# The resize is constrained by preserving the graph's aspect ratio.
# Those items are the image and its grips.
# Bound to <Shift-B1-Motion> on a grip.
# ------------------------------------------------------------------------------

proc ::rbc::ps::DragResizeBut { canvas x y } {
    variable pageInfo

    foreach var { graph gripSize xMin yMin xMax yMax } {
	set $var $pageInfo($var)
    }
    set buff [expr {$gripSize * 5}]
    set aspect [expr {
	[winfo fpixels $graph [$graph cget -height]]
      / [winfo fpixels $graph [$graph cget -width]]
    }]
    switch $pageInfo(grip) {
	nw -
	n {
	    set newX [expr {$xMax - ($yMax - $y) / $aspect}]
	    if {($y < $yMax - $buff) && ($newX < $xMax - $buff)} {
		set yMin $y
		set xMin $newX
	    }
	}
	se -
	s {
	    set newX [expr {$xMin + ($y - $yMin) / $aspect}]
	    if {($y > $yMin + $buff) && ($newX > $xMin + $buff)} {
		set yMax $y
		set xMax $newX
	    }
	}
	e {
	    set newY [expr {$yMin + ($x - $xMin) * $aspect}]
	    if {($newY > $yMin + $buff) && ($x > $xMin + $buff)} {
		set xMax $x
		set yMax $newY
	    }
	}
	w {
	    set newY [expr {$yMax - ($xMax - $x) * $aspect}]
	    if {($newY < $yMax - $buff) && ($x < $xMax - $buff)} {
		set xMin $x
		set yMin $newY
	    }

	}
	sw {
	    set newX [expr {$xMax - ($y - $yMin) / $aspect}]
	    if {($y > $yMin + $buff) && ($newX < $xMax - $buff)} {
		set yMax $y
		set xMin $newX
	    }
	}
	ne {
	    set newX [expr {$xMin + ($yMax - $y) / $aspect}]
	    if {($y < $yMax - $buff) && ($newX > $xMin + $buff)} {
		set yMin $y
		set xMax $newX
	    }
	}
    }

    set width  [expr {$xMax - $xMin}]
    set height [expr {$yMax - $yMin}]
    if { ($width < 1) || ($height < 1) } {
	return
    }

    foreach var { xMin yMin xMax yMax } {
	set pageInfo($var) [set $var]
    }

    AdjustCanvas $canvas
    return
}



##### (5b) Commands bound to GUI elements other than the canvas, and not posting
#####      a toplevel.


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::PrintPs
# ------------------------------------------------------------------------------
# Command to "Print" the graph to a file, write a message to stdout, and close
# the "PostScript Options" dialog toplevel.
#
# Notes.
# - Bound to the "Print" button in the main dialog.
# - Not called from anywhere else.
# - pageInfo(printFile) is the -textvariable for the entry widget.
# ------------------------------------------------------------------------------

proc ::rbc::ps::PrintPs { graph top } {
    variable pageInfo
    BusyAndPrint $graph $pageInfo(printFile)
    catch {puts stdout "wrote file \"$pageInfo(printFile)\"."}
    catch {flush stdout}
    if {$pageInfo(debug)} {
        # Keep the dialog open for further experimentation.
    } else {
        destroy $top
    }
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::BusyAndPrint
# ------------------------------------------------------------------------------
# Command to print a graph by evaluating "$graph postscript output $psFile", but
# wrapped with a "busy" indicator.
#
# - Called only from PrintPs
#
# FIXME deal with recursive grabs.
# ------------------------------------------------------------------------------

proc ::rbc::ps::BusyAndPrint {graph psFile} {
    ### FIXME rbc - rbc::busy segfaults, so instead use a grab.
    ### This gives a "busy" warning and also prevents the user+GUI
    ### from changing the graph while it is printing.
    ###rbc::busy hold .
    set lab $graph.temporaryLabelInRbcPsTclPrint
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
#  Proc ::rbc::ps::SetPaperSize
# ------------------------------------------------------------------------------
# Bound to radiobuttons in the main dialog that set pageInfo(paperSize) to a
# list of two values {width height} expressed in the unit (i or c) that is
# passed as the argument to this command.
# ------------------------------------------------------------------------------

proc ::rbc::ps::SetPaperSize { unit } {
    variable pageInfo
    SetUnits $unit
    set pageInfo(-paperwidth)  [lindex $pageInfo(paperSize) 0]
    set pageInfo(-paperheight) [lindex $pageInfo(paperSize) 1]
    ApplyPs
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::SetPlotSize
# ------------------------------------------------------------------------------
# Bound to the "Default" and "Max Aspect" radiobuttons in the main dialog.
# ------------------------------------------------------------------------------

proc ::rbc::ps::SetPlotSize { } {
    variable pageInfo
    set graph $pageInfo(graph)
    destroy $graph.top.plotsize
    switch $pageInfo(plotSize) {
	default { 
	    set pageInfo(-width) 0
	    set pageInfo(-height) 0 
	    set pageInfo(-maxpect) 0
	    set pageInfo(-padx) $pageInfo(oldPadX)
	    set pageInfo(-pady) $pageInfo(oldPadY)
	} maxpect { 
	    set pageInfo(-width) 0
	    set pageInfo(-height) 0
	    set pageInfo(-maxpect) 1
	    set pageInfo(-padx) $pageInfo(oldPadX)
	    set pageInfo(-pady) $pageInfo(oldPadY)
	} resize {
	    set pageInfo(-maxpect) 0
	}
    }
    ApplyPs
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::CenterPlot
# ------------------------------------------------------------------------------
# Bound to the "Center" radiobutton in the main dialog
# ------------------------------------------------------------------------------

proc ::rbc::ps::CenterPlot { } {
    variable pageInfo
    set pageInfo(-padx) $pageInfo(oldPadX)
    set pageInfo(-pady) $pageInfo(oldPadY)
    ApplyPs
    return
}



##### (5c) Commands bound to GUI elements other than the canvas, that post a
#####      secondary dialog in its own toplevel.


### Secondary Toplevel Dialogs - these are children of the main dialog.
### Dialog values are thrown away if the user clicks the "Cancel" button.
### Temporary variables are used for radiobuttons etc, with values copied from
### the permanent variable when the dialog is launched, and copied back iff the
### user selects "OK".
###
### These dialogs all change pageInfo(-*) and so call ApplyPs to effect the
### change.

# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::DialogFinish
# ------------------------------------------------------------------------------
# Called by secondary toplevel dialogs when the user clicks "OK".
# 1. Copy values from "temporary" to "permanent" elements of pageInfo
# 2. Call ApplyPs
# 3. Destroy the dialog toplevel
# Usage: DialogFinish top ?from to ...?
# ------------------------------------------------------------------------------

proc ::rbc::ps::DialogFinish { top args } {
    variable pageInfo
    if {([llength $args]%2)} {
	# args has odd number of elements
	# with top, total number is even
	return -code error {odd number of arguments needed}
    }
    foreach {from to} $args {
	set pageInfo($to) $pageInfo($from)
    }

    ApplyPs
    destroy $top
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::SizeDialog
# ------------------------------------------------------------------------------
# Toplevel dialog to set the size of the image using entry widgets with
# up/down adjusters.
# Bound to the "Resize" radiobutton in the main dialog.
# ------------------------------------------------------------------------------

proc ::rbc::ps::SizeDialog { graph title } {
    variable pageInfo

    set top $graph.top.plotsize
    if { [winfo exists $top] } {
	return
    }

    set width  [winfo fpixels $graph $pageInfo(-width)]
    set height [winfo fpixels $graph $pageInfo(-height)]
    if { $width == 0 } {
	set width [expr {   ($pageInfo(xMax) - $pageInfo(xMin))
                          / $pageInfo(scale)}]
	set pageInfo(-width) [ConvertUnits $width]
    }
    if { $height == 0 } {
	set height [expr {   ($pageInfo(yMax) - $pageInfo(yMin))
                           / $pageInfo(scale)}]
	set pageInfo(-height) [ConvertUnits $height]
    }
    set pageInfo(-maxpect) 0

    toplevel $top
    label $top.title -text $title
    button $top.cancel -text "Cancel" -command "destroy $top"
    button $top.ok -text "OK" -command [list ::rbc::ps::DialogFinish $top \
	    TmpWidth -width TmpHeight -height \
    ]
    MakeSizeAdjuster $top.plotWidth  "Width"  TmpWidth  -width
    MakeSizeAdjuster $top.plotHeight "Height" TmpHeight -height

    grid $top.title -columnspan 2
    grid $top.plotWidth $top.plotHeight
    grid $top.cancel $top.ok -pady {10 4} -padx 4 -ipadx 10
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::PaperSizeDialog
# ------------------------------------------------------------------------------
# Unused toplevel dialog - to set a custom paper size.
# If used, needs a fix to convert initial values from pixels.
# ------------------------------------------------------------------------------

proc ::rbc::ps::PaperSizeDialog { title } {
    variable pageInfo
    set top $pageInfo(graph).top.papersize

    if { [winfo exists $top] } {
	return
    }

    toplevel $top
    label $top.title -text $title
    MakeSizeAdjuster $top.width  "Width"  TmpPaperWidth  -paperwidth
    MakeSizeAdjuster $top.height "Height" TmpPaperHeight -paperheight
    button $top.cancel -text "Cancel" -command "destroy $top"
    button $top.ok -text "OK" -command [list ::rbc::ps::DialogFinish $top \
	    TmpPaperWidth  -paperwidth TmpPaperHeight -paperheight \
    ]

    grid $top.title -columnspan 2
    grid $top.width $top.height
    grid $top.cancel $top.ok -pady {10 4} -padx 4 -ipadx 10
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::OptionsDialog
# ------------------------------------------------------------------------------
# A toplevel dialog to set printer color|greyscale, preview yes|no
# Bound to the "Options" button in the main dialog.
# ------------------------------------------------------------------------------

proc ::rbc::ps::OptionsDialog { graph } {
    variable pageInfo

    set top $graph.top.options
    if { [winfo exists $top] } {
	return
    }
    toplevel $top

    set pageInfo(TmpColorMode) $pageInfo(-colormode)
    set pageInfo(TmpPreview)   $pageInfo(-preview)

    set row 0
    label $top.modeLabel -text "Printer"
    radiobutton $top.color -text "Color" -value "color" \
	-variable ::rbc::ps::pageInfo(TmpColorMode)
    radiobutton $top.greyscale -text "Greyscale" -value "greyscale" \
	-variable ::rbc::ps::pageInfo(TmpColorMode)

    grid $top.modeLabel -sticky e -row $row -column 0 -pady { 4 0 }
    grid $top.color     -sticky w -row $row -column 1
    incr row
    grid $top.greyscale -sticky w -row $row -column 1
    incr row -1

    # RBC has no EPS preview, so this is disabled.
    # Even if enabled, ApplyPs reverses any changes so that
    # "$graph postscript configure" does not raise an error.
    label $top.previewLabel -text "Preview" -state disabled
    radiobutton $top.previewYes -text "Yes" -value "1" \
	-variable ::rbc::ps::pageInfo(TmpPreview) -state disabled
    radiobutton $top.previewNo -text "No" -value "0" \
	-variable ::rbc::ps::pageInfo(TmpPreview) -state disabled

    grid $top.previewLabel -sticky e -row $row -column 2
    grid $top.previewYes   -sticky w -row $row -column 3
    incr row
    grid $top.previewNo    -sticky w -row $row -column 3
    incr row

    button $top.cancel -text "Cancel" -command "destroy $top"
    button $top.ok -text "OK" -command [list ::rbc::ps::DialogFinish $top \
	    TmpColorMode -colormode TmpPreview -preview \
    ]

    grid $top.cancel -pady 4 -padx 4  -row $row -column 0
    grid $top.ok     -pady 4 -padx 4  -row $row -column 1
    return
}    



##### (6) The "Size Adjuster" megawidget used in the secondary dialog toplevels
#####     PaperSizeDialog and SizeDialog.

# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::MakeSizeAdjuster
# ------------------------------------------------------------------------------
# Command to construct a megawidget $w for adjusting the value of a
# Tk distance.
# w           - the Tk window path of the megawidget
# label       - text for descriptive label at the top of the megawidget
# var         - name of the element of pageInfo to use as the entry widget's
#               -textvariable
# initVar     - name of the element of pageInfo whose value will be used to
#               initialize pageInfo($var).
# Return Value: the Tk window path of the megawidget
# ------------------------------------------------------------------------------

proc ::rbc::ps::MakeSizeAdjuster { w label var initVar} {
    variable pageInfo

    set pageInfo($var) $pageInfo($initVar)

    set u2t {
	c    {cm }
	i    {in }
	m    {mm }
	p    {pt }
    }
    if {[string index $pageInfo($var) end] in {c i m p}} {
	set units [string index $pageInfo($var) end]
	set txt [dict get $u2t $units]
    } else {
	set units {}
	set txt   pix
    }

    frame $w
    label $w.label -text $label
    button $w.plus -image ::rbc::ps::up -padx 1 -pady 0 -font TkFixedFont
    entry $w.entry \
	    -width 6 \
	    -font TkFixedFont \
	    -bg white \
	    -textvariable ::rbc::ps::pageInfo($var)

    button $w.minus -image ::rbc::ps::down -padx 1 -pady 0 -font TkFixedFont
    label $w.units -text $txt
    bind $w.plus <ButtonPress-1>  { ::rbc::ps::StartChange %W 0.1}
    bind $w.plus <ButtonRelease-1> { ::rbc::ps::EndChange %W }
    bind $w.minus <ButtonPress-1>  { ::rbc::ps::StartChange %W -0.1}
    bind $w.minus <ButtonRelease-1> { ::rbc::ps::EndChange %W }

    grid $w.label -row 0 -column 1
    grid $w.entry -row 1 -column 1 -rowspan 2
    grid $w.plus  -row 1 -column 0 -padx 2 -pady 2
    grid $w.minus -row 2 -column 0 -padx 2 -pady { 0 2 }
    grid $w.units -row 1 -column 2 -rowspan 2 -sticky ns
    return $w
}


##### (7) Dependencies of the "Size Adjuster" widget created by
#####     MakeSizeAdjuster.

# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::ChangeSize
# ------------------------------------------------------------------------------
# Command to increment/decrement the value managed by a "Size Adjuster".
# ------------------------------------------------------------------------------

proc ::rbc::ps::ChangeSize { w delta } {
    set f [winfo parent $w]
    set value [$f.entry get]
    if {[string index $value end] in {c i m p}} {
	set units [string index $value end]
	set value [string range $value 0 end-1]
    } else {
	set units {}
    }
    set value [expr {$value + $delta}]
    if { $value < 0 } {
	set value 1
    }
    $f.entry delete 0 end
    $f.entry insert 0 $value$units
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::StartChange
# ------------------------------------------------------------------------------
# Command to increment/decrement the value managed by a "Size Adjuster", and
# initialize further increments/decrements after 300ms.
# Bound to <ButtonPress-1> on an up/down button.
# ------------------------------------------------------------------------------

proc ::rbc::ps::StartChange { w delta } {
    variable pageInfo
    ChangeSize $w $delta
    set pageInfo(afterId) [after 300 ::rbc::ps::RepeatChange $w $delta]
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::RepeatChange
# ------------------------------------------------------------------------------
# Command to increment/decrement the value managed by a "Size Adjuster", and
# initialize further increments/decrements after 100ms.
# Called by an event launched by StartChange or RepeatChange itself.
# ------------------------------------------------------------------------------

proc ::rbc::ps::RepeatChange { w delta } {
    variable pageInfo
    ChangeSize $w $delta
    set pageInfo(afterId) [after 100 ::rbc::ps::RepeatChange $w $delta]
    return
}


# ------------------------------------------------------------------------------
#  Proc ::rbc::ps::EndChange
# ------------------------------------------------------------------------------
# Command to stop further repeats of increment/decrement to the 
# Bound to <ButtonRelease-1> on an up/down button.
# ------------------------------------------------------------------------------

proc ::rbc::ps::EndChange { w } {
    variable pageInfo
    after cancel $pageInfo(afterId)
    return
}
