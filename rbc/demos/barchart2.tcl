#!/bin/sh

# ------------------------------------------------------------------------------
#  RBC Demo barchart2.tcl
#
#  A barchart showing different ways to plot multiple data sets.
# ------------------------------------------------------------------------------
# restart using wish \
exec wish "$0" "$@"

package require rbc
namespace import rbc::*

### The script can be run from any location.
### It loads the files it needs from the demo directory.
set DemoDir [file normalize [file dirname [info script]]]


### Load common commands and create non-rbc GUI elements.
source $DemoDir/scripts/common.tcl

proc CustomHeader {w graph} {
    frame $w

    text $w.title -wrap word -width 0 -height 4 -relief flat -highlightthickness 0 -padx 15 -pady 5
    $w.title insert end [MakeLine {
        |Data points with like x-coordinates, can have their bar segments
        |displayed in one of the following modes (using the -barmode option):
    }]
    $w.title configure -state disabled
    bind $w.title <Configure> {AdjustHeight %W 20}

    radiobutton $w.stacked -text stacked -variable barMode \
        -anchor w -value "stacked" -command {
        $graph configure -barmode $barMode
    } 

    label $w.stackedlabel -justify left -text [MakeLine {
        |Bars are stacked on top of each other.
        |The overall height is the sum of the y-coordinates.
    }]

    radiobutton $w.aligned -text aligned -variable barMode \
        -anchor w -value "aligned" -command {
            $graph configure -barmode $barMode
    }

    label $w.alignedlabel -justify left -text [MakeLine {
        |Bars are drawn side-by-side at a fraction of their normal width.
    }]

    radiobutton $w.overlap -text "overlap" -variable barMode \
        -anchor w -value "overlap" -command {
        $graph configure -barmode $barMode
    } 

    label $w.overlaplabel -justify left -text {Bars overlap slightly.}


    radiobutton $w.normal -text "normal" -variable barMode \
        -anchor w -value "normal" -command {
        $graph configure -barmode $barMode
    } 

    label $w.normallabel -justify left \
            -text {Bars are overlayed one on top of the next.}

    grid $w.title -columnspan 2     -sticky ew
    grid $w.stacked $w.stackedlabel -sticky w
    grid $w.aligned $w.alignedlabel -sticky w
    grid $w.overlap $w.overlaplabel -sticky w
    grid $w.normal  $w.normallabel  -sticky w -pady {0 20}

    grid configure $w.stackedlabel $w.alignedlabel $w.overlaplabel \
            $w.normallabel -padx {20 0}
    return $w
}
set barMode stacked

set graph .graph
CustomHeader .header $graph
CommonFooter .footer $DemoDir IMG


### Set options for barchart.
### Both kinds of font description work on win32 and both fail on x11.
### The X11-legacy font descriptions are left intact where they are used in the other demos.
if 1 {
    option add *Barchart.font		-*-helvetica-bold-r-*-*-14-*-*
    option add *Axis.tickFont		-*-helvetica-medium-r-*-*-12-*-*
    option add *Axis.titleFont		-*-helvetica-bold-r-*-*-12-*-*
    option add *Legend.Font		-*-helvetica*-bold-r-*-*-12-*-*
} else {
    option add *Barchart.font		{ Helvetica -14 bold }
    option add *Axis.tickFont		{ Helvetica -12 }
    option add *Axis.titleFont		{ Helvetica -12 bold }
    option add *Legend.Font		{ Helvetica -12 bold }
}

# image create photo bgTexture -file $DemoDir/images/chalk.gif
image create photo bgTexture -file $DemoDir/images/rain.gif

option add *tile			bgTexture

option add *Barchart.title		"Comparison of Simulators"

option add *x.Command			FormatXTicks
option add *x.Title			"Simulator"

option add *y.Title			"Time (hrs)"

option add *activeBar.Foreground	pink
option add *activeBar.stipple		@$DemoDir/stipples/dot3.xbm
option add *Element.Background		red
option add *Element.Relief		solid

option add *Grid.dashes			{ 2 4 }
option add *Grid.hide			no
option add *Grid.mapX			""

option add *Legend.activeBorderWidth	2 
option add *Legend.activeRelief		raised 
option add *Legend.anchor		ne 
option add *Legend.borderWidth		0 
option add *Legend.position		right
option add *Legend.background		white

proc FormatXTicks { w value } {

    # Determine the element name from the value

    set index [expr round($value)]
    if { $index != $value } {
	return $value 
    }
    incr index -1

    set name [lindex { A1 B1 A2 B2 C1 D1 C2 A3 E1 } $index]
    return $name
}


### Create the barchart.

barchart $graph -tile bgTexture 


### Define vectors and their contents.

vector create X Y0 Y1 Y2 Y3 Y4

X set { 1 2 3 4 5 6 7 8 9 }
Y0 set { 
    0.729111111  0.002250000  0.09108333  0.006416667  0.026509167 
    0.007027778  0.1628611    0.06405278  0.08786667  
}
Y1 set {
    0.003120278	 0.004638889  0.01113889  0.048888889  0.001814722
    0.291388889  0.0503500    0.13876389  0.04513333 
}
Y2 set {
    11.534444444 3.879722222  4.54444444  4.460277778  2.334055556 
    1.262194444  1.8009444    4.12194444  3.24527778  
}
Y3 set {
    1.015750000  0.462888889  0.49394444  0.429166667  1.053694444
    0.466111111  1.4152500    2.17538889  2.55294444 
}
Y4 set {
    0.022018611  0.516333333  0.54772222  0.177638889  0.021703889 
    0.134305556  0.5189278    0.07957222  0.41155556  
}


### Add elements to the barchart.
#
# Element attributes:  
#
#    Label     yData	Foreground	Background	Stipple	    Borderwidth
set attributes { 
    "Setup"	Y1	green3		green1		fdiagonal1	1
    "Read In"	Y0	lightgoldenrod3	lightgoldenrod1	bdiagonal1	1
    "Other"	Y4	lightpink3	lightpink1	fdiagonal1	1
    "Solve"	Y3	cyan3		cyan1		bdiagonal1	1
    "Load"	Y2	lightblue3	lightblue1	fdiagonal1	1
}

foreach {label yData fg bg stipple bd} $attributes {
    $graph element create $yData -label $label -bd $bd \
	-y $yData -x X -fg "" -bg $bg -stipple @$DemoDir/stipples/${stipple}.xbm
}


### Initial configuration.

$graph configure -barmode $barMode


### Map everything, add Rbc_* commands and bindings.

grid .header -sticky ew
grid $graph  -sticky nsew
grid .footer -sticky ew

grid columnconfigure . 0 -weight 1
grid    rowconfigure . 1 -weight 1


Rbc_ZoomStack $graph
Rbc_Crosshairs $graph
Rbc_ActiveLegend $graph
Rbc_ClosestPoint $graph


$graph marker bind all <B2-Motion> {
    set coords [%W invtransform %x %y]
    catch { %W marker configure [%W marker get current] -coords $coords }
}

$graph marker bind all <Enter> {
    set marker [%W marker get current]
    catch { %W marker configure $marker -bg green}
}

$graph marker bind all <Leave> {
    set marker [%W marker get current]
    catch { %W marker configure $marker -bg ""}
}

$graph element bind all <Enter> {
    $graph element closest %x %y info
    ## catch {puts stderr "$info(x) $info(y)"}
}

