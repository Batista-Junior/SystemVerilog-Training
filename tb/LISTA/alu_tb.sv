module alu_tb;

  // Importação dos Opcodes (HLT, ADD, etc.)
  import definitions_pkg::*;

  // Parâmetros e Sinais
  localparam WIDTH = 8;

  logic       clk;
  logic [2:0] opcode;
  logic [WIDTH-1:0] data;  // Equivalente ao in_b do exemplo
  logic [WIDTH-1:0] accum; // Equivalente ao in_a do exemplo (controla flag zero)
  
  logic [WIDTH-1:0] out;   // Saída da ULA
  logic             zero;  // Flag Zero

  // Instanciação da ULA (DUT)
  alu dut (
    .clk    (clk),
    .opcode (opcode),
    .data   (data),
    .accum  (accum),
    .out    (out),
    .zero   (zero)
  );

  // Geração de Clock (Período 10ns)
  initial clk = 0;
  always #5 clk = ~clk;

  // Task de Verificação (Baseada no seu exemplo 'expect')
  task check_alu;
    input [WIDTH-1:0] i_data;
    input [WIDTH-1:0] i_accum;
    input [2:0]       i_opcode;
    input             exp_zero; // Esperado para flag Zero
    input [WIDTH-1:0] exp_out;  // Esperado para saída Out

    begin
      // 1. Configura as entradas
      data   = i_data;
      accum  = i_accum;
      opcode = i_opcode;

      // 2. Aguarda a borda de descida (momento que a ULA escreve 'out')
      @(negedge clk);
      
      // 3. Pequeno delay (delta) para os sinais estabilizarem após a borda
      #1; 

      // 4. Verifica os resultados
      if (zero !== exp_zero || out !== exp_out) begin
        $display("\n[FALHA] Tempo %0t", $time);
        $display("  Inputs: Opcode=%b Data=%h Accum=%h", opcode, data, accum);
        $display("  Output: Zero=%b Out=%h", zero, out);
        $display("  Esperado: Zero=%b Out=%h", exp_zero, exp_out);
        
        if (zero !== exp_zero) $display("  -> Erro na flag Zero (Lembra: Zero depende de Accum!)");
        if (out !== exp_out)   $display("  -> Erro no valor de Out");
        
        $finish; // Para a simulação em caso de erro
      end else begin
        // Sucesso (opcional: comentar para limpar o log)
        $display("Tempo %0t | Op=%s | In(%h, %h) -> Out=%h Zero=%b [OK]", 
                 $time, i_opcode, data, accum, out, zero);
      end
    end
  endtask

  // Sequência de Testes
  initial begin
    $display("--- INICIANDO TESTBENCH DA ULA ---");

    // Reset inicial (opcional, apenas para garantir estado conhecido)
    accum = 0; data = 0; opcode = HLT;
    @(negedge clk);

    // Formato: check_alu(data, accum, opcode, exp_zero, exp_out)
    
    // 1. Teste ADD (0x02 + 0x03 = 0x05) | Zero deve ser 0 (accum != 0)
    check_alu(8'h02, 8'h03, ADD, 1'b0, 8'h05);

    // 2. Teste AND (0xFF & 0x0F = 0x0F)
    check_alu(8'hFF, 8'h0F, AND, 1'b0, 8'h0F);

    // 3. Teste XOR (0xAA ^ 0x55 = 0xFF)
    check_alu(8'hAA, 8'h55, XOR, 1'b0, 8'hFF);

    // 4. Teste LDA (Carrega Data -> Out) | Deve ignorar Accum no cálculo, mas Zero olha Accum
    check_alu(8'hBE, 8'h10, LDA, 1'b0, 8'hBE);

    // 5. Teste Pass-Through (HLT, SKZ, STO, JMP) -> Out = Accum
    check_alu(8'h00, 8'h42, HLT, 1'b0, 8'h42);
    check_alu(8'h00, 8'h42, SKZ, 1'b0, 8'h42);
    check_alu(8'h00, 8'h42, STO, 1'b0, 8'h42);
    check_alu(8'h00, 8'h42, JMP, 1'b0, 8'h42);

    // --- TESTES DE FLAG ZERO ---
    
    // 6. Teste Zero Flag ATIVADO (Accum = 0)
    // Note: Para ADD, 0 + 5 = 5. Out será 5, mas Zero será 1 porque a entrada Accum é 0.
    check_alu(8'h05, 8'h00, ADD, 1'b1, 8'h05);

    // 7. Teste Zero Flag DESATIVADO com Resultado Zero
    // Caso interessante: Accum=5, Data=-5 (FB). Resultado=0.
    // Zero deve ser 0, pois a ENTRADA Accum era 5.
    check_alu(8'hFB, 8'h05, ADD, 1'b0, 8'h00);

    $display("\n--- TEST PASSED: TODOS OS CASOS CORRETOS ---");
    $finish;
  end

endmodule