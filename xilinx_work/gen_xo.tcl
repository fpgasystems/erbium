if { $::argc != 7 } {
    puts "ERROR: Program \"$::argv0\" requires 7 arguments!\n"
    puts "Usage: $::argv0 <xoname> <krnl_name> <target> <device> <shell> <engines> <heuristic>\n"
    exit
}

set xoname    [lindex $::argv 0]
set krnl_name [lindex $::argv 1]
set target    [lindex $::argv 2]
set device    [lindex $::argv 3]
set shell     [lindex $::argv 4]
set engines   [lindex $::argv 5]
set heuristic [lindex $::argv 6]

set suffix "${krnl_name}_${target}_${device}_${heuristic}_${engines}e"

source -notrace ../hw/${shell}/package_kernel.tcl

if {[file exists "${xoname}"]} {
    file delete -force "${xoname}"
}

package_xo -xo_path ${xoname} -kernel_name ${krnl_name} -ip_directory ./packaged_kernel/ip_${suffix} -kernel_xml ../hw/${shell}/kernel.xml