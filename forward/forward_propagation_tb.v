module tb_neural_network;
    // 时钟和复位
    reg clk;
    reg rst;
    
    // 输入
    reg enable_fp;
    reg signed [15:0] x1, x2;  // 8.8定点格式
    
    // 权重和偏置 (预训练以实现XOR功能)
    reg signed [15:0] w11, w12, w21, w22, w31, w32;
    reg signed [15:0] b1, b2, b3;
    
    // 输出
    wire signed [15:0] h1, h2, y;
    wire signed [15:0] w11_out, w12_out, w21_out, w22_out, w31_out, w32_out;
    wire signed [15:0] b1_out, b2_out, b3_out;
    wire fp_valid;
    
    // 测试控制
    integer test_count;
    
    // 实例化前向传播模块
    forward_propagation #(
        .dataWidth(16)
    ) fp_inst (
        .clk(clk),
        .rst(rst),
        .enable_fp(enable_fp),
        .x1(x1),
        .x2(x2),
        .w11(w11),
        .w12(w12),
        .w21(w21),
        .w22(w22),
        .w31(w31),
        .w32(w32),
        .b1(b1),
        .b2(b2),
        .b3(b3),
        .h1(h1),
        .h2(h2),
        .y(y),
        .w11_out(w11_out),
        .w12_out(w12_out),
        .w21_out(w21_out),
        .w22_out(w22_out),
        .w31_out(w31_out),
        .w32_out(w32_out),
        .b1_out(b1_out),
        .b2_out(b2_out),
        .b3_out(b3_out),
        .fp_valid(fp_valid)
    );
    
    // 生成时钟
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz时钟
    end
    
    // 格式化输出函数
    function [15:0] fixed_to_float;
        input [15:0] fixed;
        real float_val;
        begin
            float_val = $itor(fixed) / 256.0;
            $display("Fixed: %h, Float: %f", fixed, float_val);
            fixed_to_float = fixed;
        end
    endfunction
    
    // 测试XOR函数
    initial begin
        // 初始化
        rst = 1;
        enable_fp = 0;
        x1 = 16'h0000;
        x2 = 16'h0000;
        
        // 使用预训练权重实现XOR功能
        // 第一层
        w11 = 16'h0600;  // 6.0 in 8.8
        w12 = 16'h0600;  // 6.0 in 8.8
        w21 = 16'h0600;  // 6.0 in 8.8
        w22 = 16'h0600;  // 6.0 in 8.8
        b1 = 16'hFC00;   // -4.0 in 8.8 (隐藏神经元1的偏置)
        b2 = 16'hF900;   // -7.0 in 8.8 (隐藏神经元2的偏置)
        
        // 第二层
        w31 = 16'h0C00;  // 12.0 in 8.8
        w32 = 16'h0C00;  // -12.0 in 8.8
        b3 = 16'hFE00;   // -2.0 in 8.8 (输出神经元的偏置)
        
        // 复位系统
        #20;
        rst = 0;
        #20;
        
        // 测试用例1: x1=0, x2=0 (应输出0)
        test_count = 1;
        x1 = 16'h0000;  // 0 in 8.8 format
        x2 = 16'h0000;  // 0 in 8.8 format
        #10;
        $display("Starting Test %0d: XOR for inputs: x1=0, x2=0", test_count);
        enable_fp = 1;
        wait(fp_valid);
        #20;
        enable_fp = 0;
        $display("Test %0d: Output y = %h (%.3f)", test_count, y, $itor(y) / 256.0);
        #100;  
        
        // 测试用例2: x1=0, x2=1 (应输出1)
        test_count = 2;
        x1 = 16'h0000;  // 0 in 8.8 format
        x2 = 16'h0100;  // 1 in 8.8 format
        #10;
        $display("Starting Test %0d: XOR for inputs: x1=0, x2=1", test_count);
        rst = 1;
        #10;
        rst = 0;
        #10;
        enable_fp = 1;
        wait(fp_valid);
        #20;
        enable_fp = 0;
        $display("Test %0d: Output y = %h (%.3f)", test_count, y, $itor(y) / 256.0);
        #100;
        
        // 测试用例3: x1=1, x2=0 (应输出1)
        test_count = 3;
        x1 = 16'h0100;  // 1 in 8.8 format
        x2 = 16'h0000;  // 0 in 8.8 format
        #10;
        $display("Starting Test %0d: XOR for inputs: x1=1, x2=0", test_count);
        rst = 1;
        #10;
        rst = 0;
        #10;
        enable_fp = 1;
        wait(fp_valid);
        #20;
        enable_fp = 0;
        $display("Test %0d: Output y = %h (%.3f)", test_count, y, $itor(y) / 256.0);
        #100;
        
        // 测试用例4: x1=1, x2=1 (应输出0)
        test_count = 4;
        x1 = 16'h0100;  // 1 in 8.8 format
        x2 = 16'h0100;  // 1 in 8.8 format
        #10;
        $display("Starting Test %0d: XOR for inputs: x1=1, x2=1", test_count);
        rst = 1;
        #10;
        rst = 0;
        #10;
        enable_fp = 1;
        wait(fp_valid);
        #20;
        enable_fp = 0;
        $display("Test %0d: Output y = %h (%.3f)", test_count, y, $itor(y) / 256.0);
        #100;
        
        // 附加测试用例5: x1=0, x2=0 (重复测试)
        test_count = 5;
        x1 = 16'h0000;  // 0 in 8.8 format
        x2 = 16'h0000;  // 0 in 8.8 format
        #10;
        $display("Starting Test %0d: XOR for inputs: x1=0, x2=0 (重复测试)", test_count);
        rst = 1;
        #10;
        rst = 0;
        #10;
        enable_fp = 1;
        wait(fp_valid);
        #20;
        enable_fp = 0;
        $display("Test %0d: Output y = %h (%.3f)", test_count, y, $itor(y) / 256.0);
        #100;
        
        // 附加测试用例6: x1=1, x2=1 (重复测试)
        test_count = 6;
        x1 = 16'h0100;  // 1 in 8.8 format
        x2 = 16'h0100;  // 1 in 8.8 format
        #10;
        $display("Starting Test %0d: XOR for inputs: x1=1, x2=1 (重复测试)", test_count);
        rst = 1;
        #10;
        rst = 0;
        #10;
        enable_fp = 1;
        wait(fp_valid);
        #20;
        enable_fp = 0;
        $display("Test %0d: Output y = %h (%.3f)", test_count, y, $itor(y) / 256.0);
        #100;
        
        $display("All tests completed");
        $finish;
    end
    
    // 监控输出
    initial begin
        $monitor("Time: %t, Test: %d, x1=%h, x2=%h, h1=%h, h2=%h, y=%h, fp_valid=%b", 
                  $time, test_count, x1, x2, h1, h2, y, fp_valid);
    end
    
endmodule
    
