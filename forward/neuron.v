module neuron #(
    parameter dataWidth = 16,
    parameter numInputs = 2
)(
    input clk,
    input rst,
    
    // 输入接口
    input signed [dataWidth-1:0] input0,
    input signed [dataWidth-1:0] input1,
    input signed [dataWidth-1:0] weight0,
    input signed [dataWidth-1:0] weight1,
    input signed [dataWidth-1:0] bias,
    input calc_enable,
    
    // 输出接口
    output reg [dataWidth-1:0] out,
    output reg out_valid
);
    
    // 内部信号
    reg [31:0] mul_result;
    reg [dataWidth-1:0] sum_with_bias;
    reg [2:0] calc_state;  // 增加位宽以支持更多状态
    wire [dataWidth-1:0] sigmoid_out;
    
    // 状态定义
    parameter IDLE = 3'b000;
    parameter MULTIPLY = 3'b001;
    parameter ADD_BIAS = 3'b010;
    parameter WAIT_SIGMOID = 3'b011;  // 新增等待状态
    parameter DONE = 3'b100;
    
    // 状态机控制计算过程
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            mul_result <= 0;
            sum_with_bias <= 0;
            out_valid <= 0;
            calc_state <= IDLE;
            out <= 0;
        end 
        else begin
            case (calc_state)
                IDLE: begin
                    if (calc_enable) begin
                        mul_result <= (input0 * weight0) + (input1 * weight1);
                        calc_state <= MULTIPLY;
                        out_valid <= 0;
                    end
                end
                
                MULTIPLY: begin
                    sum_with_bias <= ((mul_result + 32'h80) >> 8) + bias;
                    calc_state <= ADD_BIAS;
                end
                
                ADD_BIAS: begin
                    // 在这个状态里，sum_with_bias的值被送入Sigmoid模块
                    // 但还需要等待一个时钟周期让Sigmoid模块计算完成
                    calc_state <= WAIT_SIGMOID;
                end
                
                WAIT_SIGMOID: begin
                    // 等待一个时钟周期后，读取sigmoid的输出
                    out <= sigmoid_out;
                    out_valid <= 1;
                    calc_state <= DONE;
                end
                
                DONE: begin
                    if (!calc_enable) begin
                        out_valid <= 0;
                        calc_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // 使用Sig_ROM
    Sig_ROM #(
        .inWidth(8),
        .dataWidth(dataWidth)
    ) sigmoid_inst (
        .clk(clk),
        .x(sum_with_bias[15:8]),  // 取高8位作为sigmoid输入
        .out(sigmoid_out)
    );
    
endmodule
