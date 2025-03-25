`timescale 1ns / 1ps

module backpropagation_tb;
    // Clock and reset signals
    reg clk;
    reg rst;
    
    // BP module control signals
    reg enable_bp;
    
    // Training mode selection (4-bit)
    reg [3:0] train;
    
    // Network inputs, outputs and targets
    reg signed [15:0] x1, x2;
    reg signed [15:0] h1, h2, y;
    reg signed [15:0] target;
    
    // Network weights and biases
    reg signed [15:0] w11, w12, w21, w22, w31, w32;
    reg signed [15:0] b1, b2, b3;
    
    // Learning rate
    reg signed [15:0] learning_rate;
    
    // Updated weights and biases
    wire signed [15:0] w11_out, w12_out, w21_out, w22_out, w31_out, w32_out;
    wire signed [15:0] b1_out, b2_out, b3_out;
    
    // Control flags
    wire weight_new_valid, bias_new_valid, done;
    
    // Training cases - fixed and alternating
    reg signed [15:0] fixed_x1, fixed_x2, fixed_target;     // (1,1) -> 1 for Mode 1
    reg signed [15:0] input1_x1, input1_x2, output1_target; // (0,1) -> 1 for Mode 2
    reg signed [15:0] input2_x1, input2_x2, output2_target; // (1,0) -> 1 for Mode 2
    
    // Mode 3: Training cases (1,1) -> 0 and (0,0) -> 0
    reg signed [15:0] input3_x1, input3_x2, output3_target; // (1,1) -> 0
    reg signed [15:0] input4_x1, input4_x2, output4_target; // (0,0) -> 0
    
    // XOR training cases for Mode 4
    reg signed [15:0] xor_inputs [0:3][0:1];
    reg signed [15:0] xor_targets [0:3];
    
    // Current input case
    reg signed [15:0] input_x1, input_x2, output_target;
    
    // Loop variables
    integer round, max_rounds, pattern_idx;
    
    // Sigmoid function implementation for test generation
    function signed [15:0] sigmoid;
        input signed [31:0] x;
        real float_x, result;
        begin
            float_x = $itor(x) / 256.0;
            result = 1.0 / (1.0 + $exp(-float_x));
            sigmoid = $rtoi(result * 256.0);
        end
    endfunction
    
    // Instantiate the backpropagation module
    backpropagation dut (
        .clk(clk),
        .rst(rst),
        .enable_bp(enable_bp),
        .target(target),
        .x1(x1),
        .x2(x2),
        .h1(h1),
        .h2(h2),
        .y(y),
        .w11_in(w11),
        .w12_in(w12),
        .w21_in(w21),
        .w22_in(w22),
        .w31_in(w31),
        .w32_in(w32),
        .b1_in(b1),
        .b2_in(b2),
        .b3_in(b3),
        .learning_rate(learning_rate),
        .w11_out(w11_out),
        .w12_out(w12_out),
        .w21_out(w21_out),
        .w22_out(w22_out),
        .w31_out(w31_out),
        .w32_out(w32_out),
        .b1_out(b1_out),
        .b2_out(b2_out),
        .b3_out(b3_out),
        .weight_new_valid(weight_new_valid),
        .bias_new_valid(bias_new_valid),
        .done(done)
    );
    
    // Clock generation, period = 10ns
    always #5 clk = ~clk;
    
    // Compute network activations for the specified inputs

    // Test process
    initial begin
        // Initialize signals
        clk = 0;
        rst = 1;
        enable_bp = 0;
        round = 0;
        pattern_idx = 0;
        
        train = 4'd2; 
        w11 = 16'd32;    // 0.125
        w12 = 16'd16;    // 0.0625
        w21 = 16'd32;    // 0.125
        w22 = 16'd24;    // 0.09375
        w31 = 16'd20;    // 0.078125
        w32 = 16'd20;    // 0.078125
        
        b1 = 16'd8;      // 0.03125
        b2 = 16'd8;      // 0.03125
        b3 = 16'd4;      // 0.015625
        
        // Set learning rate
        learning_rate = 16'd3;  // 0.01171875
        // Set fixed input for Mode 1
        fixed_x1 = 16'd256;    // 1.0
        fixed_x2 = 16'd256;    // 1.0
        fixed_target = 16'd256; // 1.0
        
        // Set alternating inputs for Mode 2
        // Pattern 1: (0,1) -> 1
        input1_x1 = 16'd0;     // 0.0
        input1_x2 = 16'd256;   // 1.0
        output1_target = 16'd256; // 1.0
        
        // Pattern 2: (1,0) -> 1
        input2_x1 = 16'd256;   // 1.0
        input2_x2 = 16'd0;     // 0.0
        output2_target = 16'd256; // 1.0
        
        // Set alternating inputs for Mode 3
        // Pattern 3: (1,1) -> 0
        input3_x1 = 16'd256;   // 1.0
        input3_x2 = 16'd256;   // 1.0
        output3_target = 16'd0; // 0.0
        
        // Pattern 4: (0,0) -> 0
        input4_x1 = 16'd0;     // 0.0
        input4_x2 = 16'd0;     // 0.0
        output4_target = 16'd0; // 0.0
        
        // Initialize XOR patterns for Mode 4
        // (0,0) -> 0
        xor_inputs[0][0] = 16'd0;    // 0.0
        xor_inputs[0][1] = 16'd0;    // 0.0
        xor_targets[0] = 16'd0;      // 0.0
        
        // (0,1) -> 1
        xor_inputs[1][0] = 16'd0;    // 0.0
        xor_inputs[1][1] = 16'd256;  // 1.0
        xor_targets[1] = 16'd256;    // 1.0
        
        // (1,0) -> 1
        xor_inputs[2][0] = 16'd256;  // 1.0
        xor_inputs[2][1] = 16'd0;    // 0.0
        xor_targets[2] = 16'd256;    // 1.0
        
        // (1,1) -> 0
        xor_inputs[3][0] = 16'd256;  // 1.0
        xor_inputs[3][1] = 16'd256;  // 1.0
        xor_targets[3] = 16'd0;      // 0.0
        
        // Initialize weights and biases with small values

        
        // Set max rounds based on training mode
        case (train)
            4'd1: max_rounds = 17;    // 17 rounds for mode 1
            4'd2: max_rounds = 40;    // 40 rounds for mode 2
            4'd3: max_rounds = 40;    // 40 rounds for mode 3 ((1,1)->0 and (0,0)->0)
            4'd4: max_rounds = 100;   // 100 rounds for mode 4 (XOR)
            default: max_rounds = 17; // Default to 17
        endcase
        
        // Apply reset
        #20 rst = 0;
        #10;
        
        // Show initial network state
        $display("Initial Network State:");
        
        // For Mode 4 (XOR training), evaluate all 4 patterns initially
        if (train == 4'd4) begin
            $display("Initial XOR Performance:");
            for (round = 0; round < 4; round = round + 1) begin
                input_x1 = xor_inputs[round][0];
                input_x2 = xor_inputs[round][1];
                output_target = xor_targets[round];
                compute_activations();
                $display("XOR(%0.1f, %0.1f) = %0.4f (Expected: %0.1f)",
                         $itor(input_x1)/256.0, 
                         $itor(input_x2)/256.0,
                         $itor(y)/256.0, 
                         $itor(output_target)/256.0);
            end
            $display("-----------------------------------------------------------");
            round = 0; // Reset counter for training
        end else if (train == 4'd3) begin
            // For Mode 3, show initial predictions for both patterns
            // Check pattern 3: (1,1) -> 0
            input_x1 = input3_x1;
            input_x2 = input3_x2;
            output_target = output3_target;
            compute_activations();
            display_network_state("Initial prediction for (1,1) -> 0");
            
            // Check pattern 4: (0,0) -> 0
            input_x1 = input4_x1;
            input_x2 = input4_x2;
            output_target = output4_target;
            compute_activations();
            display_network_state("Initial prediction for (0,0) -> 0");
        end else if (train == 4'd2) begin
            // For Mode 2, check both patterns
            // Check pattern 1: (0,1) -> 1
            input_x1 = input1_x1;
            input_x2 = input1_x2;
            output_target = output1_target;
            compute_activations();
            display_network_state("Initial prediction for (0,1) -> 1");
            
            // Check pattern 2: (1,0) -> 1
            input_x1 = input2_x1;
            input_x2 = input2_x2;
            output_target = output2_target;
            compute_activations();
            display_network_state("Initial prediction for (1,0) -> 1");
        end else begin
            // For Mode 1, just show the fixed input prediction
            input_x1 = fixed_x1;
            input_x2 = fixed_x2;
            output_target = fixed_target;
            compute_activations();
            display_network_state("Initial prediction");
        end
        
        // Train for the specified number of rounds
        for (round = 0; round < max_rounds; round = round + 1) begin
            $display("Training Round %0d", round + 1);
            train_one_round();
            
            // For XOR training, only display full network state every 10 rounds to reduce output
            if (train == 4'd4) begin
                if ((round + 1) % 10 == 0 || (round + 1) == max_rounds) begin
                    display_network_state("After Round:");
                end else begin
                    $display("Round %0d - Output: %0.4f, Error: %0.4f", 
                           round + 1, 
                           $itor(y)/256.0,
                           $itor((output_target > y) ? (output_target - y) : (y - output_target)) * 
                           $itor((output_target > y) ? (output_target - y) : (y - output_target)) / 256.0);
                    $display("-----------------------------------------------------------");
                end
            end else begin
                display_network_state("After Round:");
            end
            
            // Wait between rounds
            #20;
        end
        
        // Final evaluation
        $display("Final Network Evaluation:");
        
        // For Mode 4 (XOR), evaluate all 4 XOR patterns
        if (train == 4'd4) begin
            $display("Final XOR Performance:");
            for (round = 0; round < 4; round = round + 1) begin
                input_x1 = xor_inputs[round][0];
                input_x2 = xor_inputs[round][1];
                output_target = xor_targets[round];
                compute_activations();
                $display("XOR(%0.1f, %0.1f) = %0.4f (Expected: %0.1f)",
                         $itor(input_x1)/256.0, 
                         $itor(input_x2)/256.0,
                         $itor(y)/256.0, 
                         $itor(output_target)/256.0);
            end
            $display("-----------------------------------------------------------");
        end else if (train == 4'd3) begin
            // For Mode 3, check both patterns
            // Check pattern 3: (1,1) -> 0
            input_x1 = input3_x1;
            input_x2 = input3_x2;
            output_target = output3_target;
            compute_activations();
            display_network_state("Final prediction for (1,1) -> 0");
            
            // Check pattern 4: (0,0) -> 0
            input_x1 = input4_x1;
            input_x2 = input4_x2;
            output_target = output4_target;
            compute_activations();
            display_network_state("Final prediction for (0,0) -> 0");
        end else if (train == 4'd2) begin
            // For Mode 2, check both patterns
            // Check pattern 1: (0,1) -> 1
            input_x1 = input1_x1;
            input_x2 = input1_x2;
            output_target = output1_target;
            compute_activations();
            display_network_state("Final prediction for (0,1) -> 1");
            
            // Check pattern 2: (1,0) -> 1
            input_x1 = input2_x1;
            input_x2 = input2_x2;
            output_target = output2_target;
            compute_activations();
            display_network_state("Final prediction for (1,0) -> 1");
        end else begin
            // For Mode 1, just show the fixed input prediction
            input_x1 = fixed_x1;
            input_x2 = fixed_x2;
            output_target = fixed_target;
            compute_activations();
            display_network_state("Final prediction");
        end
        
        // End simulation
        #100 $finish;
    end
    
    // Display detailed states for debugging (optional)
    always @(posedge clk) begin
        if (dut.state != dut.IDLE) begin
            $display("BP State: %d", dut.state);
        end
        if (weight_new_valid) begin
            $display("Weights updated");
        end
        
        if (done) begin
            $display("Training done flag set");
        end
    end
        task display_network_state;
        input [63:0] message;
        begin
            $display("%s", message);
            $display("Weights: w11=%0.4f, w12=%0.4f, w21=%0.4f, w22=%0.4f, w31=%0.4f, w32=%0.4f", 
                     $itor(w11)/256.0, $itor(w12)/256.0, 
                     $itor(w21)/256.0, $itor(w22)/256.0, 
                     $itor(w31)/256.0, $itor(w32)/256.0);
            $display("Biases:  b1=%0.4f, b2=%0.4f, b3=%0.4f",
                     $itor(b1)/256.0, $itor(b2)/256.0, $itor(b3)/256.0);
            $display("Input=(%0.1f,%0.1f), Target=%0.1f, Current Output=%0.4f, Error=%0.4f",
                     $itor(input_x1)/256.0, $itor(input_x2)/256.0,
                     $itor(output_target)/256.0, $itor(y)/256.0,
                     $itor((output_target > y) ? (output_target - y) : (y - output_target)) * 
                     $itor((output_target > y) ? (output_target - y) : (y - output_target)) / 256.0);
            $display("-----------------------------------------------------------");
        end
    endtask
    

task train_one_round;
    begin
        if (train == 4'd1) begin
            // Mode 1: Fixed (1,1) -> 1 input for all rounds
            input_x1 = fixed_x1;
            input_x2 = fixed_x2;
            output_target = fixed_target;
            
            if (round == 0) begin
                $display("Using fixed input pattern: (1,1) -> 1 for all rounds");
            end
            
            compute_activations();
            x1 = input_x1;
            x2 = input_x2;
            target = output_target;
            enable_bp = 1;
            @(posedge clk);
            enable_bp = 0;
            while (!weight_new_valid) @(posedge clk);
            @(posedge clk);
            w11 = w11_out;
            w12 = w12_out;
            w21 = w21_out;
            w22 = w22_out;
            w31 = w31_out;
            w32 = w32_out;
            b1 = b1_out;
            b2 = b2_out;
            b3 = b3_out;
        end else if (train == 4'd2) begin
            // Mode 2: Alternating inputs (0,1) -> 1 and (1,0) -> 1
            if (round % 2 == 0) begin
                // Use (0,1) -> 1 for even rounds
                input_x1 = input1_x1;
                input_x2 = input1_x2;
                output_target = output1_target;
                $display("Using input pattern: (0,1) -> 1");
            end else begin
                // Use (1,0) -> 1 for odd rounds
                input_x1 = input2_x1;
                input_x2 = input2_x2;
                output_target = output2_target;
                $display("Using input pattern: (1,0) -> 1");
            end
            
            compute_activations();
            x1 = input_x1;
            x2 = input_x2;
            target = output_target;
            enable_bp = 1;
            @(posedge clk);
            enable_bp = 0;
            while (!weight_new_valid) @(posedge clk);
            @(posedge clk);
            w11 = w11_out;
            w12 = w12_out;
            w21 = w21_out;
            w22 = w22_out;
            w31 = w31_out;
            w32 = w32_out;
            b1 = b1_out;
            b2 = b2_out;
            b3 = b3_out;
        end 
        compute_activations();
    end
endtask

    task compute_activations;
        reg signed [31:0] h1_sum, h2_sum, y_sum;
        begin
            // Compute hidden layer pre-activations
            h1_sum = ((w11 * input_x1) >>> 8) + ((w12 * input_x2) >>> 8) + b1;
            h2_sum = ((w21 * input_x1) >>> 8) + ((w22 * input_x2) >>> 8) + b2;
            
            // Apply ReLU (max(0,x)) for hidden layers
            h1 = (h1_sum[31] == 1'b0) ? h1_sum[15:0] : 16'd0;
            h2 = (h2_sum[31] == 1'b0) ? h2_sum[15:0] : 16'd0;
            
            // Compute output layer pre-activation
            y_sum = ((w31 * h1) >>> 8) + ((w32 * h2) >>> 8) + b3;
            
            // Apply sigmoid for output layer
            y = sigmoid(y_sum);
        end
    endtask
    
endmodule