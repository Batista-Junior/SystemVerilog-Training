interface mem_interface #(
  parameter ADDR_WIDTH = 5,
  parameter DATA_WIDTH = 8
) (
  input logic clk
);

  logic read;
  logic write;
  logic [ADDR_WIDTH-1:0] addr;
  logic [DATA_WIDTH-1:0] data_in;
  logic [DATA_WIDTH-1:0] data_out;

  modport dut (
    input  clk,
    input  read,
    input  write,
    input  addr,
    input  data_in,
    output data_out
  );

  modport tester (
    input  clk,
    output read,
    output write,
    output addr,
    output data_in,
    input  data_out
  );

endinterface