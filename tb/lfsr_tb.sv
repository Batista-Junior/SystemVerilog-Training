`timescale 1ns/1ps

module lfsr_tb;

    // Sinais
    logic clk;
    logic rst_n;
    logic load_seed;
    logic lfsr_en;
    logic [31:0] saved_seed;
    logic [31:0] lfsr_out;
    logic [1:0] saida;

    assign saida = lfsr_out[1:0];

    // Instancia o DUT (Device Under Test)
    lfsr_core dut (
        .clk(clk),
        .rst_n(rst_n),
        .load_seed(load_seed),
        .lfsr_en(lfsr_en),
        .saved_seed(saved_seed),
        .lfsr_out(lfsr_out)
    );

    // Geração de Clock
    initial clk = 0;
    always #5 clk = ~clk;

    // Procedimento de Teste
    initial begin
        // Configuração de arquivo de onda
        $dumpfile("lfsr_unit.vcd");
        $dumpvars(0, lfsr_tb);

        $display("=== INICIO TESTE UNITARIO LFSR ===");

        // 1. Inicialização
        rst_n = 0;
        load_seed = 0;
        lfsr_en = 0;
        saved_seed = 32'd1; // SEED FIXA = 1
        
        repeat(2) @(posedge clk);
        rst_n = 1;
        $display("Reset liberado. Valor inicial (Reset): %h", lfsr_out);

        // 2. Carregar Semente
        @(negedge clk);
        load_seed = 1;
        @(negedge clk);
        load_seed = 0;
        $display("Semente Carregada: %d (Bin: %b)", lfsr_out, lfsr_out);
        
        // Verifica a cor correspondente à semente (antes de shiftar)
        // Se a lógica do seu jogo usa os bits [1:0] IMEDIATAMENTE:
        check_color(lfsr_out, "Valor Inicial");

        // 3. Gerar Sequência (Shiftar 5 vezes)
        $display("\n--- GERANDO SEQUENCIA ---");
        
        for (int i = 1; i <= 5; i++) begin
            @(negedge clk);
            lfsr_en = 1; // Pulso de Enable
            @(negedge clk);
            lfsr_en = 0;
            
            $display("Shift #%0d -> Reg: %0d (Bin: %b)", i, lfsr_out, lfsr_out);
            check_color(lfsr_out, $sformatf("Cor #%0d", i));
        end

        $display("\n=== FIM DO TESTE ===");
        $stop;
    end

    // Função auxiliar para mostrar qual LED acenderia
    function void check_color(logic [31:0] val, string label);
        logic [3:0] leds;
        case (val[1:0])
            2'b00: leds = 4'b0001;
            2'b01: leds = 4'b0010;
            2'b10: leds = 4'b0100;
            2'b11: leds = 4'b1000;
        endcase
        $display("   [%s] Bits[1:0]=%b -> LED: %b", label, val[1:0], leds);
    endfunction

endmodule