`timescale 1ns/1ps

module genius_fsm_tb;

  // ===========================================================================
  // 1. SINAIS E VARIÁVEIS DO TESTBENCH
  // ===========================================================================
  logic clk;
  logic rst_n;
  logic start;
  logic [1:0] level;
  logic [3:0] buttom;
  
  // Saídas do DUT (Device Under Test)
  logic [3:0] leds;
  logic [5:0] score;

  // Variáveis para "Hackear" o jogo (Armazenar a sequência mostrada)
  logic [3:0] sequence_queue [$]; // Fila para guardar as cores
  logic [3:0] captured_color;
  int i;

  // ===========================================================================
  // 2. INSTANCIAÇÃO DO MÓDULO (DUT)
  // ===========================================================================
  // Importante: Sobrescrevemos o TIME para 10 ticks para simulação rápida!
  genius_fsm #(
      .TIME(10) 
  ) uut (
      .clk(clk),
      .rst_n(rst_n),
      .speed(1'b0), // Não usado
      .start(start),
      .level(level),
      .mode(1'b0),  // Não usado
      .buttom(buttom),
      .leds(leds),
      .score(score)
  );

  // ===========================================================================
  // 3. GERAÇÃO DE CLOCK
  // ===========================================================================
  initial clk = 0;
  always #5 clk = ~clk; // Clock de 10ns (100MHz)

  // ===========================================================================
  // 4. TASKS AUXILIARES (Para deixar o teste limpo)
  // ===========================================================================
  
  // Task para apertar um botão
 // Task para apertar um botão (Versão Corrigida)
  task press_btn(input [3:0] btn_val);
    begin
      @(posedge clk);
      buttom = btn_val;       // Aperta o botão
      
      // SEGURA O BOTÃO POR MAIS TEMPO
      // S7 (Detecta) -> S8 (Verifica) -> S5 (Avança)
      // Precisamos garantir que ele esteja alto durante S8
      repeat(4) @(posedge clk); 
      
      buttom = 4'b0000;       // Solta o botão
      
      repeat(5) @(posedge clk); // Espera um pouco (Debounce/Intervalo)
    end
  endtask

  // ===========================================================================
  // 5. CENÁRIO DE TESTE
  // ===========================================================================
  initial begin
    // --- Configuração Inicial ---
    $display("=== INICIANDO SIMULACAO GENIUS ===");
    rst_n = 0;
    start = 0;
    level = 2'b00; // Nível 8 rodadas
    buttom = 0;
    
    // Reset
    repeat(10) @(posedge clk);
    rst_n = 1;
    repeat(10) @(posedge clk);

    // --- Iniciar Jogo ---
    $display("1. Apertando START");
    start = 1;
    @(posedge clk);
    start = 0;

    // --- LOOP DE JOGO (Vencer 3 rodadas) ---
    for (int round = 1; round <= 3; round++) begin
        $display("\n--- RODADA %0d ---", round);
        
        // A. FASE DE OBSERVAÇÃO (MÁQUINA MOSTRA)
        // Limpa a fila
        sequence_queue.delete();
        
        $display("Aguardando maquina mostrar sequencia...");
        
        // Loop para capturar "round" cores
        for (i = 0; i < round; i++) begin
            // Espera o LED acender (sinal diferente de 0)
            wait(leds != 4'b0000);
            
            // Captura a cor
            captured_color = leds;
            sequence_queue.push_back(captured_color);
            $display("   [Maqui] Mostrou cor: %b", captured_color);
            
            // Espera o LED apagar antes de procurar o próximo
            wait(leds == 4'b0000);
            
            // Pequeno delay para garantir que não pegamos o mesmo pulso
            repeat(2) @(posedge clk);
        end

        // B. FASE DE JOGADA (USUÁRIO REPETE)
        $display("Vez do Usuario (Replicando sequencia)...");
        
        // Espera a máquina entrar no estado de espera (Led apagado e tempo passado)
        repeat(20) @(posedge clk); 

        foreach(sequence_queue[k]) begin
            $display("   [User ] Apertando: %b", sequence_queue[k]);
            press_btn(sequence_queue[k]);
            
            // Espera processar (estado S8 -> S5 -> S7)
            repeat(5) @(posedge clk); 
        end
        
        // Verifica Score
        repeat(5) @(posedge clk);
        if (score == round) 
            $display("   [SUCESSO] Rodada %0d concluida! Score atual: %0d", round, score);
        else
            $display("   [ERRO] Score incorreto. Esperado: %0d, Real: %0d", round, score);
            
        // Espera transição para próxima rodada
        repeat(20) @(posedge clk);
    end

    // --- TESTE DE DERROTA (GAME OVER) ---
    $display("\n--- TESTE DE GAME OVER ---");
    $display("A maquina vai mostrar 4 cores, vamos errar a primeira propositalmente.");
    
    // Espera primeira cor aparecer
    wait(leds != 4'b0000);
    wait(leds == 4'b0000);
    // (Ignora o resto da sequencia da maquina)
    repeat(50) @(posedge clk); 

    $display("Simulando erro do usuario...");
    press_btn(4'b1111); // Aperta todos os botões (inválido ou garantidamente errado se one-hot)
    
    repeat(10) @(posedge clk);
    
    if (score == 0) // Assumindo que score reseta no game over/idle
        $display("   [SUCESSO] Jogo Resetado/Game Over detectado.");
    else
        $display("   [INFO] Score final: %0d (Verifique se o jogo foi para S0)", score);

    $display("\n=== FIM DA SIMULACAO ===");
    $stop;
  end

endmodule