module memory #(
  parameter ADDR_WIDTH = 5,
  parameter DATA_WIDTH = 8
)(
  // Apenas uma porta agora: a interface (usando o modport 'dut')
  mem_interface.dut bus
);

  // Array de Memória
  logic [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];

  // Inicialização
  initial begin
    for (int i = 0; i < (2**ADDR_WIDTH); i++) begin
        mem[i] = 0;
    end
  end

  // Escrita (Síncrona) - Acessando via 'bus.'
  always_ff @(posedge bus.clk) begin
    if (bus.write) begin
      mem[bus.addr] <= bus.data_in;
    end
  end

  // Leitura (Assíncrona) - Acessando via 'bus.'
  always_comb begin
    if (bus.read) begin
      bus.data_out = mem[bus.addr];
    end else begin
      bus.data_out = {DATA_WIDTH{1'bz}};
    end
  end

endmodule