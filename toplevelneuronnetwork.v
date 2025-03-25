module xor_nn_top (
    input clk,
    input rst,
    input start_training,
    input signed [15:0] x1_in, x2_in,    // Input values
    input signed [15:0] target_in,       // Target output
    output reg signed [15:0] y_out,      // Neural network output
    output reg training_done             // Training completion flag
);

    // State machine definition
    localparam IDLE          = 3'd0;
    localparam FORWARD_PASS  = 3'd1;
    localparam WAIT_FP       = 3'd2;
    localparam BACKWARD_PASS = 3'd3;
    localparam WAIT_BP       = 3'd4;
    localparam UPDATE_WEIGHTS = 3'd5;
    localparam CHECK_DONE    = 3'd6;
    localparam TRAIN_DONE    = 3'd7;
    
    reg [2:0] state, next_state;
    
    // Control signals
    reg enable_fp;
    reg enable_bp;
    
    // Internal registers for inputs and outputs
    reg signed [15:0] x1, x2, target;
    
    // Weights and biases - stored in the top module
    reg signed [15:0] w11_reg, w12_reg, w21_reg, w22_reg, w31_reg, w32_reg;
    reg signed [15:0] b1_reg, b2_reg, b3_reg;
    
    // Learning rate
    reg signed [15:0] learning_rate;
    
    // Intermediate signals
    wire signed [15:0] h1, h2, y;
    wire signed [15:0] w11_fp_out, w12_fp_out, w21_fp_out, w22_fp_out, w31_fp_out, w32_fp_out;
    wire signed [15:0] b1_fp_out, b2_fp_out, b3_fp_out;
    wire fp_valid;
    
    wire signed [15:0] w11_bp_out, w12_bp_out, w21_bp_out, w22_bp_out, w31_bp_out, w32_bp_out;
    wire signed [15:0] b1_bp_out, b2_bp_out, b3_bp_out;
    wire weight_new_valid, bias_new_valid, bp_done;
    
    // Iteration counter
    reg [15:0] iteration_count;
    reg [15:0] max_iterations;
    
    // Instantiate forward propagation module
    forward_propagation fp_module (
        .clk(clk),
        .rst(rst),
        .enable_fp(enable_fp),
        .x1(x1),
        .x2(x2),
        .w11(w11_reg),
        .w12(w12_reg),
        .w21(w21_reg),
        .w22(w22_reg),
        .w31(w31_reg),
        .w32(w32_reg),
        .b1(b1_reg),
        .b2(b2_reg),
        .b3(b3_reg),
        .h1(h1),
        .h2(h2),
        .y(y),
        .w11_out(w11_fp_out),
        .w12_out(w12_fp_out),
        .w21_out(w21_fp_out),
        .w22_out(w22_fp_out),
        .w31_out(w31_fp_out),
        .w32_out(w32_fp_out),
        .b1_out(b1_fp_out),
        .b2_out(b2_fp_out),
        .b3_out(b3_fp_out),
        .fp_valid(fp_valid)
    );
    
    // Instantiate backpropagation module
    backpropagation bp_module (
        .clk(clk),
        .rst(rst),
        .enable_bp(enable_bp),
        .target(target),
        .x1(x1),
        .x2(x2),
        .h1(h1),
        .h2(h2),
        .y(y),
        .w11_in(w11_fp_out),
        .w12_in(w12_fp_out),
        .w21_in(w21_fp_out),
        .w22_in(w22_fp_out),
        .w31_in(w31_fp_out),
        .w32_in(w32_fp_out),
        .b1_in(b1_fp_out),
        .b2_in(b2_fp_out),
        .b3_in(b3_fp_out),
        .learning_rate(learning_rate),
        .w11_out(w11_bp_out),
        .w12_out(w12_bp_out),
        .w21_out(w21_bp_out),
        .w22_out(w22_bp_out),
        .w31_out(w31_bp_out),
        .w32_out(w32_bp_out),
        .b1_out(b1_bp_out),
        .b2_out(b2_bp_out),
        .b3_out(b3_bp_out),
        .weight_new_valid(weight_new_valid),
        .bias_new_valid(bias_new_valid),
        .done(bp_done)
    );
    
    // State transition logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: 
                next_state = start_training ? FORWARD_PASS : IDLE;
            FORWARD_PASS: 
                next_state = WAIT_FP;
            WAIT_FP: 
                next_state = fp_valid ? BACKWARD_PASS : WAIT_FP;
            BACKWARD_PASS: 
                next_state = WAIT_BP;
            WAIT_BP: 
                next_state = weight_new_valid ? UPDATE_WEIGHTS : WAIT_BP;
            UPDATE_WEIGHTS:
                next_state = CHECK_DONE;
            CHECK_DONE: 
                next_state = (iteration_count == 28) ? TRAIN_DONE : FORWARD_PASS;
            TRAIN_DONE: 
                next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // Main control logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all control signals
            enable_fp <= 0;
            enable_bp <= 0;
            training_done <= 0;
            y_out <= 16'd0;
            
            // Reset input registers
            x1 <= 16'd0;
            x2 <= 16'd0;
            target <= 16'd0;
            
            // Initialize weights with values appropriate for XOR problem
            // These are in 8.8 fixed-point format
            w11_reg <= 16'h00a3;  // 0.5
            w12_reg <= 16'hff5d;   // 0.25
            w21_reg <= 16'hff5d;  // 0.75
            w22_reg <= 16'h00a3;  // 0.625
            w31_reg <= 16'h0080;  // 0.875
            w32_reg <= 16'h0078;   // 0.375
            
            // Initialize biases
            b1_reg <= 16'h0019;    // 0.125
            b2_reg <= 16'h0020;   // -0.125
            b3_reg <= 16'hff80;    // 0.0625
            
            // Set learning rate (0.25 in 8.8 format)
            learning_rate <= 16'd1;
            
            // Initialize iteration counter
            iteration_count <= 16'd0;
            max_iterations <= 16'd1000; // Maximum 1000 iterations
            
        end else begin
            // Default values
            enable_fp <= 0;
            enable_bp <= 0;
            
            case (state)
                IDLE: begin
                    if (start_training) begin
                        // Capture input values
                        x1 <= x1_in;
                        x2 <= x2_in;
                        target <= target_in;
                        training_done <= 0;
                    end
                end
                
                FORWARD_PASS: begin
                    // Enable forward propagation
                    enable_fp <= 1;
                end
                
                WAIT_FP: begin
                    // Wait for forward propagation to complete
                    enable_fp <= 0;
                    if (fp_valid) begin
                        y_out <= y; // Update output
                    end
                end
                
                BACKWARD_PASS: begin
                    // Enable backpropagation
                    enable_bp <= 1;
                end
                
                WAIT_BP: begin
                    // Wait for backpropagation to complete
                    enable_bp <= 0;
                end
                
                UPDATE_WEIGHTS: begin
                    // Update weights and biases with new values
                    
                        w11_reg <= w11_bp_out;
                        w12_reg <= w12_bp_out;
                        w21_reg <= w21_bp_out;
                        w22_reg <= w22_bp_out;
                        w31_reg <= w31_bp_out;
                        w32_reg <= w32_bp_out;
                    
                    
                    
                        b1_reg <= b1_bp_out;
                        b2_reg <= b2_bp_out;
                        b3_reg <= b3_bp_out;
                    
                end
                
                CHECK_DONE: begin
                    // Increment iteration counter
                    iteration_count <= iteration_count + 1;
                    
                    // Check if training is done
                    if (iteration_count == 28) begin
                        training_done <= 1;
                    end
                end
                
                TRAIN_DONE: begin
                    // Keep training_done flag high
                    training_done <= 1;
                    // Reset iteration counter for next training session
                    iteration_count <= 16'd0;
                end
            endcase
        end
    end
    
endmodule