// Resolução Lab 3 Modeling a simple counter

`timescale 1ns/1ps

module counter #(
  parameter WIDTH = 5
)(
  input  logic             clk,
  input  logic             enable,
  input  logic             rst_,
  input  logic             load,
  input  logic [WIDTH-1:0] data,
  output logic [WIDTH-1:0] count

);

always_ff @(posedge clk or negedge rst_) begin 
  if(!rst_)
    count <= '0;
  else if(load)
    count <= data;
  else if(enable)
    count <= count + 1'b1;
end

endmodule