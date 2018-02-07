# ------------------------------------------------------------------------------
#  RBC Demos - file demos/scripts/graph2.tcl
# ------------------------------------------------------------------------------
#  This file is a script fragment that is sourced by the demo
#  demos/graph2.tcl
#
# (1) Set values for use as option defaults for the graph and its components
# (2) Configure the graph
# (3) Define and compute the vectors
# (4) Add elements to the graph
# ------------------------------------------------------------------------------

### (1) Set values for use as option defaults for the graph and its components

set configOptions {
    Axis.TickFont		{ Helvetica 14 bold }
    Axis.TitleFont		{ Helvetica 12 bold }

    Element.Pixels		8
    Element.ScaleSymbols	true
    Element.Smooth		cubic

    degrees.Command		FormatAxisLabel
    degrees.LimitsFormat	"Deg=%g"
    degrees.Subdivisions	0 
    degrees.Title		"Degrees" 
    degrees.stepSize		90 
}


set resource [string trimleft $graph .]
foreach { option value } $configOptions {
    option add *$resource.$option $value
}


proc FormatAxisLabel {graph x} {
     ### FIXME rbc - on X11, "graph" does not render the degree sign correctly.
     ### This formula returns the integer followed by the Unicode character for the degree sign.
     format "%d%c" [expr int($x)] 0xB0
}


### (2) Configure the graph
### (2a) create and configure graph pens and styles

set max -1.0
set step 0.2

set letters { A B C D E F G H I J K L }
set count 0
for { set level 30 } { $level <= 100 } { incr level 10 } {
    set color [format "#dd0d%0.2x" [expr round($level*2.55)]]
    set pen "pen$count"
    ### No bitmap command in rbc - so
    ### use "-symbol circle" instead of "-symbol $symbol"
    ### set symbol "symbol$count"
    ### bitmap compose $symbol [lindex $letters $count] \
    ###	-font -*-helvetica-medium-r-*-*-34-*-*-*-*-*-*-*
    $graph pen create $pen \
	-color $color \
	-symbol circle \
	-fill "" \
	-pixels 13
    set min $max
    set max [expr $max + $step]
    lappend styles "$pen $min $max"
    incr count
}


### (2b) Create and configure graph axes
$graph axis create degrees \
    -rotate 90
$graph xaxis use degrees


### (2c) Configure graph size and PostScript properties

$graph postscript configure \
    -maxpect yes \
    -landscape yes 
$graph configure \
    -width 5i \
    -height 5i 


### (3) Define and compute the vectors

set tcl_precision 15
set pi1_2 [expr 3.14159265358979323846/180.0]

vector create w x sinX cosX radians
x seq -360.0 360.0 10.0
#x seq -360.0 -180.0 30.0
radians expr { x * $pi1_2 }
sinX expr sin(radians)
cosX expr cos(radians)
cosX dup w
vector destroy radians

vector create xh xl yh yl
set pct [expr ($cosX(max) - $cosX(min)) * 0.025]
yh expr {cosX + $pct}
yl expr {cosX - $pct}
set pct [expr ($x(max) - $x(min)) * 0.025]
xh expr {x + $pct}
xl expr {x - $pct}


### (4) Add elements to the graph
set bitmap [file join $DemoDir bitmaps hobbes.xbm]
set mask   [file join $DemoDir bitmaps hobbes_mask.xbm]

$graph element create line3 \
    -color green4 \
    -fill green \
    -label "cos(x)" \
    -mapx degrees \
    -styles $styles \
    -weights w \
    -x x \
    -y cosX \
    -yhigh yh -ylow yl

$graph element create line1 \
    -color orange \
    -outline black \
    -fill orange \
    -fill yellow \
    -label "sin(x)" \
    -linewidth 3 \
    -mapx degrees \
    -pixels 6m \
    -symbol [list @$bitmap @$mask] \
    -x x \
    -y sinX 





### The code below is not executed and is not part of the demo.
### It remains available for experimentation.


### This was in the original demo, but the axis was not used - only the
### limits labels were plotted, which was a bit confusing.
if 0 {

lappend configOptions [subst {
    temp.LimitsFormat		"Temp=%g"
    temp.Title			"Temperature"
}]

$graph axis create temp \
    -color lightgreen \
    -title Temp

}




### The code below is not executed and is not part of the demo.
### It remains available for experimentation.

### (1) Unused options
### The original BLT demo used these options.  Mostly they are experimental,
### and do not apply to the previously created graph.
### The values that do apply are copied above.

if 0 {

option add *HighlightThickness		0
option add *Tile			bgTexture
option add *Button.Tile			""

image create photo bgTexture -file $DemoDir/images/chalk.gif


if { ![string match "*gray*" [winfo screenvisual .]] } {
    option add *Button.Background	red
    option add *TextMarker.Foreground	black
    option add *TextMarker.Background	yellow
    option add *LineMarker.Foreground	black
    option add *LineMarker.Background	yellow
    option add *PolyMarker.Fill		yellow2
    option add *PolyMarker.Outline	""
    option add *PolyMarker.Stipple	bdiagonal1
    option add *activeLine.Color	red4
    option add *activeLine.Fill		red2
    option add *Element.Color		purple
}


set configOptions [subst {
    InvertXY			no
    Axis.TickFont		{ Helvetica 14 bold }
    Axis.TitleFont		{ Helvetica 12 bold }
    BorderWidth			2

    Element.Pixels		8
    Element.ScaleSymbols	true
    Element.Smooth		cubic

    Font			{ Helvetica 18 bold }
    Foreground			white
    Legend.ActiveBorderWidth	2
    Legend.ActiveRelief		raised
    Legend.Anchor		ne
    Legend.BorderWidth		0
    Legend.Font			{ Helvetica 34 }
    Legend.Foreground		orange
    #Legend.Position		plotarea
    Legend.Hide			yes
    Legend.Relief		flat
    Postscript.Preview		yes
    Relief			raised
    Shadow			{ navyblue 2 }
    Title			"Bitmap Symbols" 

    degrees.Command		[namespace current]::FormatAxisLabel
    degrees.LimitsFormat	"Deg=%g"
    degrees.Subdivisions	0 
    degrees.Title		"Degrees" 
    degrees.stepSize		90 
    temp.LimitsFormat		"Temp=%g"
    temp.Title			"Temperature"

    y.Color			purple2
    y.LimitsFormat		"Y=%g"
    y.Rotate			90 
    y.Title			"Y" 
    y.loose			no
    y2.Color			magenta3
    y2.Hide			no
    xy2.Rotate			270
    y2.Rotate			0
    y2.Title			"Y2" 
    y2.LimitsFormat		"Y2=%g"
    x2.LimitsFormat		"x2=%g"
}]

}
