# ------------------------------------------------------------------------------
#  RBC Demos - file demos/scripts/graph3.tcl
# ------------------------------------------------------------------------------
#  This file is a script fragment that is sourced by the demo
#  demos/graph3.tcl
#
# (1) Set values for use as option defaults for graph elements
# (2) Define and compute the vectors
# (3) Add elements to the graph
# ------------------------------------------------------------------------------


### (1) Set values for use as option defaults for graph elements

set configOptions {
    Element.Pixels		1.75m
    Element.ScaleSymbols	yes
}

set resName [string trimleft $graph .]
foreach { option value } $configOptions {
    option add *$resName.$option $value
}


### (2) Define and compute the vectors

set tcl_precision 15
set pi1_2 [expr 3.14159265358979323846/180.0]

vector create x sinX cosX -variable ""
x seq -360 360 5
sinX expr { sin(x*$pi1_2) }
cosX expr { cos(x*$pi1_2) }


### (3) Add elements to the graph

$graph element create line1 \
    -label "sin(x)" \
    -fill orange \
    -color black \
    -x x \
    -y sinX  
$graph element create line2 \
    -label "cos(x)" \
    -color yellow4 \
    -fill yellow \
    -x x \
    -y cosX 




### The code below is not executed and is not part of the demo.
### It remains available for experimentation.

### (1) Unused options

if 0 {

proc FormatAxisLabel {graph x} {
     return "[expr int($x)]\260"
}


set configOptions [subst {
    Axis.Hide			no
    Axis.Limits			"%g"
    Axis.TickFont		{ helvetica 12 bold }
    Axis.TitleFont		{ helvetica 12 bold }
    BorderWidth			1
    Font			{ helvetica 23 bold }
    Legend.ActiveBorderWidth	2
    Legend.ActiveRelief		raised
    Legend.Anchor		ne
    Legend.BorderWidth		0
    Legend.Font			{ Helvetica 24 }
    Legend.Position		plotarea
    Relief			sunken
    Title			"Sine and Cosine Functions" 
    x.Command			[namespace current]::FormatAxisLabel
    x.StepSize			90 
    x.Subdivisions		0 
    x.Title			"X" 
    y.Color			purple2
    y.Loose			no
    y.Title			"Y" 
    y.rotate			90 
    y2.color			magenta3
}]


$graph configure -leftvar changed

}
