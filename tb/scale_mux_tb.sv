`timescale 1ns/1ps

module scale_mux_tb;

  // 1. Definir Parâmetros
  parameter WIDTH = 8;

  // 2. Declarar sinais para conectar ao DUT
  logic [WIDTH-1:0] in_a;
  logic [WIDTH-1:0] in_b;
  logic             sel_a;
  logic [WIDTH-1:0] out;

  // 3. Instanciar o Design Under Test (DUT)
  scale_mux #(.WIDTH(WIDTH)) dut (
    .in_a (in_a),
    .in_b (in_b),
    .sel_a(sel_a),
    .out  (out)
  );

  // 4. Bloco de Testes
  initial begin
    // Formatação para facilitar leitura
    $timeformat(-9, 2, " ns", 10);
    $display("Iniciando Teste do MUX (WIDTH=%0d)...", WIDTH);
    $display("---------------------------------------------------------------");
    $display("Time      | Sel | In A     | In B     | Out      | Status");
    $display("---------------------------------------------------------------");

    // --- Teste 1: Selecionar A ---
    sel_a = 1;
    in_a  = 8'hAA;
    in_b  = 8'h55;
    #10; 
    check_output(in_a, "Select A");

    // --- Teste 2: Selecionar B ---
    sel_a = 0;
    in_a  = 8'hF0;
    in_b  = 8'h0F;
    #10;
    check_output(in_b, "Select B");

    // --- Teste 3: Teste Aleatório (Randomizado) ---
    repeat (5) begin
      sel_a = $random;      // Randomiza o seletor (0 ou 1)
      in_a  = $random;      // Randomiza entrada A
      in_b  = $random;      // Randomiza entrada B
      #10;
      
      // Verifica qual deveria ser a saída esperada
      if (sel_a) 
        check_output(in_a, "Random A");
      else       
        check_output(in_b, "Random B");
    end

    // --- Teste 4: Propagação de X (Estado desconhecido) ---
    sel_a = 1'bx;
    in_a  = 8'hFF;
    in_b  = 8'h00;
    #10;
    
    if (out === 'x) // Usamos === para comparar 'x' exatamente
        $display("%t | x   | %h       | %h       | %h       | PASS (X Prop)", $time, in_a, in_b, out);
    else
        $display("%t | x   | %h       | %h       | %h       | FAIL (Expected X)", $time, in_a, in_b, out);

    $display("---------------------------------------------------------------");
    $display("Fim dos testes.");
    $finish;
  end

  // Task auxiliar para verificar e imprimir resultados automaticamente
  task check_output(input [WIDTH-1:0] expected, input string msg);
    if (out === expected) begin
      $display("%t | %b   | %h       | %h       | %h       | PASS (%s)", 
               $time, sel_a, in_a, in_b, out, msg);
    end else begin
      $display("%t | %b   | %h       | %h       | %h       | FAIL (%s - Exp: %h)", 
               $time, sel_a, in_a, in_b, out, msg, expected);
    end
  endtask

endmodule