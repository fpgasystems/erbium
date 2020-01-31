set path_to_packaged "./packaged_kernel/ip_${suffix}"
set path_to_tmp_project "./_xo-tmp_${suffix}"

create_project -force kernel_pack $path_to_tmp_project 
read_vhdl -library tools [glob ../hw/tools/*.vhd]
read_vhdl -library bre [glob ../hw/engine/*.vhd]
read_vhdl -library bre [glob ../hw/custom/cfg_engines_${engines}.vhd]
read_vhdl -library bre [glob ../hw/custom/cfg_criteria_${heuristic}.vhd]
add_files -norecurse [glob ../hw/${shell}/*.sv ../hw/${shell}/*.v ../hw/${shell}/*.vhd]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1
ipx::package_project -root_dir $path_to_packaged -vendor ethz -taxonomy /KernelIP -import_files -set_current false
ipx::unload_core $path_to_packaged/component.xml
ipx::edit_ip_in_project -upgrade true -name tmp_edit_project -directory $path_to_packaged $path_to_packaged/component.xml
set_property core_revision 2 [ipx::current_core]
foreach up [ipx::get_user_parameters] {
  ipx::remove_user_parameter [get_property NAME $up] [ipx::current_core]
}
set_property sdx_kernel true [ipx::current_core]
set_property sdx_kernel_type rtl [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
::ipx::associate_bus_interfaces -busif m00_axi -clock ap_clk [ipx::current_core]
::ipx::associate_bus_interfaces -busif s_axi_control -clock ap_clk [ipx::current_core]
::ipx::infer_bus_interface "ap_clk_2"   "xilinx.com:signal:clock_rtl:1.0" [ipx::current_core]
::ipx::infer_bus_interface "ap_rst_n_2" "xilinx.com:signal:reset_rtl:1.0" [ipx::current_core]
set_property xpm_libraries {XPM_CDC XPM_MEMORY XPM_FIFO} [ipx::current_core]
set_property supported_families { } [ipx::current_core]
set_property auto_family_support_level level_2 [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]
close_project -delete