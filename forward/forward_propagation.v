module forward_propagation #(
    parameter dataWidth = 16// 使用8.8定点格式
)(
    input clk,
    input rst,
    input enable_fp,
    
    // 输入
    input signed [dataWidth-1:0] x1, x2,
    
    // 权重和偏置
    input signed [dataWidth-1:0] w11, w12, w21, w22, w31, w32,
    input signed [dataWidth-1:0] b1, b2, b3,
    
    // 输出
    output signed [dataWidth-1:0] h1, h2, y,
    
    // 传递权重和偏置到反向传播模块
    output reg signed [dataWidth-1:0] w11_out, w12_out, w21_out, w22_out, w31_out, w32_out,
    output reg signed [dataWidth-1:0] b1_out, b2_out, b3_out,
    
    // 有效信号
    output reg fp_valid
);
    
    // 状态信号
    reg [1:0] state;
    parameter IDLE = 2'b00;
    parameter LAYER1 = 2'b01;
    parameter LAYER2 = 2'b10;
    parameter DONE = 2'b11;
    
    // 神经元使能和有效信号
    reg neuron1_enable, neuron2_enable, neuron3_enable;
    wire neuron1_valid, neuron2_valid, neuron3_valid;
    
    // 将权重传递给反向传播模块
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            w11_out <= 16'd0;
            w12_out <= 16'd0;
            w21_out <= 16'd0;
            w22_out <= 16'd0;
            w31_out <= 16'd0;
            w32_out <= 16'd0;
            b1_out <= 16'd0;
            b2_out <= 16'd0;
            b3_out <= 16'd0;
        end else if (enable_fp && state == IDLE) begin
            w11_out <= w11;
            w12_out <= w12;
            w21_out <= w21;
            w22_out <= w22;
            w31_out <= w31;
            w32_out <= w32;
            b1_out <= b1;
            b2_out <= b2;
            b3_out <= b3;
        end
    end
    
    // 状态机和数据路径控制
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            fp_valid <= 1'b0;
            neuron1_enable <= 1'b0;
            neuron2_enable <= 1'b0;
            neuron3_enable <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (enable_fp) begin
                        // 启动第一层神经元计算
                        neuron1_enable <= 1'b1;
                        neuron2_enable <= 1'b1;
                        
                        state <= LAYER1;
                        fp_valid <= 1'b0;
                    end
                end
                
                LAYER1: begin
                    // 等待第一层计算完成
                    neuron1_enable <= 1'b0;
                    neuron2_enable <= 1'b0;
                    
                    if (neuron1_valid && neuron2_valid) begin
                        // 启动第二层神经元计算
                        neuron3_enable <= 1'b1;
                        state <= LAYER2;
                    end
                end
                
                LAYER2: begin
                    // 等待第二层计算完成
                    neuron3_enable <= 1'b0;
                    
                    if (neuron3_valid) begin
                        fp_valid <= 1'b1;
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    // 重置状态，等待下一次计算
                    if (!enable_fp) begin
                        fp_valid <= 1'b0;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // 实例化第一层神经元 (隐藏层)
    neuron #(
        .dataWidth(dataWidth),
        .numInputs(2)
    ) neuron_h1 (
        .clk(clk),
        .rst(rst),
        .input0(x1),
        .input1(x2),
        .weight0(w11),
        .weight1(w12),
        .bias(b1),
        .calc_enable(neuron1_enable),
        .out(h1),
        .out_valid(neuron1_valid)
    );
    
    neuron #(
        .dataWidth(dataWidth),
        .numInputs(2)

    ) neuron_h2 (
        .clk(clk),
        .rst(rst),
        .input0(x1),
        .input1(x2),
        .weight0(w21),
        .weight1(w22),
        .bias(b2),
        .calc_enable(neuron2_enable),
        .out(h2),
        .out_valid(neuron2_valid)
    );
    
    // 实例化第二层神经元 (输出层)
    neuron #(
        .dataWidth(dataWidth),
        .numInputs(2)

    ) neuron_output (
        .clk(clk),
        .rst(rst),
        .input0(h1),
        .input1(h2),
        .weight0(w31),
        .weight1(w32),
        .bias(b3),
        .calc_enable(neuron3_enable),
        .out(y),
        .out_valid(neuron3_valid)
    );
    
endmodule
