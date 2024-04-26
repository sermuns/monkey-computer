# build.tcl
# Common build script for TSEA83
# Version 1.1
# 2024-02-23
# Anders Nilsson

#------------------------------
# Version log:

set CurrentVersion "Version 1.1 - 2024-02-23"

# Version 1.1 - 2024-02-23
# Added timing summary and timing for 5 worst cases when generating bit file.

# Version 1.0 - 2023-11-29
# Initial version

#------------------------------

# Run this build script with:
# vivado -mode batch -source build.tcl -notrace -tclargs ...
#
# The first argument should be the action/command to execute, one of:
# - synth : sythesize project
# - bit   : generate bitfile
# - prog  : program bitfile into FPGA
# - help  : print instructions
#
# The following argument(s) should be a list of VHDL files, and the
# last argument should be the constraints file
#

# Set (and create) working directory
set workDir work
#file mkdir $workDir

# Init global variables
set_param general.maxThreads 8 
set help 0
set error 0

if {[llength $argv] == 0} { incr help };

# Extract command from arguments
set cmd [lrange $argv 0 0]

# Extract list of files from arguments
set vhdFiles [lrange $argv 1 end-1]

# Set top module
set top [file rootname [file tail [lrange $vhdFiles 0 0]]]

# Extract constraints file from arguments
set xdcFile [lrange $argv end end]

# Set bit file
set bitFile "${top}.bit"

#set files [lrange [lindex $args 0] 1 end-1]
#set xdc [lrange [lindex $args 0] end end]

## Synthesize design procedure
proc synthesize {} {
    global vhdFiles
    global xdcFile
    global top
    global workDir

    puts ""
    puts "############################################################################"
    puts "#### Synthesizing..."
    puts ""

    foreach i $vhdFiles {
	puts "Reading: $i"
	read_vhdl ../$i
    set_property FILE_TYPE {VHDL 2008} [get_files $i]
    }

    puts "Reading: $xdcFile"
    read_xdc ../$xdcFile

    synth_design -top $top -part xc7a35ticpg236-1L
}


## Bitfile generation procedure
proc bitgen {} {
    global workDir
    global bitFile

    puts ""
    puts "############################################################################"
    puts "#### Generating bitfile..."
    puts ""
    
    puts ""
    puts "############################################################################"
    puts "#### Optimizing design"
    puts ""
    
    opt_design
    
    puts ""
    puts "############################################################################"
    puts "#### Place design"
    puts ""
    
    place_design
    
    puts ""
    puts "############################################################################"
    puts "#### Physical optimization"
    puts ""
    
    phys_opt_design
    
    puts ""
    puts "############################################################################"
    puts "#### Route design"
    puts ""
    
    route_design
    
    puts ""
    puts "############################################################################"
    puts "#### Write bitstream"
    puts ""
    
    write_bitstream -force $bitFile

    puts ""
    puts "############################################################################"
    puts "#### Produce timing reports"
    puts ""

    report_timing_summary -file timing_summary.txt
    report_timing -nworst 5 -path_type full -input_pins -file timing_5worst.txt
}


## Program FPGA board procedure
proc program {} {
    global workDir
    global bitFile

    puts ""
    puts "############################################################################"
    puts "#### Programming FPGA board..."
    puts ""

    puts ""
    puts "############################################################################"
    puts "#### Open hardware manager"
    puts ""
    
    ## open hardware manager  # Vivado 2023.2
    open_hw_manager
    #open_hw # deprecated
    #connect_hw_server -allow_non_jtag # Vivado 2023.2
    connect_hw_server
    
    puts ""
    puts "############################################################################"
    puts "#### Open target"
    puts ""
    
    ## Open target
    open_hw_target
    current_hw_device [get_hw_devices xc7a35t_0]
    refresh_hw_device -update_hw_probes false [lindex [get_hw_devices xc7a35t_0] 0]
    
    puts ""
    puts "############################################################################"
    puts "#### Program device"
    puts ""
    
    ## Program device
    set_property PROBES.FILE {} [get_hw_devices xc7a35t_0]
    set_property FULL_PROBES.FILE {} [get_hw_devices xc7a35t_0]
    set progFile "${bitFile}"
    set_property PROGRAM.FILE $bitFile [get_hw_devices xc7a35t_0]
    program_hw_devices [get_hw_devices xc7a35t_0]
}


## Main command switch
puts ""
puts "############################################################################"
puts "#### Build script '$CurrentVersion'"
puts ""

switch -exact -- $cmd {

    synth { ## synthesize design option
	puts "Doing synth"
	synthesize
	write_checkpoint -force synth.dcp
    }

    bit { ## generate bit file option
	global workDir
	if {[file exists synth.dcp] == 1} {
	    open_checkpoint synth.dcp
	    bitgen
	} else {
	    synthesize
	    bitgen
	}
    }

    prog { ## program FPGA board option
	global workDir
	global bitFile
	if {[file exists $bitFile] == 1} {
	    program
	} elseif {[file exists synth.dcp] == 1} {
	    open_checkpoint synth.dcp
	    bitgen
	    program
	} else {
	    synthesize
	    bitgen
	    program
	}	
    }

    help { ## help option
	incr help
    }

    default { ## default option
	puts "'$cmd' is not a valid command"
	incr error
	}
}


if {$help} {
    puts "Supply with one of the following:"
    puts "synth"
    puts "bit"
    puts "prog"
    puts "help"
    return -code ok {}
}


if {$error} {
    return -code error {Oops, something is not correct}
}

return -code ok {}


