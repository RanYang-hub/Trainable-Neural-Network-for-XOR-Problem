vlib work

# 编译文件
vlog Sig_ROM.v
vlog neuron.v
vlog forward_propagation.v
vlog forward_propagation_tb.v

# 启动仿真
vsim -t 1ns -L work -voptargs="+acc" tb_neural_network

# 添加顶层信号
add wave -position insertpoint sim:/tb_neural_network/clk
add wave -position insertpoint sim:/tb_neural_network/rst
add wave -position insertpoint sim:/tb_neural_network/enable_fp
add wave -position insertpoint sim:/tb_neural_network/x1
add wave -position insertpoint sim:/tb_neural_network/x2
add wave -position insertpoint sim:/tb_neural_network/h1
add wave -position insertpoint sim:/tb_neural_network/h2
add wave -position insertpoint sim:/tb_neural_network/y
add wave -position insertpoint sim:/tb_neural_network/fp_valid
add wave -position insertpoint sim:/tb_neural_network/test_count

# 前向传播模块的所有信号
add wave -position insertpoint -expand -group "Forward_Prop" sim:/tb_neural_network/fp_inst/*

# 第一层神经元(h1)的所有信号
add wave -position insertpoint -expand -group "Neuron_h1" sim:/tb_neural_network/fp_inst/neuron_h1/*

# 第一层神经元(h2)的所有信号
add wave -position insertpoint -expand -group "Neuron_h2" sim:/tb_neural_network/fp_inst/neuron_h2/*

# 输出层神经元的所有信号
add wave -position insertpoint -expand -group "Neuron_out" sim:/tb_neural_network/fp_inst/neuron_output/*

# Sigmoid ROM的信号(用于第一个神经元)
add wave -position insertpoint -expand -group "Sigmoid_h1" sim:/tb_neural_network/fp_inst/neuron_h1/sigmoid_inst/*

# Sigmoid ROM的信号(用于第二个神经元)
add wave -position insertpoint -expand -group "Sigmoid_h2" sim:/tb_neural_network/fp_inst/neuron_h2/sigmoid_inst/*

# Sigmoid ROM的信号(用于输出神经元)
add wave -position insertpoint -expand -group "Sigmoid_out" sim:/tb_neural_network/fp_inst/neuron_output/sigmoid_inst/*

# 设置每组信号的颜色
configure wave -namecolwidth 200
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2

# 运行仿真直到结束
run -all

# 放大波形以查看全部细节
wave zoom full
