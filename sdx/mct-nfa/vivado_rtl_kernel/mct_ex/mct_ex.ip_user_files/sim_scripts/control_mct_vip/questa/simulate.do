onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib control_mct_vip_opt

do {wave.do}

view wave
view structure
view signals

do {control_mct_vip.udo}

run -all

quit -force
