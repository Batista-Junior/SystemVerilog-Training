module alu(
  input  logic clk,
  input  logic [2:0] opcode,
  input  logic [7:0] data,
  input  logic [7:0] accum,
  output logic [7:0] out,
  output logic zero
);

  import definitions_pkg::*;

  always_ff @(negedge clk)begin
    case (opcode)
      HLT: begin 
        out <= accum;
      end

      SKZ: begin 
        out <= accum;
      end
      
      ADD: begin 
        out <= data + accum;
      end

      AND: begin 
        out <= data & accum;
      end

      XOR: begin 
        out <= data ^ accum;
      end

      LDA: begin 
        out <= data;
      end

      STO: begin 
        out <= accum;
      end

      JMP: begin 
        out <= accum;
      end
    endcase

  end

  always_comb begin
    zero = (accum==0)? 1 : 0;
  end

endmodule