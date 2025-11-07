module register #(
  parameter WIDTH = 8
)
  input  logic clk,
  input  logic enable,
  input  logic rst_,
  input  logic [WIDTH-1:0] data,
  output logic [WIDTH-1:0] out
(
  always_ff(posedge clk or rst_) begin 
    if(!rst_)
      out <= '0;
    else begin
      if(enable)
      out <= data;
    end
  end
);
endmodule
