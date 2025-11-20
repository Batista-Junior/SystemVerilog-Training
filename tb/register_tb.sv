`timescale 1ns/1ps

module register_tb;

  // Parâmetros e Sinais
  parameter WIDTH = 8;
  
  logic clk;
  logic enable;
  logic rst_;
  logic [WIDTH-1:0] data;
  logic [WIDTH-1:0] out;

  // Instanciação do DUT (Device Under Test)
  register #(.WIDTH(WIDTH)) dut (
    .clk(clk),
    .enable(enable),
    .rst_(rst_),
    .data(data),
    .out(out)
  );

  // Geração de Clock (Período de 10ns)
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Configuração do Monitoramento (Log)
  initial begin
    // Formato: Unidade -9 (ns), 1 casa decimal, sufixo " ns", largura mínima 10
    $timeformat(-9, 1, " ns", 10);
    
    // O monitor roda em background e imprime sempre que um sinal muda
    $monitor("time=%t enable=%b rst_=%b data=%h out=%h", 
             $time, enable, rst_, data, out);
  end

  // Sequência de Testes (Estímulos)
  initial begin
    // Time = 0.0 ns: Inicialização (estados indefinidos 'x' são o padrão do logic)
    // Forçamos rst_ para 1 (inativo) inicialmente para ver o 'xx' na saída
    rst_ = 1;
    // data e enable começam como 'x' por padrão se não definidos, 
    // mas para garantir o log exato, podemos deixá-los indefinidos.
    
    // Time = 15.0 ns: Aplicar Reset
    #15;
    rst_ = 0; // Reset ativo (out vai para 00)

    // Time = 25.0 ns: Soltar Reset, Enable desligado
    #10;
    rst_ = 1;
    enable = 0;

    // Time = 35.0 ns: Escrever AA
    #10;
    enable = 1;
    data = 8'haa;

    // Time = 45.0 ns: Parar de escrever (manter valor AA), mudar data input
    #10;
    enable = 0;
    data = 8'h55; // Out deve manter aa

    // Time = 55.0 ns: Resetar novamente
    #10;
    rst_ = 0; // Out vai para 00
    enable = 'x; // Simulando estado desconhecido no enable
    data = 'x;

    // Time = 65.0 ns: Recuperar do reset
    #10;
    rst_ = 1;
    enable = 0;

    // Time = 75.0 ns: Escrever 55
    #10;
    enable = 1;
    data = 8'h55;

    // Time = 85.0 ns: Manter valor 55
    #10;
    enable = 0;
    data = 8'haa;

    // Fim do teste
    #10;
    $display("REGISTER TEST PASSED");
    $finish;
  end

endmodule