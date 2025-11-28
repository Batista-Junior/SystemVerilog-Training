`timescale 1ns / 1ps

module q_analog_prng_tb;

    // ========================================================================
    // 1. PARÂMETROS DO PRNG (Conforme o Artigo)
    // ========================================================================
    parameter int E = 31;           // Primo de Mersenne 2^31 - 1
    parameter int Q_VAL = 1025;     // Gerador q = 1025 [cite: 144]
    
    // Cálculo da duração da simulação:
    // Objetivo NIST: 200 sequências * 1.000.000 bits = 200.000.000 bits.
    // Bits por ciclo: 31.
    // Ciclos necessários: ~6.451.613. Arredondamos para 6.500.000 para segurança.
    localparam int TOTAL_SAMPLES = 6500000; 

    // ========================================================================
    // 2. SINAIS E VARIÁVEIS
    // ========================================================================
    logic          clk;
    logic          rst_n;
    logic          en;
    logic [E-1:0]  x0;
    logic [E-1:0]  prng_out;

    integer        f_out;           // Handle do arquivo
    integer        sample_cnt;      // Contador de amostras
    string         filename = "prng_nist_data.txt";

    // ========================================================================
    // 3. INSTANCIAÇÃO DO DUT (Device Under Test)
    // ========================================================================
    q_analog_prng #(
        .E(E),
        .Q_VAL(Q_VAL)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .x0(x0),
        .prng_out(prng_out)
    );

    // ========================================================================
    // 4. GERAÇÃO DE CLOCK
    // ========================================================================
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 100 MHz
    end

    // ========================================================================
    // 5. PROCESSO DE CONTROLE E EXPORTAÇÃO
    // ========================================================================
    initial begin
        // Abertura do Arquivo
        f_out = $fopen(filename, "w");
        if (f_out == 0) begin
            $display("ERRO: Nao foi possivel criar o arquivo %s", filename);
            $finish;
        end
        
        $display("=== INICIANDO EXPORTACAO PARA NIST ===");
        $display("Arquivo de saida: %s", filename);
        $display("Total de amostras planejadas: %0d", TOTAL_SAMPLES);
        $display("Total de bits estimados: %0d", TOTAL_SAMPLES * 31);

        // Inicialização
        rst_n = 0;
        en    = 0;
        x0    = '0;
        sample_cnt = 0;

        // Reset
        #20;
        rst_n = 1;

        // Carga da Semente (Deve ser != [0]q)
        @(negedge clk);
        x0 = 31'd12345; // Semente arbitrária válida
        en = 0;
        
        // Habilitar Geração
        @(negedge clk);
        en = 1;
        
        // Loop de Geração
        while (sample_cnt < TOTAL_SAMPLES) begin
            @(posedge clk);
            
            // Escreve os 31 bits no arquivo (Formato ASCII 0/1)
            // O artigo especifica que as strings binárias são concatenadas[cite: 149].
            $fwrite(f_out, "%b", prng_out);
            
            sample_cnt++;

            // Mostra progresso a cada 1% para o usuário não achar que travou
            if (sample_cnt % (TOTAL_SAMPLES/100) == 0) begin
                $display("Progresso: %0d%% (%0d amostras geradas)", 
                         (sample_cnt * 100) / TOTAL_SAMPLES, sample_cnt);
            end
        end

        // Finalização
        $fclose(f_out);
        $display("=== EXPORTACAO CONCLUIDA ===");
        $display("Arquivo gerado com sucesso. Pronto para teste NIST.");
        $finish;
    end

endmodule