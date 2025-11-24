module flipflop #(
  parameter WIDTH = 8
)(
  input  logic [WIDTH-1:0] qin,
  input  logic clk,
  input  logic reset,
  output logic [WIDTH-1:0] qout
);
  always_ff @(posedge clk) begin
    if(reset)
      qout <= '0;
    else 
      qout <= qin;
  end
endmodule