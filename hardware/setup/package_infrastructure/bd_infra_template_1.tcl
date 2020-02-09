
set root_dir         $::env(OCACCEL_HARDWARE_ROOT)
set fpga_part        $::env(FPGACHIP)
set project "bd_infra"
set project_dir      $root_dir/build/temp_projs/$project

set ip_repo_dir     $root_dir/build/ip_repo
set interfaces_dir  $root_dir/build/interfaces
set bd_name         "infra_template_1"

source $root_dir/setup/common/common_funcs.tcl
set imp_version [eval my_get_imp_version]
set build_date [eval my_get_build_date]
set card_type [eval my_get_card_type]

###############################################################################
# Create project and bd

create_project $project $project_dir -part $fpga_part
create_bd_design $bd_name
set_property  ip_repo_paths  [list $ip_repo_dir $interfaces_dir] [current_project]
update_ip_catalog

###############################################################################
# Add IPs
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:bridge_axi_slave:1.0 bridge_axi_slave
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:data_bridge:1.0 data_bridge
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:mmio_axilite_master:1.0 mmio_axilite_master
set_property -dict [list CONFIG.IMP_VERSION $imp_version ] [get_bd_cells mmio_axilite_master]
set_property -dict [list CONFIG.BUILD_DATE $build_date ] [get_bd_cells mmio_axilite_master]
set_property -dict [list CONFIG.CARD_TYPE $card_type ] [get_bd_cells mmio_axilite_master]

create_bd_cell -type ip -vlnv opencapi.org:ocaccel:opencapi30_c1:1.0 opencapi30_c1
create_bd_cell -type ip -vlnv opencapi.org:ocaccel:opencapi30_mmio:1.0 opencapi30_mmio


# Address 
assign_bd_address [get_bd_addr_segs {bridge_axi_slave/s_axi/reg0 }]

###############################################################################
# Make connections
connect_bd_net [get_bd_pins opencapi30_c1/debug_bus] [get_bd_pins mmio_axilite_master/debug_bus_trans_protocol]
connect_bd_intf_net [get_bd_intf_pins opencapi30_mmio/ocaccel_mmio] [get_bd_intf_pins mmio_axilite_master/ocaccel_mmio]
connect_bd_intf_net [get_bd_intf_pins data_bridge/ocaccel_dma_wr] [get_bd_intf_pins opencapi30_c1/ocaccel_dma_wr]
connect_bd_intf_net [get_bd_intf_pins data_bridge/ocaccel_dma_rd] [get_bd_intf_pins opencapi30_c1/ocaccel_dma_rd]
connect_bd_intf_net [get_bd_intf_pins bridge_axi_slave/ocaccel_lcl_wr] [get_bd_intf_pins data_bridge/ocaccel_lcl_wr]
connect_bd_intf_net [get_bd_intf_pins bridge_axi_slave/ocaccel_lcl_rd] [get_bd_intf_pins data_bridge/ocaccel_lcl_rd]



connect_bd_net [get_bd_pins mmio_axilite_master/debug_info_clear] [get_bd_pins opencapi30_c1/debug_info_clear]
connect_bd_net [get_bd_pins bridge_axi_slave/lcl_wr_ctx_valid] [get_bd_pins opencapi30_c1/lcl_wr_ctx_valid]
connect_bd_net [get_bd_pins bridge_axi_slave/lcl_rd_ctx_valid] [get_bd_pins opencapi30_c1/lcl_rd_ctx_valid]
connect_bd_net [get_bd_pins bridge_axi_slave/lcl_wr_ctx] [get_bd_pins opencapi30_c1/lcl_wr_ctx]
connect_bd_net [get_bd_pins bridge_axi_slave/lcl_rd_ctx] [get_bd_pins opencapi30_c1/lcl_rd_ctx]
connect_bd_intf_net [get_bd_intf_pins bridge_axi_slave/ocaccel_lcl_rd] [get_bd_intf_pins data_bridge/ocaccel_lcl_rd]
connect_bd_net [get_bd_pins data_bridge/debug_bus] [get_bd_pins mmio_axilite_master/debug_bus_data_bridge]
connect_bd_net [get_bd_pins data_bridge/last_context_cleared] [get_bd_pins opencapi30_c1/last_context_cleared]
connect_bd_net [get_bd_pins data_bridge/context_update_ongoing] [get_bd_pins opencapi30_c1/context_update_ongoing]


###############################################################################
# Make Ports (External Pins)
# Clocks and Reset
create_bd_port -dir I -type clk -freq_hz 100000000 clock_afu
connect_bd_net [get_bd_ports clock_afu] [get_bd_pins /bridge_axi_slave/clk] 
connect_bd_net [get_bd_ports clock_afu] [get_bd_pins data_bridge/clk]
connect_bd_net [get_bd_ports clock_afu] [get_bd_pins opencapi30_mmio/clock_afu]
connect_bd_net [get_bd_ports clock_afu] [get_bd_pins opencapi30_c1/clock_afu]
connect_bd_net [get_bd_ports clock_afu] [get_bd_pins mmio_axilite_master/clk]

create_bd_port -dir I -type clk -freq_hz 100000000 clock_tlx
connect_bd_net [get_bd_ports clock_tlx] [get_bd_pins opencapi30_c1/clock_tlx]
connect_bd_net [get_bd_ports clock_tlx] [get_bd_pins opencapi30_mmio/clock_tlx]

create_bd_port -dir I -type rst rst_n
connect_bd_net [get_bd_pins /bridge_axi_slave/rst_n] [get_bd_ports rst_n]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins data_bridge/rst_n]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins opencapi30_c1/rst_n]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins mmio_axilite_master/rst_n]
connect_bd_net [get_bd_ports rst_n] [get_bd_pins opencapi30_mmio/rst_n]

# To Action Wrapper
make_bd_pins_external  [get_bd_pins mmio_axilite_master/soft_reset_action]
make_bd_pins_external  [get_bd_pins opencapi30_c1/interrupt]
make_bd_pins_external  [get_bd_pins opencapi30_c1/interrupt_src]
make_bd_pins_external  [get_bd_pins opencapi30_c1/interrupt_ctx]
make_bd_pins_external  [get_bd_pins opencapi30_c1/interrupt_ack]
make_bd_intf_pins_external  [get_bd_intf_pins mmio_axilite_master/m_axi]
make_bd_intf_pins_external  [get_bd_intf_pins bridge_axi_slave/s_axi]

# To Host IF
make_bd_intf_pins_external  [get_bd_intf_pins opencapi30_c1/ocaccel_afu_tlx]
make_bd_intf_pins_external  [get_bd_intf_pins opencapi30_mmio/ocaccel_tlx_afu]
make_bd_pins_external  [get_bd_pins opencapi30_mmio/cfg_f1_mmio_bar0]
make_bd_pins_external  [get_bd_pins opencapi30_mmio/cfg_f1_mmio_bar0_mask]
make_bd_intf_pins_external  [get_bd_intf_pins opencapi30_c1/ocaccel_cfg_infra_c1]

#----------------------------------------------------------------------
# Remove the automatically generated _0 to make port name = pin name
# This is not a must, just to avoid to many _0 when building several levels of bd

set_property NAME soft_reset_action [get_bd_ports soft_reset_action_0 ]
set_property NAME interrupt [get_bd_ports interrupt_0 ]
set_property NAME interrupt_src [get_bd_ports interrupt_src_0 ]
set_property NAME interrupt_ctx [get_bd_ports interrupt_ctx_0 ]
set_property NAME interrupt_ack [get_bd_ports interrupt_ack_0 ]
set_property NAME m_axi [get_bd_intf_ports m_axi_0 ]
set_property NAME s_axi [get_bd_intf_ports s_axi_0 ]

# To Host IF
set_property NAME ocaccel_afu_tlx [get_bd_intf_ports ocaccel_afu_tlx_0 ]
set_property NAME ocaccel_tlx_afu [get_bd_intf_ports ocaccel_tlx_afu_0 ]
set_property NAME cfg_f1_mmio_bar0 [get_bd_ports cfg_f1_mmio_bar0_0 ]
set_property NAME cfg_f1_mmio_bar0_mask [get_bd_ports cfg_f1_mmio_bar0_mask_0 ]
set_property NAME ocaccel_cfg_infra_c1 [get_bd_intf_ports ocaccel_cfg_infra_c1_0 ]


###############################################################################
# Save and Make wrapper
regenerate_bd_layout
save_bd_design [current_bd_design]
make_wrapper -files [get_files $project_dir/${project}.srcs/sources_1/bd/$bd_name/$bd_name/bd] -top

ipx::package_project -root_dir $ip_repo_dir/$bd_name -vendor opencapi.org -library ocaccel -taxonomy /UserIP -module $bd_name -import_files

set_property core_revision 2 [ipx::find_open_core opencapi.org:ocaccel:$bd_name:1.0]
ipx::create_xgui_files [ipx::find_open_core opencapi.org:ocaccel:$bd_name:1.0]
ipx::update_checksums [ipx::find_open_core opencapi.org:ocaccel:$bd_name:1.0]
ipx::save_core [ipx::find_open_core opencapi.org:ocaccel:$bd_name:1.0]
close_project
