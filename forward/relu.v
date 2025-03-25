module ReLU #(parameter dataWidth=16, weightIntWidth=1) (
    input           clk,
    input   [2*dataWidth-1:0]   x,
    output  reg [dataWidth-1:0]  out
);

always @(posedge clk)
begin
    if($signed(x) >= 0)
    begin
        // 对于8.8格式，整数部分有8位(包括符号位)
        // 检查整数部分是否溢出(除符号位外的高7位)
        if(|x[2*dataWidth-1-:weightIntWidth+8]) //检查整数部分是否溢出
            out <= {1'b0,{(dataWidth-1){1'b1}}}; //正数饱和处理
        else
            // 保持8.8格式，从合适位置取出16位
            out <= x[2*dataWidth-1-weightIntWidth-:dataWidth];
    end
    else 
        out <= 0;      
end

endmodule
