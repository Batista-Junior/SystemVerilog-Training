module memory #(
  parameter ADDR_WIDTH = 5,
  parameter DATA_WIDTH = 8
)(
  input  logic clk,
  input  logic read,
  input  logic write,
  input  logic [ADDR_WIDTH-1:0] addr,
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out
);

  //reg [DWIDTH-1:0] array [0:2**AWIDTH-1];
  logic [DATA_WIDTH-1:0] array [0:2**ADDR_WIDTH-1];

  //escrevendo zeros na memória
  initial begin
    for (int i = 0; i < (2**ADDR_WIDTH); i++) begin
        mem[i] = 0;
    end
  end

  //escrita
  always_ff @(posedge clk) begin
    if(write)
      array[addr] <= data_in;
  end
  //leitura 
  always_comb begin
    if(read)
      data_out = array[addr];
    else begin
      data_out = {DATA_WIDTH{1'bz}};
    end
  end
endmodule