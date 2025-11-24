module scale_mux #(
  parameter WIDTH  = 1000000
  parameter SELECT = 14

)(
  input  logic clk,
  input  logic [SELECT-1:0] counter
  input  logic [WIDTH-1:0] pe_chain,
  input  logic [SELECT-1:0] select,
  output logic [63:0] out
);

  always_comb (posedge clk) begin 
    if(counter == 15625) begin
      out <= pe_chain[]
    end 
  end
endmodule