`timescale 1ns/1ps

module genius_fsm_tb;

  // 1. SINAIS
  logic clk = 0;
  logic rst_n = 0;
  logic start = 0;
  logic [3:0] buttom = 0;
  logic [1:0] level = 0;
  
  // Saídas (não precisamos dirigir, só observar)
  logic [3:0] leds;
  logic [5:0] score;

  // 2. INSTANCIAÇÃO (DUT)
  // TIME=10 faz a simulação ser instantânea
  genius_fsm #( .TIME(10) ) uut (
      .clk(clk), .rst_n(rst_n), .start(start), .level(level), 
      .buttom(buttom), .leds(leds), .score(score),
      .speed(0), .mode(0)
  );

  // 3. CLOCK (100MHz)
  always #5 clk = ~clk;

  // 4. TASK SIMPLES PARA APERTAR BOTÃO
  // Essa task resolve todo o seu problema de timing.
task jogar(input [3:0] valor);
    begin
      // Passo A: Espera a FSM estar PRONTA (Estado S7)
      wait(uut.current_state == uut.S7);
      
      // Passo B: Sincroniza e aperta
      @(negedge clk);
      buttom = valor;
      
      // Passo C: Espera a FSM reconhecer e sair de S7 (indo para S8)
      wait(uut.current_state != uut.S7);
      
      // --- A CORREÇÃO ESTÁ AQUI ---
      // Estamos agora em S8. NÃO SOLTE O BOTÃO AINDA!
      // A FSM precisa ler o valor 'valor' enquanto está em S8.
      // Vamos segurar o botão por 2 clocks extras enquanto a FSM verifica.
      repeat(2) @(posedge clk); 
      
      // Passo D: Agora sim, pode soltar
      buttom = 0;
      
      // Passo E: Intervalo entre jogadas
      repeat(5) @(posedge clk);
    end
  endtask

  // 5. O ROTEIRO DO JOGO (LINEAR E DETERMINÍSTICO)
  initial begin
    // Gera arquivo de ondas
    $dumpfile("genius_simple.vcd");
    $dumpvars(0, genius_fsm_tb);

    // --- RESET ---
    rst_n = 0;
    repeat(10) @(posedge clk);
    rst_n = 1;
    repeat(10) @(posedge clk);

    $display("=== INICIO DO TESTE SIMPLIFICADO ===");

    // --- START ---
    start = 1; @(posedge clk); start = 0;

    // --- RODADA 1 ---
    // Sequência esperada: 2 (0010)
    jogar(4'b0010); 

    // Verifica Score
    repeat(20) @(posedge clk); // Tempo p/ atualizar score
    if(score == 1) $display("[OK] Rodada 1 Passou!");
    else           $display("[ERRO] Rodada 1 Falhou. Score: %d", score);

    // --- RODADA 2 ---
    // Sequência esperada: 2 -> 8 (0010 -> 1000)
    // A task 'jogar' espera automaticamente a vez do usuário, 
    // então não precisamos dar 'waits' manuais.
    jogar(4'b0010);
    jogar(4'b1000);

    repeat(20) @(posedge clk);
    if(score == 2) $display("[OK] Rodada 2 Passou!");
    else           $display("[ERRO] Rodada 2 Falhou. Score: %d", score);

    // --- RODADA 3 ---
    // Sequência esperada: 2 -> 8 -> 4
    jogar(4'b0010);
    jogar(4'b1000);
    jogar(4'b0100);

    repeat(20) @(posedge clk);
    if(score == 3) $display("[OK] Rodada 3 Passou!");
    else           $display("[ERRO] Rodada 3 Falhou. Score: %d", score);

    // --- GAME OVER ---
    // Vamos errar de propósito apertando 1111
    jogar(4'b1111);

    repeat(20) @(posedge clk);
    if(score == 0) $display("[OK] Game Over funcionou (Score zerou)!");
    else           $display("[ERRO] Nao deu Game Over. Score: %d", score);

    $display("=== FIM DO TESTE ===");
    $stop;
  end

endmodule