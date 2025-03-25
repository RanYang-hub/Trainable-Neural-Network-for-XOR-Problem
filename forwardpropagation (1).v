
// Implementation of neural network forward propagation
module forward_propagation (
    input clk,
    input rst,
    input enable_fp,
    input signed [15:0] x1, x2,
    input signed [15:0] w11, w12, w21, w22, w31, w32,
    input signed [15:0] b1, b2, b3,
    output reg signed [15:0] h1, h2, y,
    output reg signed [15:0] w11_out, w12_out, w21_out, w22_out, w31_out, w32_out,
    output reg signed [15:0] b1_out, b2_out, b3_out,
    output reg fp_valid
);
    // Use 32-bit temporary variables to avoid overflow
    reg signed [31:0] temp_h1, temp_h2, temp_y;
    reg signed [15:0] z1, z2, z3; // Pre-activation values for all layers
    
    // Instantiate combinational sigmoid module - will be used for output layer
    wire signed [15:0] sigmoid_out;
    
    // State machine definition
    reg [2:0] state;
    localparam IDLE = 3'd0;
    localparam COMPUTE_HIDDEN_SUMS = 3'd1;
    localparam COMPUTE_HIDDEN_ACTS = 3'd2;
    localparam COMPUTE_OUTPUT_SUM = 3'd3;
    localparam COMPUTE_OUTPUT_ACT = 3'd4;
    localparam DONE = 3'd5;
    
    // Instantiate the combinational sigmoid module for the output layer
    Sigmoid_Combinational sigmoid_comb (
        .x(z3),
        .out(sigmoid_out)
    );
    neuron #(
    .dataWidth(16),
    .weightIntWidth(1),
    .sigmoidSize(8),
    .actType("sigmoid")  // "sigmoid" or "relu"
) neuron_inst (
    .clk(clk),
    .rst(rst),
    .input1(x1),
    .input2(x1),
    .inputs_valid(enable_fp),
    .weight1(w11),
    .weight2(w12),
    .bias_in(b1),
    .out(),
    .outvalid()
);
    // ReLU activation function
    function signed [15:0] relu;
        input signed [15:0] x;
        begin
            relu = (x[15] == 1'b1) ? 16'd0 : x; // If negative, return 0, else return x
        end
    endfunction
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all outputs and state
            h1 <= 16'd0;
            h2 <= 16'd0;
            y <= 16'd0;
            w11_out <= 16'd0;
            w12_out <= 16'd0;
            w21_out <= 16'd0;
            w22_out <= 16'd0;
            w31_out <= 16'd0;
            w32_out <= 16'd0;
            b1_out <= 16'd0;
            b2_out <= 16'd0;
            b3_out <= 16'd0;
            fp_valid <= 0;
            state <= IDLE;
            z1 <= 16'd0;
            z2 <= 16'd0;
            z3 <= 16'd0;
        end else begin
            case (state)
                IDLE: begin
                    if (enable_fp) begin
                        // Forward the weights to BP module
                        w11_out <= w11;
                        w12_out <= w12;
                        w21_out <= w21;
                        w22_out <= w22;
                        w31_out <= w31;
                        w32_out <= w32;
                        b1_out <= b1;
                        b2_out <= b2;
                        b3_out <= b3;
                        
                        // Reset valid signal
                        fp_valid <= 0;
                        
                        // Move to hidden layer sum computation
                        state <= COMPUTE_HIDDEN_SUMS;
                    end
                end
                
                COMPUTE_HIDDEN_SUMS: begin
                    // Compute hidden layer weighted sum with proper rounding
                    // First hidden neuron
                    temp_h1 = ($signed(w11) * $signed(x1)) >>> 8;
                    temp_h1 = temp_h1 + (($signed(w12) * $signed(x2)) >>> 8);
                    z1 <= temp_h1[15:0] + b1;
                    
                    // Second hidden neuron
                    temp_h2 = ($signed(w21) * $signed(x1)) >>> 8;
                    temp_h2 = temp_h2 + (($signed(w22) * $signed(x2)) >>> 8);
                    z2 <= temp_h2[15:0] + b2;
                    
                    // Move to activation computation
                    state <= COMPUTE_HIDDEN_ACTS;
                end
                
                COMPUTE_HIDDEN_ACTS: begin
                    // Apply ReLU activation for hidden layers
                    h1 <= relu(z1);
                    h2 <= relu(z2);
                    
                    // Move to output sum computation
                    state <= COMPUTE_OUTPUT_SUM;
                end
                
                COMPUTE_OUTPUT_SUM: begin
                    // Output neuron calculation using previously computed h1, h2
                    temp_y = ($signed(w31) * $signed(h1)) >>> 8;
                    temp_y = temp_y + (($signed(w32) * $signed(h2)) >>> 8);
                    z3 <= temp_y[15:0] + b3;
                    
                    // Move to output layer activation computation
                    state <= COMPUTE_OUTPUT_ACT;
                end
                
                COMPUTE_OUTPUT_ACT: begin
                    // Apply sigmoid activation for the output layer
                    y <= sigmoid_out;
                    
                    // Debug display 
//                    $display("Debug: z3 = %d, sigmoid_out = %d", z3, sigmoid_out);
                    
                    // Move to done state
                    state <= DONE;
                end
                
                DONE: begin
                    // Set valid signal
                    fp_valid <= 1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule

// Implementation of combinational sigmoid function
module Sigmoid_Combinational (
    input signed [15:0] x,
    output signed [15:0] out
);
    // Calculate the absolute value
    wire signed [15:0] abs_x;
    assign abs_x = (x[15]) ? (-x) : x;
    
    // Divide into 32 regions - use the upper bits to index the lookup table
    wire [4:0] idx;
    assign idx = (abs_x >= 16'd768) ? 5'd31 : (abs_x >> 5); // Map to 32 regions, shifting by 5 bits for division
    
    // Lookup table for sigmoid function values, precomputed for specific input ranges
    reg [15:0] sigmoid_value;
    
    always @(*) begin
        case(idx)
            5'd0:  sigmoid_value = 16'h0080; // 0.5000 (x=0)
            5'd1:  sigmoid_value = 16'h0088; // 0.5312 (x=~0.1)
            5'd2:  sigmoid_value = 16'h0090; // 0.5625 (x=~0.2)
            5'd3:  sigmoid_value = 16'h0098; // 0.5937 (x=~0.3)
            5'd4:  sigmoid_value = 16'h00A0; // 0.6250 (x=~0.4)
            5'd5:  sigmoid_value = 16'h00A8; // 0.6562 (x=~0.5)
            5'd6:  sigmoid_value = 16'h00B0; // 0.6875 (x=~0.6)
            5'd7:  sigmoid_value = 16'h00B8; // 0.7187 (x=~0.7)
            5'd8:  sigmoid_value = 16'h00C0; // 0.7500 (x=~0.8)
            5'd9:  sigmoid_value = 16'h00C7; // 0.7773 (x=~0.9)
            5'd10: sigmoid_value = 16'h00CE; // 0.8047 (x=~1.0)
            5'd11: sigmoid_value = 16'h00D5; // 0.8320 (x=~1.1)
            5'd12: sigmoid_value = 16'h00DC; // 0.8594 (x=~1.2)
            5'd13: sigmoid_value = 16'h00E2; // 0.8828 (x=~1.3)
            5'd14: sigmoid_value = 16'h00E8; // 0.9062 (x=~1.4)
            5'd15: sigmoid_value = 16'h00ED; // 0.9258 (x=~1.5)
            5'd16: sigmoid_value = 16'h00F2; // 0.9453 (x=~1.6)
            5'd17: sigmoid_value = 16'h00F6; // 0.9609 (x=~1.7)
            5'd18: sigmoid_value = 16'h00FA; // 0.9766 (x=~1.8)
            5'd19: sigmoid_value = 16'h00FD; // 0.9883 (x=~1.9)
            5'd20: sigmoid_value = 16'h00FF; // 0.9961 (x=~2.0)
            5'd21: sigmoid_value = 16'h00FF; // 0.9961 (x=~2.1)
            5'd22: sigmoid_value = 16'h00FF; // 0.9961 (x=~2.2)
            5'd23: sigmoid_value = 16'h0100; // 1.0000 (x=~2.3)
            5'd24: sigmoid_value = 16'h0100; // 1.0000 (x=~2.4)
            5'd25: sigmoid_value = 16'h0100; // 1.0000 (x=~2.5)
            5'd26: sigmoid_value = 16'h0100; // 1.0000 (x=~2.6)
            5'd27: sigmoid_value = 16'h0100; // 1.0000 (x=~2.7)
            5'd28: sigmoid_value = 16'h0100; // 1.0000 (x=~2.8)
            5'd29: sigmoid_value = 16'h0100; // 1.0000 (x=~2.9)
            5'd30: sigmoid_value = 16'h0100; // 1.0000 (x=~3.0)
            5'd31: sigmoid_value = 16'h0100; // 1.0000 (x>3.0)
        endcase
    end
    
    // Apply sigmoid property: sigmoid(-x) = 1 - sigmoid(x)
    // In 8.8 fixed-point representation: sigmoid(-x) = 256 - sigmoid(x)
    assign out = (x[15]) ? (16'h0100 - sigmoid_value) : sigmoid_value;
endmodule

module neuron #(
    parameter dataWidth=16,
    parameter weightIntWidth=1,
    parameter sigmoidSize=8,
    parameter actType="sigmoid"  // "sigmoid" 或 "relu"
)(
    input                      clk,
    input                      rst,
    // 并行输入接口
    input [dataWidth-1:0]      input1,
    input [dataWidth-1:0]      input2,
    input                      inputs_valid,
    // 权重和偏置
    input [dataWidth-1:0]      weight1,
    input [dataWidth-1:0]      weight2,
    input [dataWidth-1:0]      bias_in,
    // 输出接口
    output [dataWidth-1:0]     out,
    output reg                 outvalid
);
    
    // 内部信号
    reg [2*dataWidth-1:0]    mul1, mul2; 
    reg [2*dataWidth-1:0]    sum;
    reg [2*dataWidth-1:0]    bias;
    reg                      calc_started;
    reg                      calc_done;
    
    // 偏置加载
    always @(posedge clk) begin
        if(rst) begin
            bias <= 0;
        end else begin
            bias <= {bias_in, {dataWidth{1'b0}}};
        end
    end
    
    // 计算状态跟踪
    always @(posedge clk or posedge rst) begin
        if(rst) begin
            calc_started <= 0;
            calc_done <= 0;
            outvalid <= 0;
        end else begin
            // 计算开始
            if(inputs_valid && !calc_started) begin
                calc_started <= 1;
                calc_done <= 0;
                outvalid <= 0;
            end
            // 计算结束
            else if(calc_started && !calc_done) begin
                calc_done <= 1;
            end
            // 输出有效
            else if(calc_done && !outvalid) begin
                outvalid <= 1;
            end
            // 重置
            else if(outvalid) begin
                calc_started <= 0;
                calc_done <= 0;
                outvalid <= 0;
            end
        end
    end
    
    // 并行乘法
    always @(posedge clk) begin
        if(rst) begin
            mul1 <= 0;
            mul2 <= 0;
        end else if(inputs_valid) begin
            mul1 <= $signed(input1) * $signed(weight1);
            mul2 <= $signed(input2) * $signed(weight2);
        end
    end
    
    // 累加和偏置加法
    always @(posedge clk) begin
        if(rst || !calc_started) begin
            sum <= 0;
        end else if(calc_started && !calc_done) begin
            sum <= mul1 + mul2 + bias;  // 一步完成全部加法
        end
    end
    
endmodule
