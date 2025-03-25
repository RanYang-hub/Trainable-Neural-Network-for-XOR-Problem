`timescale 1ns / 1ps

module xor_nn_top_tb;
    // Clock and reset signals
    reg clk;
    reg rst;
    
    // Control signals
    reg start_training;
    
    // Input signals
    reg signed [15:0] x1_in, x2_in;
    reg signed [15:0] target_in;
    
    // Output signals
    wire signed [15:0] y_out;
    wire training_done;
    
    // XOR training data (in 8.8 fixed-point format)
    reg signed [15:0] xor_inputs [0:1][0:1];
    reg signed [15:0] xor_targets [0:1];
    
    // Loop variables
    integer i, j;
    integer error_cycle;
    
    // Instantiate the design under test
    xor_nn_top dut (
        .clk(clk),
        .rst(rst),
        .start_training(start_training),
        .x1_in(x1_in),
        .x2_in(x2_in),
        .target_in(target_in),
        .y_out(y_out),
        .training_done(training_done)
    );
    
    // Clock generation, period = 10ns
    always #5 clk = ~clk;
    
    initial begin
        error_cycle = 0;
    end
    
    always @(posedge clk) begin
        if (dut.state == dut.CHECK_DONE && dut.next_state == dut.FORWARD_PASS) begin
            error_cycle = error_cycle + 1;
        end
    end
    
    // Test process
    initial begin
        // Initialize all signals
        clk = 0;
        rst = 1;
        start_training = 0;
        x1_in = 0;
        x2_in = 0;
        target_in = 0;
        
        // Initialize only (0,1) and (1,0) XOR training data
        // Pattern 0: (0,1) => 1
        xor_inputs[0][0] = 16'd0;    // 0
        xor_inputs[0][1] = 16'd256;  // 1 (1.0 in 8.8 format)
        xor_targets[0] = 16'd256;    // 1
        
        // Pattern 1: (1,0) => 1
        xor_inputs[1][0] = 16'd256;  // 1
        xor_inputs[1][1] = 16'd0;    // 0
        xor_targets[1] = 16'd256;    // 1
        
        // Apply reset
        #20 rst = 0;
        #20;
        
        // Override default max iterations with custom parameter
        @(posedge clk);
        dut.max_iterations <= 16'd12; 
        
        // Start training process - 20 rounds with specific XOR cases at certain rounds
        for (i = 0; i < 15; i = i + 1) begin 
            for (j = 0; j < 2; j = j + 1) begin
                // Set training inputs
                @(posedge clk);
                
                // Modify inputs for specific rounds
                if (i == 4 && j == 0) begin
                    // 5th round, first input: (0,0) -> 0
                    x1_in = 16'd0;
                    x2_in = 16'd0;
                    target_in = 16'd0;
                end else if (i == 9 && j == 0) begin
                    // 10th round, first input: (1,1) -> 0
                    x1_in = 16'd256;
                    x2_in = 16'd256;
                    target_in = 16'd0;
                end else if (i == 12 && j == 0) begin
                    // 13th round, first input: (0,0) -> 0
                    x1_in = 16'd0;
                    x2_in = 16'd0;
                    target_in = 16'd0;
                end else if (j == 0) begin
                    // Normal pattern 1: (0,1) -> 1
                    x1_in = xor_inputs[0][0];
                    x2_in = xor_inputs[0][1];
                    target_in = xor_targets[0];
                end else begin
                    // Normal pattern 2: (1,0) -> 1
                    x1_in = xor_inputs[1][0];
                    x2_in = xor_inputs[1][1];
                    target_in = xor_targets[1];
                end
                
                start_training = 1;
                
                // Deassert start_training after one clock cycle
                @(posedge clk);
                start_training = 0;
                
                // Wait for current training sample to complete
                wait(dut.state == dut.CHECK_DONE);
                @(posedge clk);
            end
        end
        
        // Wait for training to complete
        wait(training_done);
        #20;
        
        // Print final weights
        $display("w11=%0.4f, w12=%0.4f, w21=%0.4f, w22=%0.4f, w31=%0.4f, w32=%0.4f",
                 $itor(dut.w11_reg)/256.0, $itor(dut.w12_reg)/256.0,
                 $itor(dut.w21_reg)/256.0, $itor(dut.w22_reg)/256.0,
                 $itor(dut.w31_reg)/256.0, $itor(dut.w32_reg)/256.0);
        $display("b1=%0.4f, b2=%0.4f, b3=%0.4f",
                 $itor(dut.b1_reg)/256.0, $itor(dut.b2_reg)/256.0,
                 $itor(dut.b3_reg)/256.0);
        
        // End simulation
        #100 $finish;
    end
    

    
    
    
