module backpropagation (
    input clk,
    input rst,
    input enable_bp,
    input signed [15:0] target,        // Target output (8.8 fixed-point)
    input signed [15:0] x1, x2,        // Input values
    input signed [15:0] h1, h2, y,     // Hidden layer and output activations
    input signed [15:0] w11_in, w12_in, w21_in, w22_in, w31_in, w32_in, // Input weights
    input signed [15:0] b1_in, b2_in, b3_in,  // Input biases
    input signed [15:0] learning_rate,  // Learning rate (8.8 fixed-point)
    output reg signed [15:0] w11_out, w12_out, w21_out, w22_out, w31_out, w32_out, // Updated weights
    output reg signed [15:0] b1_out, b2_out, b3_out,  // Updated biases
    output reg weight_new_valid,  // Weight update valid flag
    output reg bias_new_valid,    // Bias update valid flag
    output reg done               // Training completion flag
);

    // Define states for state machine
    localparam IDLE = 4'd0;
    localparam COMPUTE_ERROR = 4'd1;
    localparam CHECK_DONE = 4'd2;
    localparam COMPUTE_DELTA3 = 4'd3;
    localparam COMPUTE_DELTA_TEMP = 4'd4;  // Calculate delta_temp
    localparam COMPUTE_DELTA12 = 4'd5;     // Update delta1 and delta2
    localparam COMPUTE_UPDATE_TEMP = 4'd6; // Calculate temporary weight update values
    localparam UPDATE_WEIGHTS = 4'd7;      // Apply weight updates
    localparam SET_FLAGS = 4'd8;
    localparam CLEAR_FLAGS = 4'd9;
    
    // State registers
    reg [3:0] state, next_state;
    
    // Intermediate variables
    reg signed [15:0] delta3, delta1, delta2;
    reg signed [15:0] temp, error;
    reg signed [31:0] delta1_temp, delta2_temp;
    
    // Create separate temporary variables for each weight update
    reg signed [31:0] w11_update_temp;
    reg signed [31:0] w12_update_temp;
    reg signed [31:0] w21_update_temp;
    reg signed [31:0] w22_update_temp;
    reg signed [31:0] w31_update_temp;
    reg signed [31:0] w32_update_temp;
    reg signed [31:0] b1_update_temp;
    reg signed [31:0] b2_update_temp;
    reg signed [31:0] b3_update_temp;

    // Sigmoid derivative function (simplified)
    // For sigmoid(x), the derivative is sigmoid(x)*(1-sigmoid(x))
    // In 8.8 fixed-point, this is: y * (256 - y) / 256
    function signed [15:0] sigmoid_derivative;
        input signed [15:0] sig_value;
        begin
            // sig_value is already the sigmoid output in 8.8 format
            // Calculate sig_value * (1 - sig_value)
            sigmoid_derivative = ((sig_value * (16'd256 - sig_value)) + 16'd128) >>> 8;
        end
    endfunction

    // State transition logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    // Combinational logic to determine the next state
    always @(*) begin
        case (state)
            IDLE: 
                next_state = enable_bp ? COMPUTE_ERROR : IDLE;
            COMPUTE_ERROR: 
                next_state = CHECK_DONE;
            CHECK_DONE: 
                next_state = (error < 16'd1) ? SET_FLAGS : COMPUTE_DELTA3; // Error threshold adjusted
            COMPUTE_DELTA3: 
                next_state = COMPUTE_DELTA_TEMP;
            COMPUTE_DELTA_TEMP:
                next_state = COMPUTE_DELTA12;
            COMPUTE_DELTA12: 
                next_state = COMPUTE_UPDATE_TEMP;
            COMPUTE_UPDATE_TEMP:
                next_state = UPDATE_WEIGHTS;
            UPDATE_WEIGHTS: 
                next_state = SET_FLAGS;
            SET_FLAGS: 
                next_state = CLEAR_FLAGS;
            CLEAR_FLAGS: 
                next_state = IDLE;
            default: 
                next_state = IDLE;
        endcase
    end
    
    // State machine operation logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all registers and flags
            done <= 0;
            weight_new_valid <= 0;
            bias_new_valid <= 0;
            delta3 <= 16'd0;
            delta1 <= 16'd0;
            delta2 <= 16'd0;
            temp <= 16'd0;
            error <= 16'd0;
            delta1_temp <= 32'd0;
            delta2_temp <= 32'd0;
            
            // Reset all temporary update variables
            w11_update_temp <= 32'd0;
            w12_update_temp <= 32'd0;
            w21_update_temp <= 32'd0;
            w22_update_temp <= 32'd0;
            w31_update_temp <= 32'd0;
            w32_update_temp <= 32'd0;
            b1_update_temp <= 32'd0;
            b2_update_temp <= 32'd0;
            b3_update_temp <= 32'd0;
            
            w11_out <= 16'd0;
            w12_out <= 16'd0;
            w21_out <= 16'd0;
            w22_out <= 16'd0;
            w31_out <= 16'd0;
            w32_out <= 16'd0;
            b1_out <= 16'd0;
            b2_out <= 16'd0;
            b3_out <= 16'd0;
        end else begin
            // Default value settings
            done <= done;  // Maintain current value
            weight_new_valid <= 0;  // Default to 0, only set to 1 in specific state
            bias_new_valid <= 0;    // Default to 0, only set to 1 in specific state
            
            case (state)
                IDLE: begin
                    // In idle state, reset partial variables but keep outputs
                    if (enable_bp) begin
                        delta3 <= 16'd0;
                        delta1 <= 16'd0;
                        delta2 <= 16'd0;
                        temp <= 16'd0;
                        error <= 16'd0;
                        delta1_temp <= 32'd0;
                        delta2_temp <= 32'd0;
                        weight_new_valid <= 0;
                        bias_new_valid <= 0;
                        
                        // Reset all temporary update variables
                        w11_update_temp <= 32'd0;
                        w12_update_temp <= 32'd0;
                        w21_update_temp <= 32'd0;
                        w22_update_temp <= 32'd0;
                        w31_update_temp <= 32'd0;
                        w32_update_temp <= 32'd0;
                        b1_update_temp <= 32'd0;
                        b2_update_temp <= 32'd0;
                        b3_update_temp <= 32'd0;
                        
                        done <= 0;  // Reset done flag
                    end
                end
                
                COMPUTE_ERROR: begin
                    // Calculate error, check input validity
                    if (|target !== 1'bx && |y !== 1'bx) begin
                        temp <= target - y;
                        error <= ((target - y) * (target - y)); // Store full error without dividing
                    end else begin
                        temp <= 16'd0;
                        error <= 16'd0;
                    end
                end
                
                CHECK_DONE: begin
                    // Check if termination condition is reached (error < 1.0 in 8.8 format)
                    if (error < 16'd1) begin
                        done <= 1;
                    end
                end
                
                COMPUTE_DELTA3: begin
                    // Calculate output layer gradient for sigmoid output
                    // delta3 = (target - y) * sigmoid_derivative(y)
                    delta3 <= ((temp * sigmoid_derivative(y)) + 16'd128) >>> 8;
                end
                
                COMPUTE_DELTA_TEMP: begin
                    // Calculate delta_temp for hidden layer
                    delta1_temp <= delta3 * w31_in;
                    delta2_temp <= delta3 * w32_in;
                end
                
                COMPUTE_DELTA12: begin
                    // ReLU derivative for hidden layers
                    if (h1 > 16'd0) begin
                        delta1 <= (delta1_temp + 32'd128) >>> 8;
                    end else begin
                        delta1 <= 16'd128;
                    end
                    
                    if (h2 > 16'd0) begin
                        delta2 <= (delta2_temp + 32'd128) >>> 8;
                    end else begin
                        delta2 <= 16'd128;
                    end
                end
                
                COMPUTE_UPDATE_TEMP: begin
                    // Calculate all weight update temporary values
                    // Output layer weight updates
                    w31_update_temp <= learning_rate * delta3 * h1;
                    w32_update_temp <= learning_rate * delta3 * h2;
                    b3_update_temp <= learning_rate * delta3;
                    
                    // Hidden layer weight updates
                    w11_update_temp <= learning_rate * delta1 * x1;
                    w12_update_temp <= learning_rate * delta1 * x2;
                    b1_update_temp <= learning_rate * delta1;
                    
                    w21_update_temp <= learning_rate * delta2 * x1;
                    w22_update_temp <= learning_rate * delta2 * x2;
                    b2_update_temp <= learning_rate * delta2;
                end
                
                UPDATE_WEIGHTS: begin
                    // Apply calculated weight updates with rounding
                    // Update output layer weights and biases
                    w31_out <= w31_in + ((w31_update_temp + 32'd128) >>> 8);
                    w32_out <= w32_in + ((w32_update_temp + 32'd128) >>> 8);
                    b3_out <= b3_in + ((b3_update_temp + 32'd128) >>> 8);
                    
                    // Update hidden layer weights and biases
                    w11_out <= w11_in + ((w11_update_temp + 32'd128) >>> 8);
                    w12_out <= w12_in + ((w12_update_temp + 32'd128) >>> 8);
                    b1_out <= b1_in + ((b1_update_temp + 32'd128) >>> 8);
                    
                    w21_out <= w21_in + ((w21_update_temp + 32'd128) >>> 8);
                    w22_out <= w22_in + ((w22_update_temp + 32'd128) >>> 8);
                    b2_out <= b2_in + ((b2_update_temp + 32'd128) >>> 8);
                end
                
                SET_FLAGS: begin
                    // Set output flags
                    weight_new_valid <= 1;
                    bias_new_valid <= 1;
                end
                
                CLEAR_FLAGS: begin
                    // Clear flags - corrected to set them to 0
                    weight_new_valid <= 0;
                    bias_new_valid <= 0;
                    // If training is complete, keep done=1
                end
            endcase
        end
    end

endmodule