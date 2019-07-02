# This is a generated file. Use and modify at your own risk.
################################################################################

set kernel_name    "mct"
set kernel_vendor  "ethz"
set kernel_library "abr"

##############################################################################

proc edit_core {core} {
  set bif      [::ipx::get_bus_interfaces -of $core  "m00_axi"] 
  set bifparam [::ipx::add_bus_parameter -quiet "MAX_BURST_LENGTH" $bif]
  set_property value        64           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_READ_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam
  set bifparam [::ipx::add_bus_parameter -quiet "NUM_WRITE_OUTSTANDING" $bif]
  set_property value        32           $bifparam
  set_property value_source constant     $bifparam

  ::ipx::associate_bus_interfaces -busif "m00_axi" -clock "ap_clk" $core
  ::ipx::associate_bus_interfaces -busif "s_axi_control" -clock "ap_clk" $core

  set mem_map    [::ipx::add_memory_map -quiet "s_axi_control" $core]
  set addr_block [::ipx::add_address_block -quiet "reg0" $mem_map]

  set reg      [::ipx::add_register "Control" $addr_block]
  set_property address_offset 0x000 $reg
  set_property size           1     $reg

  set reg      [::ipx::add_register -quiet "numCriteria" $addr_block]
  set_property address_offset 0x010 $reg
  set_property size           1   $reg

  set reg      [::ipx::add_register -quiet "queriesNumCLs" $addr_block]
  set_property address_offset 0x018 $reg
  set_property size           4   $reg

  set reg      [::ipx::add_register -quiet "edgesNumCLs" $addr_block]
  set_property address_offset 0x020 $reg
  set_property size           4   $reg

  set reg      [::ipx::add_register -quiet "resultNumCLs" $addr_block]
  set_property address_offset 0x028 $reg
  set_property size           4   $reg

  set reg      [::ipx::add_register -quiet "extraParam1" $addr_block]
  set_property address_offset 0x030 $reg
  set_property size           4   $reg

  set reg      [::ipx::add_register -quiet "extraParam2" $addr_block]
  set_property address_offset 0x038 $reg
  set_property size           4   $reg

  set reg      [::ipx::add_register -quiet "nfaPtr" $addr_block]
  set_property address_offset 0x040 $reg
  set_property size           8   $reg

  set reg      [::ipx::add_register -quiet "queryPtr" $addr_block]
  set_property address_offset 0x048 $reg
  set_property size           8   $reg

  set reg      [::ipx::add_register -quiet "resultPtr" $addr_block]
  set_property address_offset 0x050 $reg
  set_property size           8   $reg

  set_property slave_memory_map_ref "s_axi_control" [::ipx::get_bus_interfaces -of $core "s_axi_control"]

  set_property xpm_libraries {XPM_CDC XPM_MEMORY XPM_FIFO} $core
  set_property sdx_kernel true $core
  set_property sdx_kernel_type rtl $core
}

##############################################################################

proc package_project {path_to_packaged kernel_vendor kernel_library kernel_name} {
  set core [::ipx::package_project -root_dir $path_to_packaged -vendor $kernel_vendor -library $kernel_library -taxonomy "/KernelIP" -import_files -set_current false]
  foreach user_parameter [list C_S_AXI_CONTROL_ADDR_WIDTH C_S_AXI_CONTROL_DATA_WIDTH C_M00_AXI_ADDR_WIDTH C_M00_AXI_DATA_WIDTH] {
    ::ipx::remove_user_parameter $user_parameter $core
  }
  ::ipx::create_xgui_files $core
  set_property supported_families { } $core
  set_property auto_family_support_level level_2 $core
  set_property used_in {out_of_context implementation synthesis} [::ipx::get_files -type xdc -of_objects [::ipx::get_file_groups "xilinx_anylanguagesynthesis" -of_objects $core] *_ooc.xdc]
  edit_core $core
  ::ipx::update_checksums $core
  ::ipx::save_core $core
  ::ipx::unload_core $core
  unset core
}

##############################################################################

proc package_project_dcp {path_to_dcp path_to_packaged kernel_vendor kernel_library kernel_name} {
  set core [::ipx::package_checkpoint -dcp_file $path_to_dcp -root_dir $path_to_packaged -vendor $kernel_vendor -library $kernel_library -name $kernel_name -taxonomy "/KernelIP" -force]
  edit_core $core
  ::ipx::update_checksums $core
  ::ipx::save_core $core
  ::ipx::unload_core $core
  unset core
}

##############################################################################

proc package_project_dcp_and_xdc {path_to_dcp path_to_xdc path_to_packaged kernel_vendor kernel_library kernel_name} {
  set core [::ipx::package_checkpoint -dcp_file $path_to_dcp -root_dir $path_to_packaged -vendor $kernel_vendor -library $kernel_library -name $kernel_name -taxonomy "/KernelIP" -force]
  edit_core $core
  set rel_path_to_xdc [file join "impl" [file tail $path_to_xdc]]
  set abs_path_to_xdc [file join $path_to_packaged $rel_path_to_xdc]
  file mkdir [file dirname $abs_path_to_xdc]
  file copy $path_to_xdc $abs_path_to_xdc
  set xdcfile [::ipx::add_file $rel_path_to_xdc [::ipx::add_file_group "xilinx_implementation" $core]]
  set_property type "xdc" $xdcfile
  set_property used_in [list "implementation"] $xdcfile
  ::ipx::update_checksums $core
  ::ipx::save_core $core
  ::ipx::unload_core $core
  unset core
}

##############################################################################
