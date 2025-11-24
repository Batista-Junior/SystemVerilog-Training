`timescale 1ns/1ps

module tb_counter;

  // 1. Parâmetros e Sinais
  parameter WIDTH = 5;
  
  logic             clk;
  logic             enable;
  logic             rst_;
  logic             load;
  logic [WIDTH-1:0] data;
  logic [WIDTH-1:0] count;

  // 2. Instanciar o DUT (Device Under Test)
  counter #(
    .WIDTH(WIDTH)
  ) dut (
    .clk(clk),
    .enable(enable),
    .rst_(rst_),
    .load(load),
    .data(data),
    .count(count)
  );

  // 3. Geração de Clock (Período de 10ns)
  initial begin
    clk = 0;
    forever #5 clk = ~clk; 
  end

  // 4. Procedimento de Teste
  initial begin
    // Configuração de visualização (opcional, para simuladores que usam console)
    $monitor("Time=%0t | rst_=%b load=%b en=%b data=%0d | count=%0d", 
             $time, rst_, load, enable, data, count);

    // Inicialização
    enable = 0;
    load = 0;
    data = 0;
    rst_ = 1; // Reset inativo (ativo em nível baixo)

    // Cenário 1: Reset Assíncrono
    #12 rst_ = 0; // Aplica reset
    #10 rst_ = 1; // Libera reset
    
    // Cenário 2: Testar Enable (Contagem normal)
    #10 enable = 1;
    #50; // Espera 5 ciclos de clock (deve contar 0 -> 5)
    
    // Cenário 3: Testar Load (Carregamento de valor)
    // O Load tem prioridade sobre o Enable
    #10 load = 1;
    data = 5'd20; // Carrega o valor 20
    #10 load = 0; // Retira o load, deve continuar contando a partir de 20
    
    // Cenário 4: Testar Wraparound (Estouro)
    // Vamos carregar o valor máximo (31 para 5 bits) e ver se volta a 0
    #10 load = 1;
    data = 5'd31;
    #10 load = 0;
    #20; // Deve passar de 31 para 0 e depois 1

    // Finaliza a simulação
    #20 $finish;
  end

  // Opcional: Gerar arquivo para visualizador de ondas (GTKWave, etc)
  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_counter);
  end

endmodule