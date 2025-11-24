module top;

  timeunit 1ns;
  timeprecision 1ps;

  // Parâmetros Globais
  localparam ADDR_WIDTH = 5;
  localparam DATA_WIDTH = 8;

  // Fios de interconexão
  logic clk;
  logic read;
  logic write;
  logic [ADDR_WIDTH-1:0] addr;
  logic [DATA_WIDTH-1:0] data_in;
  logic [DATA_WIDTH-1:0] data_out;

  // 1. Geração de Clock (Período 10ns)
  initial clk = 0;
  always #5 clk = ~clk;

  // 2. Instância da Memória (DUT)
  memory #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) mem_inst (
    .clk      (clk),
    .read     (read),
    .write    (write),
    .addr     (addr),
    // Zera todas as posições para evitar 'X' na simulação
    .data_in  (data_in),
    .data_out (data_out)
  );

  // 3. Instância do Testbench/Tester
  mem_test #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) tester_inst (
    .clk      (clk),
    .read     (read),
    .write    (write),
    .addr     (addr),
    .data_in  (data_in),
    .data_out (data_out)
  );

endmodule