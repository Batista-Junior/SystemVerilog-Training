module top;

  timeunit 1ns;
  timeprecision 1ps;

  // Parâmetros Globais
  localparam ADDR_WIDTH = 5;
  localparam DATA_WIDTH = 8;

  // 1. Geração de Clock
  logic clk;
  initial clk = 0;
  always #5 clk = ~clk;

  // 2. Instância da INTERFACE
  // A interface é "criada" aqui e chamada de '_if'
  mem_interface #(
    .ADDR_WIDTH(ADDR_WIDTH), 
    .DATA_WIDTH(DATA_WIDTH)
  ) _if (
    .clk(clk)
  );

  // 3. Instância da Memória (DUT)
  // Conectamos a interface '_if' criada acima na porta 'bus' da memória
  memory #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) mem_inst (
    .bus(_if.dut) // Usa o modport 'dut'
  );

  // 4. Instância do Testbench (Tester)
  // Conectamos a mesma interface '_if' na porta 'bus' do testbench
  mem_test #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) tester_inst (
    .bus(_if.tester) // Usa o modport 'tester'
  );

endmodule