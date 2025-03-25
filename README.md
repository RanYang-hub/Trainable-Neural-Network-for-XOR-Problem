# FPGA-based Trainable Neural Network for XOR Problem

## Core Modules

* **Forward Propagation Module (forward_propagation)**: Implements the forward computation process of the neural network, includes ReLU and Sigmoid activation functions, and supports parallel computation
* **Backpropagation Module (backpropagation)**: Implements the gradient descent algorithm, calculates weight and bias updates, and supports configurable learning rates
* **Top-level Module (xor_nn_top)**: Integrates forward propagation and backpropagation modules, manages the training process and weight updates, and handles input/output interfaces
* **Test Benches (xor_nn_top_tb, backpropagation_tb)**: Provide complete simulation environments

## Module Details

### backpropagation.v
This module:
* Calculates output errors and gradients
* Propagates errors to the hidden layer through the chain rule
* Updates network weights and biases based on gradients and learning rate
* Uses a state machine architecture to implement the computation process

### forwardpropagation.v
This module:
* Performs weighted sum calculations using fixed-point multiplication and addition
* Implements ReLU and Sigmoid activation functions
* Contains a combinational logic implementation of the Sigmoid lookup table

#### Key Sub-modules in the forward_propagation Module

1. **Sigmoid_Combinational Sub-module**:
   * A combinational logic implementation of the sigmoid activation function
   * Uses a lookup table (LUT) approach to implement the non-linear sigmoid function, avoiding complex exponential calculations
   * Divides the input range into 32 regions, each mapped to a pre-calculated sigmoid value
   * Implements the symmetric property of sigmoid: sigmoid(-x) = 1 - sigmoid(x)
   * Uses 8.8 fixed-point format for the lookup table, accurately representing sigmoid outputs from 0 to 1
   * Optimized for FPGA resources, balancing precision and resource usage

2. **neuron Sub-module**:
   * A parameterized design implementing a single neuron
   * Supports configurable data width, weight integer width, and sigmoid size
   * Supports different activation function types ("sigmoid" or "relu") through the actType parameter
   * Implements key computational steps of a neuron:
     * Parallel multiplication calculation (inputs with weights)
     * Result accumulation
     * Bias addition
     * Activation function application
   * Uses a state machine to control data flow, including calculation start, in-progress, completion, and output valid states
   * Features optimized parallel computation structure suitable for FPGA implementation

### toplevelneuronnetwork.v
The top-level network module integrates forward and backward propagation functionality and controls the entire training process. This module:
* Stores network weights and biases
* Schedules forward and backward propagation operations
* Updates weights based on backpropagation results
* Detects training completion conditions

### Test Bench Modules
* **XOR_bp_tb.v**: Independent test bench for the backpropagation module
* **top_tb.v**: Test bench for the entire neural network system

## Usage Instructions

### Simulation Steps
1. Load all Verilog files into your HDL simulator (ModelSim, Vivado, VCS, etc.)
2. Run xor_nn_top_tb to simulate the complete neural network training process
3. Or run backpropagation_tb to test the backpropagation module independently

### Training Configuration
You can modify the following parameters in the test bench:
* Training mode (by modifying the train variable)
* Learning rate (by modifying the learning_rate variable)
* Maximum iteration count (by modifying the max_iterations variable)
* Initial weights and bias values
