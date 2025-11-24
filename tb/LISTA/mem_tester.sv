module mem_test #(
  parameter ADDR_WIDTH = 5,
  parameter DATA_WIDTH = 8
)(
  input  logic clk,
  output logic read,
  output logic write,
  output logic [ADDR_WIDTH-1:0] addr,
  output logic [DATA_WIDTH-1:0] data_in,
  input  logic [DATA_WIDTH-1:0] data_out
);

  timeunit 1ns;
  timeprecision 1ps;

  // Task auxiliar para escrita (Síncrona)
  task write_mem(input [ADDR_WIDTH-1:0] w_addr, input [DATA_WIDTH-1:0] w_data);
    begin
      @(negedge clk); // Muda os dados na borda de descida (setup time seguro para a borda de subida)
      write   = 1;
      read    = 0;
      addr    = w_addr;
      data_in = w_data;
      
      @(negedge clk); // Mantém o sinal ativo por um ciclo completo
      write   = 0;
      addr    = 0;
      data_in = 0;
      $display("Tempo %0t: Escrita -> Addr: %0d | Data: %h", $time, w_addr, w_data);
    end
  endtask

  // Task auxiliar para leitura (Assíncrona/Combinacional)
  task read_mem(input [ADDR_WIDTH-1:0] r_addr, input [DATA_WIDTH-1:0] exp_data);
    begin
      #1; // Pequeno delay
      write = 0;
      read  = 1;
      addr  = r_addr;
      
      #1; // Delay para a lógica combinacional da memória responder
      
      if (data_out !== exp_data) begin
        $display("[FALHA] Tempo %0t: Leitura Addr %0d", $time, r_addr);
        $display("  Esperado: %h", exp_data);
        $display("  Obtido:   %h", data_out);
        $finish; // Para se houver erro
      end else begin
        $display("Tempo %0t: Leitura -> Addr: %0d | Data: %h [OK]", $time, r_addr, data_out);
      end
      
      read = 0; // Desativa leitura ao final
    end
  endtask

  // Task para verificar Alta Impedância (High-Z)
  task check_z();
    begin
      write = 0;
      read  = 0;
      #1;
      if (data_out !== {DATA_WIDTH{1'bz}}) begin
        $display("[FALHA] Tempo %0t: Esperado High-Z (z), mas obtido %h", $time, data_out);
        $finish;
      end else begin
         $display("Tempo %0t: Check High-Z [OK]", $time);
      end
    end
  endtask

  // Sequência de Teste Principal
  initial begin
    $display("--- INICIANDO TESTE DE MEMÓRIA ---");
    
    // 1. Inicialização
    read = 0; write = 0; addr = 0; data_in = 0;
    @(posedge clk); // Espera um ciclo

    // 2. Teste de Escrita
    write_mem(5'd0, 8'hAA); // Escreve AA no endereço 0
    qwrite_mem(5'd1, 8'hBB); // Escreve BB no endereço 1
    write_mem(5'd10,8'h00);
    write_mem(5'd31, 8'hFF); // Escreve FF no último endereço (limite)

    // 3. Teste de Leitura (Deve recuperar o que foi escrito)
    @(negedge clk);
    read_mem(5'd0, 8'hAA);
    read_mem(5'd1, 8'hBB);
    read_mem(5'd31, 8'hFF);

    // 4. Teste de Leitura em endereço não inicializado (Deve ser 0 conforme initial block da memória)
   // read_mem(5'd10, 8'hxx);

    // 5. Teste de High-Z (Quando read=0)
    check_z();

    $display("--- SUCESSO: MEMÓRIA PASSOU EM TODOS OS TESTES ---");
    $finish;
  end

endmodule