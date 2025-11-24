module mem_test #(
  parameter ADDR_WIDTH = 5,
  parameter DATA_WIDTH = 8
)(
  mem_interface.tester bus
);

  timeunit 1ns;
  timeprecision 1ps;

  // ==========================================================================
  // CLASSE DE TRANSAÇÃO COM CONSTRAINTS
  // ==========================================================================
  class ASCII_Transaction;
    rand bit [7:0] data;

    // ------------------------------------------------------------------------
    // REQUISITO 1: Printable ASCII (0x20 a 0x7F)
    // Descomente abaixo para testar apenas ASCII Geral
    // ------------------------------------------------------------------------
    // constraint c_printable {
    //   data >= 8'h20;
    //   data <= 8'h7F;
    // }

    // ------------------------------------------------------------------------
    // REQUISITO 2: Apenas Letras (A-Z, a-z) sem pesos
    // Descomente abaixo (e comente os outros) para testar apenas letras
    // ------------------------------------------------------------------------
    // constraint c_letters_only {
    //   data inside {[8'h41:8'h5A], [8'h61:8'h7A]}; // A-Z, a-z
    // }

    // ------------------------------------------------------------------------
    // REQUISITO 3: Pesos (80% Maiúsculas, 20% Minúsculas)
    // ESTE ESTÁ ATIVO AGORA.
    // Nota: O operador ':/' distribui o peso para o total do intervalo.
    // ------------------------------------------------------------------------
    constraint c_weighted_case {
      data dist {
        [8'h41:8'h5A] :/ 80, // 80% de chance de cair neste grupo (Maiúsculas)
        [8'h61:8'h7A] :/ 20  // 20% de chance de cair neste grupo (Minúsculas)
      };
    }
  endclass

  // ==========================================================================
  // VARIÁVEIS DO TESTBENCH
  // ==========================================================================
  ASCII_Transaction tr;          // Instância da classe
  logic [DATA_WIDTH-1:0] scoreboard [int]; 
  int mem_depth;

  // Task auxiliar para escrita (Modificada para %c)
  task write_mem(input [ADDR_WIDTH-1:0] w_addr, input [DATA_WIDTH-1:0] w_data);
    begin
      @(negedge bus.clk); 
      bus.write   = 1;
      bus.read    = 0;
      bus.addr    = w_addr;
      bus.data_in = w_data;
      
      @(negedge bus.clk);
      bus.write   = 0;
      bus.addr    = 0;
      bus.data_in = 0;
      
      // Debug modificado para mostrar o caractere (%c)
      $display("[WRITE] Addr: %0d | Hex: %h | Char: %c", w_addr, w_data, w_data);
    end
  endtask

  // Task auxiliar para leitura (Modificada para %c)
  task read_mem(input [ADDR_WIDTH-1:0] r_addr, input [DATA_WIDTH-1:0] exp_data);
    begin
      #1; 
      bus.write = 0;
      bus.read  = 1;
      bus.addr  = r_addr;
      
      #1; 
      
      if (bus.data_out !== exp_data) begin
        $display("[ERRO] Addr %0d. Esperado: %c (%h), Obtido: %c (%h)", 
                 r_addr, exp_data, exp_data, bus.data_out, bus.data_out);
        $finish; 
      end else begin
         // Debug opcional para confirmar leitura
         // $display("[READ ] Addr: %0d | Hex: %h | Char: %c [OK]", r_addr, bus.data_out, bus.data_out);
      end
      
      bus.read = 0; 
    end
  endtask

  // Sequência de Teste Principal
  initial begin
    tr = new(); // Cria o objeto de randomização
    mem_depth = 1 << ADDR_WIDTH;

    // Inicialização
    bus.read = 0; bus.write = 0; bus.addr = 0; bus.data_in = 0;
    @(posedge bus.clk); 

    $display("\n--- INICIANDO TESTE COM CONSTRAINTS E PESOS ---");
    
    // 1. Loop de Escrita Randomizada
    $display("--- Gerando e Escrevendo Dados ---");
    for (int i = 0; i < mem_depth; i++) begin
      
      // Randomiza o objeto 'tr' aplicando as constraints ativas
      if (!tr.randomize()) begin
        $display("Erro na randomização!");
        $finish;
      end
      
      scoreboard[i] = tr.data;
      write_mem(i[ADDR_WIDTH-1:0], tr.data);
    end

    // 2. Loop de Leitura e Verificação
    $display("\n--- Lendo e Verificando Dados ---");
    for (int i = 0; i < mem_depth; i++) begin
      read_mem(i[ADDR_WIDTH-1:0], scoreboard[i]);
    end

    $display("\n--- SUCESSO: TODOS OS DADOS VALIDADOS ---");
    $finish;
  end

endmodule