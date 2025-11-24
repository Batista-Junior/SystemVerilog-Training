module controller_tb;

  import definitions_pkg::*;

  // Sinais
  logic clk;
  logic rst_;
  logic zero;
  logic [2:0] opcode;
  logic mem_rd, load_ir, halt, in_pc, load_ac, load_pc, mem_wr;

  // Instanciação do DUT
  controller dut (
    .clk     (clk),
    .rst_    (rst_),
    .zero    (zero),
    .opcode  (opcode),
    .mem_rd  (mem_rd),
    .load_ir (load_ir),
    .halt    (halt),
    .in_pc   (in_pc),
    .load_ac (load_ac),
    .load_pc (load_pc),
    .mem_wr  (mem_wr)
  );

  // Clock
  initial clk = 0;
  always #5 clk = ~clk;

  int phase_counter;

  // Task de Verificação
  task check(input logic [6:0] exp_out);
    state_t state_debug;
    opcode_t opcode_debug;

    // Pequeno delay para estabilidade
    #1; 

    state_debug  = state_t'(dut.current_state);
    opcode_debug = opcode_t'(opcode);

    if ({mem_rd, load_ir, halt, in_pc, load_ac, load_pc, mem_wr} !== exp_out) begin
      $display("\n[FALHA] Tempo: %0t", $time);
      $display("  Opcode: %s (Zero: %b)", opcode_debug.name(), zero); 
      $display("  Estado: %s", state_debug.name()); 
      $display("  Esperado: %b (rd, ir, hlt, ipc, ac, pc, wr)", exp_out);
      $display("  Obtido:   %b_%b_%b_%b_%b_%b_%b", mem_rd, load_ir, halt, in_pc, load_ac, load_pc, mem_wr);
      $finish;
    end
    
    phase_counter++;
    @(negedge clk); 
  endtask

  // Task auxiliar para rodar ciclo padrão de fetch
  task run_fetch_cycle();
    check(7'b0000000); // INST_ADDR
    check(7'b1000000); // INST_FETCH
    check(7'b1100000); // INST_LOAD
    check(7'b1100000); // IDLE
    check(7'b0001000); // OP_ADDR (Padrão para não-HLT)
  endtask

  // Sequência de Testes
  initial begin
    $display("--- INICIANDO TESTBENCH COMPLETO ---");
    
    rst_ = 0;
    zero = 0;
    opcode = HLT; 
    phase_counter = 0;

    // Reset inicial
    @(negedge clk);
    @(negedge clk);
    rst_ = 1; 

    // ---------------------------------------------------------
    // 1. TESTE HLT
    // ---------------------------------------------------------
    $display("Testando HLT..."); 
    opcode = HLT; zero = 0; phase_counter = 0;
    
    check(7'b0000000); // INST_ADDR
    check(7'b1000000); // INST_FETCH
    check(7'b1100000); // INST_LOAD
    check(7'b1100000); // IDLE
    check(7'b0011000); // OP_ADDR (Halt=1, in_pc=1)
    
    // Reset para destravar
    rst_ = 0; @(negedge clk); rst_ = 1; 

    // ---------------------------------------------------------
    // 2. TESTE ARITMÉTICO / LÓGICO (ADD, AND, XOR, LDA)
    // Todos compartilham o comportamento ALUOP=1
    // ---------------------------------------------------------
    
    // --- ADD ---
    $display("Testando ADD...");
    opcode = ADD; phase_counter = 0;
    run_fetch_cycle(); // Estados comuns
    check(7'b1000000); // OP_FETCH (rd=1)
    check(7'b1000100); // ALU_OP (rd=1, ac=1)
    check(7'b1000100); // STORE  (rd=1, ac=1)

    // --- AND ---
    $display("Testando AND...");
    opcode = AND; phase_counter = 0;
    run_fetch_cycle();
    check(7'b1000000); // OP_FETCH
    check(7'b1000100); // ALU_OP
    check(7'b1000100); // STORE

    // --- XOR ---
    $display("Testando XOR...");
    opcode = XOR; phase_counter = 0;
    run_fetch_cycle();
    check(7'b1000000); // OP_FETCH
    check(7'b1000100); // ALU_OP
    check(7'b1000100); // STORE

    // --- LDA ---
    $display("Testando LDA...");
    opcode = LDA; phase_counter = 0;
    run_fetch_cycle();
    check(7'b1000000); // OP_FETCH
    check(7'b1000100); // ALU_OP
    check(7'b1000100); // STORE

    // ---------------------------------------------------------
    // 3. TESTE STO
    // ---------------------------------------------------------
    $display("Testando STO...");
    opcode = STO; phase_counter = 0;
    run_fetch_cycle();
    check(7'b0000000); // OP_FETCH (Nada)
    check(7'b0000000); // ALU_OP (Nada)
    check(7'b0000001); // STORE (mem_wr=1)

    // ---------------------------------------------------------
    // 4. TESTE JMP
    // ---------------------------------------------------------
    $display("Testando JMP...");
    opcode = JMP; phase_counter = 0;
    run_fetch_cycle();
    check(7'b0000000); // OP_FETCH
    check(7'b0000010); // ALU_OP (load_pc=1)
    check(7'b0001010); // STORE  (in_pc=1, load_pc=1 conforme tabela/DUT)

    // ---------------------------------------------------------
    // 5. TESTE SKZ (Skip if Zero)
    // ---------------------------------------------------------
    
    // CASO A: Zero = 0 (Não deve pular)
    $display("Testando SKZ (Zero=0)...");
    opcode = SKZ; zero = 0; phase_counter = 0;
    run_fetch_cycle();
    check(7'b0000000); // OP_FETCH
    check(7'b0000000); // ALU_OP (in_pc=0 pois zero=0)
    check(7'b0000000); // STORE

    // CASO B: Zero = 1 (Deve pular -> in_pc = 1)
    $display("Testando SKZ (Zero=1)...");
    opcode = SKZ; zero = 1; phase_counter = 0;
    run_fetch_cycle();
    check(7'b0000000); // OP_FETCH
    check(7'b0001000); // ALU_OP (in_pc=1 pois zero=1)
    check(7'b0000000); // STORE

    $display("\n--- SUCESSO: TODOS OS OPCODES VERIFICADOS! ---");
    $finish;
  end

endmodule