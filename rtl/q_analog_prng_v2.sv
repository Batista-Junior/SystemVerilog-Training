module q_analog_prng #(
  parameter int E = 61,
  parameter int Q_VAL = 1025
)(
  input  logic clk,
  input  logic rst_n,
  input  logic en,
  input  logic [E-1:0] x0,
  output logic [63:0] prng_out 
);

  // sinais internos
  logic [E-1:0] current_x;
  logic [E+12:0] multi_res; 

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

  // estágio 2: Redução Modular
  assign upper_bits = E'(multi_res >> E); 

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

   // Lógica de Saída (XOR Padding)
   logic [2:0] padding_bits;

    always_comb begin
        padding_bits[2] = current_x[4] ^ current_x[5]; 
        padding_bits[1] = current_x[2] ^ current_x[3]; 
        padding_bits[0] = current_x[0] ^ current_x[1]; 
    end

    assign prng_out = {padding_bits, current_x[60:0]};

endmodule