module lfsr_core (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        load_seed,
    input  logic        lfsr_en,
    input  logic [31:0] saved_seed,
    output logic [31:0] lfsr_out
);

    logic [31:0] lfsr_reg;
    logic        feedback;

    // Expõe o registrador para a saída
    assign lfsr_out = lfsr_reg;

    // Polinômio Xilinx Standard 32-bit: x^32 + x^22 + x^2 + x^1 + 1
    // Taps: 31, 21, 1, 0
    assign feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 32'hDEAD_BEEF; // Valor de reset padrão
        end else begin
            if (load_seed) begin
                lfsr_reg <= saved_seed; // Carrega a semente determinística
            end else if (lfsr_en) begin
                // Shift para esquerda, insere feedback na direita (LSB)
                lfsr_reg <= {lfsr_reg[30:0], feedback}; 
            end
        end
    end

endmodule