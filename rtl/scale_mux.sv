`timescale 1ns/1ps

module scale_mux #(
  parameter WIDTH = 1
)
(
  input  logic [WIDTH-1:0] in_a,
  input  logic [WIDTH-1:0] in_b,
  input  logic sel_a
  output logic out 
);
  always_comb begin
    //out = sel_a?in_b:in_a;  

    unique case(sel_a)
      1'b1: out = in_a;
      1'b0: out = in_b;

      default: out = 'x;
    endcase
  end

endmodule