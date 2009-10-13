# all.tcl --
#
# This file contains a top-level script to run all of the Tcl
# tests.  Execute it by invoking "source all.test" when running tcltest
# in this directory.
#

# restart using tclsh \
exec tclsh "$0" "$@"

package require tcltest 2

package require Tk ;# This is the Tk test suite; fail early if no Tk!

eval tcltest::configure $argv
tcltest::configure -testdir [file normalize [file dirname [info script]]]

tcltest::configure -singleproc 1
tcltest::runAllTests

