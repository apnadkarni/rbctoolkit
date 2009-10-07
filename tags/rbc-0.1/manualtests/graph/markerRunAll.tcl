set CommandName "marker"

proc commandList {} {
	list bind configure.bitmap configure.common configure.image configure.line configure.polygon configure.text configure.window create delete
}

source ../GraphRunAllSupportMethods.tcl

LoadSources [commandList] $CommandName

ExecuteCommandSequenceCommand [commandList] $CommandName