`timescale 1ns / 1ps

module q_analog_prng_tb_v2;

    // ========================================================================
    // 1. PARÂMETROS ATUALIZADOS
    // ========================================================================
    parameter int E = 61;           // Primo de Mersenne 2^61 - 1
    parameter int Q_VAL = 1025;     // Gerador (Mantido conforme sua escolha)
    
    // Cálculo da duração da simulação para o NIST:
    // Alvo: 200 sequências * 1.000.000 bits = 200.000.000 bits totais.
    // Vazão atual: 64 bits por ciclo.
    // Ciclos necessários: 200.000.000 / 64 = 3.125.000.
    // Arredondamos para 3.200.000 para margem de segurança.
    localparam int TOTAL_SAMPLES = 3200000; 

    // ========================================================================
    // 2. SINAIS E VARIÁVEIS (LARGURAS AJUSTADAS)
    // ========================================================================
    logic          clk;
    logic          rst_n;
    logic          en;
    
    logic [E-1:0]  x0;       // Agora tem 61 bits [60:0]
    logic [63:0]   prng_out; // Agora tem 64 bits fixos

    integer        f_out;
    integer        sample_cnt;
    string         filename = "prng_nist_data_64bit_teste2.txt";

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
        
        $display("=== INICIANDO EXPORTACAO PARA NIST (64 BITS) ===");
        $display("Parametro E: %0d", E);
        $display("Parametro Q: %0d", Q_VAL);
        $display("Total de amostras: %0d", TOTAL_SAMPLES);
        $display("Total de bits estimados: %0d", TOTAL_SAMPLES * 64);

        // Inicialização
        rst_n = 0;
        en    = 0;
        x0    = '0;
        sample_cnt = 0;

        // Reset
        #20;
        rst_n = 1;

        // Carga da Semente (x0 deve ser != [0]q)
        // Usamos uma semente arbitrária de 61 bits
        @(negedge clk);
        x0 = 61'h123456789ABCDEF; // Exemplo hexadecimal para preencher 61 bits
        en = 0;
        $display("Semente carregada: %h", x0);
        
        // Habilitar Geração
        @(negedge clk);
        en = 1;
        
        // Loop de Geração
        while (sample_cnt < TOTAL_SAMPLES) begin
            @(posedge clk);
            
            // #1 delay para garantir que prng_out estabilizou após a borda do clock
            #1; 
            
            // Escreve os 64 bits no arquivo (Formato ASCII 0/1)
            // O %b escreverá automaticamente os 64 caracteres '0' ou '1'
            $fwrite(f_out, "%b", prng_out);
            
            sample_cnt++;

            // Mostra progresso a cada 5%
            if (sample_cnt % (TOTAL_SAMPLES/20) == 0) begin
                $display("Progresso: %0d%% (%0d amostras)", 
                         (sample_cnt * 100) / TOTAL_SAMPLES, sample_cnt);
            end
        end

        // Finalização
        $fclose(f_out);
        $display("=== EXPORTACAO CONCLUIDA ===");
        $display("Arquivo '%s' gerado com sucesso.", filename);
        $finish;
    end

endmodule