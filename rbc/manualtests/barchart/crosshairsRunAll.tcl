set CommandName "crosshairs"

proc commandList {} {
	list configure off on toggle
}

source ../BarchartRunAllSupportMethods.tcl

LoadSources [commandList] $CommandName

ExecuteCommandSequenceCommand [commandList] $CommandName