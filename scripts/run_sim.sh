#!/bin/bash

# Set up paths for QuestaSim and scripts
TCL_SCRIPT="run_sim.tcl"

# Default values for flags
DEBUG=false
BUILD_SW=false

# Parse arguments
for arg in "$@"; do
    case $arg in
        --debug)
            DEBUG=true
            ;;
        --build_sw)
            BUILD_SW=true
            ;;
    esac
done

# Build software if the --build_sw flag is provided
if $BUILD_SW; then
    echo "Building software..."
    cd $HOME/main/Source/cheshire
    make sw-all || {
        echo "Error: 'make sw-all' failed!" >&2
        exit 1
    }
fi

cd $HOME/main/Source/cheshire/target/sim/vsim

# Create the TCL script dynamically
cat <<EOF > $TCL_SCRIPT
# Preload \`helloworld.spm.elf\` through serial link
set BINARY ../../../sw/tests/helloworld.spm.elf
set BOOTMODE 0
set PRELMODE 1

# Compile design
source compile.cheshire_soc.tcl

# Start and run simulation
source start.cheshire_soc.tcl
run -all
quit
EOF

source /eda/scripts/init_questa_2024.3

# Run QuestaSim in command-line mode and filter the output
if $DEBUG; then
    vsim -c -do "source $TCL_SCRIPT" 2>&1 | grep -E "Error|error"
else
    vsim -c -do "source $TCL_SCRIPT"
fi

# Clean up the TCL script after execution (optional)
rm -f $TCL_SCRIPT
