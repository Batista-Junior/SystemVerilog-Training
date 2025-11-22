// Lab 1 Modeling a Simple Register

`timescale 1ns/1ps

module register #(
  parameter WIDTH = 8
) (
  input  logic clk,
  input  logic enable,
  input  logic rst_,
  input  logic [WIDTH-1:0] data,
  output logic [WIDTH-1:0] out
);

  always_ff @(posedge clk or negedge rst_) begin 
    if (!rst_) begin
      out <= '0;
    end else begin
      if (enable)
        out <= data;
    end
  end

endmodule
