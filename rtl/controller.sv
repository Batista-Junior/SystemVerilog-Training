module controller (
  input  logic clk,
  input  logic rst_,
  input  logic zero,
  input  logic [2:0] opcode,
  output logic mem_rd,
  output logic load_ir,
  output logic halt,
  output logic in_pc,
  output logic load_ac,
  output logic load_pc,
  output logic mem_wr
);

import definitions_pkg::*;

state_t current_state, next_state;


//LÓGICA SEQUENCIAL 

always_ff @(posedge clk or negedge rst_) begin 
  if(!rst_)
    current_state <= INST_ADDR;
  else
    current_state <= next_state;    
end


//LÓGICA COMBINACIONAL 

always_comb begin
  next_state = current_state;

  case (current_state)
    INST_ADDR:  begin 
      mem_rd  = 1'b0;
      load_ir = 1'b0; 
      halt    = 1'b0;
      in_pc   = 1'b0;
      load_ac = 1'b0;
      load_pc = 1'b0; 
      mem_wr  = 1'b0;
      next_state = INST_FETCH;
    end
    
    INST_FETCH: begin
      mem_rd  = 1'b1;
      load_ir = 1'b0; 
      halt    = 1'b0;
      in_pc   = 1'b0;
      load_ac = 1'b0;
      load_pc = 1'b0; 
      mem_wr  = 1'b0;
      next_state = INST_LOAD;
    end

    INST_LOAD:  begin
      mem_rd  = 1'b1;
      load_ir = 1'b1; 
      halt    = 1'b0;
      in_pc   = 1'b0;
      load_ac = 1'b0;
      load_pc = 1'b0; 
      mem_wr  = 1'b0;
      next_state = IDLE;
    end
    IDLE:       begin 
      mem_rd  = 1'b1;
      load_ir = 1'b1; 
      halt    = 1'b0;
      in_pc   = 1'b0;
      load_ac = 1'b0;
      load_pc = 1'b0; 
      mem_wr  = 1'b0;
      next_state = OP_ADDR;
    end

    OP_ADDR:    begin
      mem_rd  = 1'b0;
      load_ir = 1'b0; 
      halt    = (opcode==HLT)?1:0;
      in_pc   = 1'b1;
      load_ac = 1'b0;
      load_pc = 1'b0; 
      mem_wr  = 1'b0;
      next_state = OP_FETCH;
    end

    OP_FETCH:   begin 
      mem_rd  = (opcode==ADD || opcode==AND || opcode==XOR || opcode==LDA);
      load_ir = 1'b0; 
      halt    = 1'b0;
      in_pc   = 1'b0;
      load_ac = 1'b0;
      load_pc = 1'b0; 
      mem_wr  = 1'b0;
      next_state = ALU_OP;
    end

    ALU_OP:     begin
      mem_rd  = (opcode==ADD || opcode==AND || opcode==XOR || opcode==LDA);
      load_ir = 1'b0; 
      halt    = 1'b0;
      in_pc   = (opcode==SKZ && zero);
      load_ac = (opcode==ADD || opcode==AND || opcode==XOR || opcode==LDA);
      load_pc = (opcode==JMP);
      mem_wr  = 1'b0;
      next_state = STORE;
    end
    STORE:      begin 
      mem_rd  = (opcode==ADD || opcode==AND || opcode==XOR || opcode==LDA);
      load_ir = 1'b0; 
      halt    = 1'b0;
      in_pc   = (opcode==JMP);
      load_ac = (opcode==ADD || opcode==AND || opcode==XOR || opcode==LDA);
      load_pc = (opcode==JMP);
      mem_wr  = (opcode==STO);
      next_state = INST_ADDR;
    end
    endcase
end

endmodule