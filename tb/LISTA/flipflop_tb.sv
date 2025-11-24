module flipflop_tb;

  timeunit 1ns;
  timeprecision 1ps;

  parameter WIDTH = 8;

  // Sinais do Testbench
  logic clk;
  logic reset;
  logic [WIDTH-1:0] qin;
  logic [WIDTH-1:0] qout;

  // 1. Instanciação do DUT (Device Under Test)
  flipflop #(
    .WIDTH(WIDTH)
  ) dut (
    .clk   (clk),
    .reset (reset),
    .qin   (qin),
    .qout  (qout)
  );

  // Geração de Clock (Período 10ns)
  initial clk = 0;
  always #5 clk = ~clk;

  // ============================================================
  // 2. CLOCKING BLOCK (Especificação Principal)
  // ============================================================
  // CORREÇÃO AQUI: Adicionado 'default' antes de 'clocking'
  // Isso diz ao SystemVerilog que qualquer '##' neste módulo refere-se a este clock.
  default clocking cb @(posedge clk);
    default input #1step output #4ns;

    // Output: O TB escreve no DUT (qin, reset)
    output reset;
    output qin;

    // Input: O TB lê do DUT (qout)
    input  qout;
  endclocking

  // ============================================================
  // 3. BLOCO DE ESTIMULOS
  // ============================================================
  initial begin
    // Inicialização síncrona via clocking block
    cb.reset <= 0;
    cb.qin   <= 0;
    
    // Aguarda o primeiro alinhamento do clock
    ##1; 

    // --- REQUISITO: Reset Sequence ---
    $display("[%0t] Ativando Reset...", $time);
    
    cb.reset <= 1; // Ativa reset
    ##3;           // Agora funciona pois 'cb' é o default clocking
    cb.reset <= 0; // Desativa reset
    
    $display("[%0t] Reset liberado.", $time);

    // --- REQUISITO: Data Loop ---
    $display("[%0t] Iniciando Loop de Dados...", $time);
    
    for (int i = 0; i < 10; i++) begin
      // Gera um dado aleatório e atribui ao qin via clocking block
      cb.qin <= i + 8'hA0; 
      
      // Avança 1 ciclo de clock
      ##1; 
      
      // Monitoramento (cb.qout lê o valor amostrado)
      $display("  Tempo %0t | Input: %h | Output lido (cb.qout): %h", $time, dut.qin, cb.qout);
    end

    $display("[%0t] Fim do Teste.", $time);
    $finish;
  end

endmodule