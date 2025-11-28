module q_analog_prng #(
  parameter int E = 31,
  parameter int Q_VAL = 1025
)(
  input  logic clk,
  input  logic rst_n,
  input  logic en,
  input  logic [E-1:0] x0,
  output logic [E-1:0] prng_out
);

  // sinais internos
  logic [E-1:0] current_x;
  logic [2*E-1:0] multi_res;

  // sinais para a redução modular
  logic [E-1:0] upper_bits;
  logic [E-1:0] lower_bits;
  logic [E:0]   sum_parts;
  logic [E:0]   sum_plus_one;
  logic         sel_correction;
  logic [E-1:0] next_val_calc; 
  logic [E-1:0] next_val_mux;

  // estágio 1: (q * x) + 1
  assign multi_res = (current_x * Q_VAL) + 1;

  // estágio 2:
  assign upper_bits = multi_res[2*E-1:E];
  assign lower_bits = multi_res[E-1:0];

  assign sum_parts = upper_bits + lower_bits;

  assign sum_plus_one = sum_parts + 1;

  assign sel_correction = sum_plus_one[E];

  assign next_val_calc = sel_correction ? sum_plus_one[E-1:0] : sum_parts[E-1:0];

  // estágio 3:
   assign next_val_mux = (en) ? next_val_calc : x0;

   always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      current_x <= '0;
    else
      current_x <= next_val_mux;
   end

   // saída
   assign prng_out = current_x;

endmodule