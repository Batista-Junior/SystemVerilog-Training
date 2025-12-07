module genius_fsm (
  input  logic clk,
  input  logic rst_n,
  input  logic speed,
  input  logic start,
  input  logic [1:0] level,
  input  logic mode, 
  input  logic [3:0] buttom,
  output logic [3:0] leds,
  output logic [5:0] score
);

  parameter TIME = 50_000_000;

  typedef enum logic [3:0]{
    S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10
  } fsm_state;

  fsm_state current_state, next_state;



  //SINAIS INTERNOS
  logic [31:0] free_running_counter;
  logic [3:0]  reg_buttom;
  logic        buttom_pressed;
  logic [31:0] saved_seed;
  logic [5:0]  step_counter;
  logic [5:0]  round_counter;
  logic [3:0]  lfsr_decoded;
  logic        verif_flag;
  logic [31:0] timer_counter;
  logic        timer_over;
  logic [5:0]  level_;

  logic [31:0] lfsr_reg;
  logic        load_seed;
  logic        lfsr_en;
  logic        feedback;

  assign level_ = (level+1) * 4'b1000;  // os levels possíveis são 8, 16 e 32

  //free_running_counter
  always_ff @(posedge clk or negedge rst_n) begin
    if(!rst_n)
      free_running_counter <= '0;
    else
      free_running_counter <= free_running_counter + 1;
  end

  //timer
  always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n)
      timer_counter <= '0;
    else if (current_state == S3)
      timer_counter <= TIME;
    else if (current_state == S4 && timer_counter > 0)
      timer_counter <= timer_counter -1;
  end

  assign timer_over = (timer_counter == 32'b0);


  //lfsr provisório tirado do gemini
  assign feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= 32'hDEAD_BEEF; 
        end else begin
            if (load_seed) begin
                lfsr_reg <= saved_seed; 
            end else if (lfsr_en) begin
                lfsr_reg <= {lfsr_reg[30:0], feedback}; 
            end
        end
    end

  // decodificar o LFSR para comparar com o botão pressionado
  always_comb begin 
    case (lfsr_reg[1:0])
    2'b00: lfsr_decoded = 4'b0001;
    2'b01: lfsr_decoded = 4'b0010;
    2'b10: lfsr_decoded = 4'b0100;
    2'b11: lfsr_decoded = 4'b1000;
    default: lfsr_decoded = 4'b0000;
    endcase
  end

  // logica para evitar que o botão pressionado seja lido multiplas vezes
  always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n)
      reg_buttom <= 4'b0;
    else
      reg_buttom <= buttom;
  end

  assign buttom_pressed = (buttom!=0)&&(reg_buttom!=buttom);

  //logica dos contadores
  always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n) begin
      round_counter <= 6'b1;
      step_counter  <= 6'b0;
      score         <= 6'b0;
      saved_seed    <= 32'b1;
      verif_flag    <= 1'b0;
    end else begin 

      case(current_state)
      S0: begin 
        //saved_seed <= free_running_counter;
        saved_seed    <= 32'd1;
        round_counter <= 6'b000001;
        score      <= '0;
        verif_flag <= 1'b0; 
      end

      S2: begin 
        step_counter <= 6'b0;
      end

      S5: begin
        step_counter <= step_counter + 1;
      end 
      S6: begin 
        //step_counter <= 6'b0;
        verif_flag <= !verif_flag;
      end

      //S8: begin
      //  score <= score + 1;
      //end

      S10: begin 
        round_counter <= round_counter + 1;
        score <= score + 1;
      end

      endcase
    end
  end

  //logica proximoo estado 
  always_ff @(posedge clk or negedge rst_n) begin 
    if(!rst_n)
      current_state <= S0;
    else 
      current_state <= next_state;
  end

  //logica de transição 
  always_comb begin
    next_state = current_state;
    load_seed  = 1'b0;
    lfsr_en    = 1'b0;
  //verif_flag = 1'b0;

    case (current_state)

    S0: begin 
      if(start) next_state = S1;
    end

    S1: begin 
      //implementar lógica para ir para o modo "mando eu"
      next_state = S2;
    end

    S2: begin
      load_seed = 1'b1;
      if(verif_flag == 1'b1)
        next_state = S7;
      else
        next_state = S3;
      
    end

    S3: begin 
      next_state = S4;
    end

    S4: begin 
      if(timer_over == 1'b1)
        next_state = S5;
    end

    S5: begin 
      lfsr_en = 1'b1;
      if(step_counter < (round_counter - 1)) begin 
        if(verif_flag == 1'b1)
          next_state = S7;
        else  
          next_state = S3;
      end else
        next_state = S6;
      

    end

    S6: begin 
      if(verif_flag == 1'b1)
        next_state = S10;
      else
        next_state = S2;
    end

    S7: begin 
      if(buttom_pressed)
        next_state = S8;
    end

    S8: begin 
      if(buttom == lfsr_decoded) begin
        // Debug: Acerto
        //$display("[HW-DEBUG] Acertou! Botao: %b, Esperado: %b", buttom, lfsr_decoded);
        next_state = S5;
      end else begin
        // Debug: Erro (AQUI ESTÁ A RESPOSTA)
        $display("[HW-DEBUG] ERRO FATAL em S8! Botao lido: %b | Esperado: %b | Tempo: %t", buttom, lfsr_decoded, $time);
        next_state = S9;
      end
    end

    S9: begin 
      //piscarei as luzes numa sequencia para caso ganhe e outra para caso perca;
      next_state = S0;
    end

    S10: begin 
      if(round_counter == level_)
        next_state = S9;
      else
        next_state = S2;
    end
    endcase
  end

  always_comb begin
        leds = 4'b0000; 

        if (current_state == S3|| current_state == S4) begin
            case (lfsr_reg[1:0]) 
                2'b00: leds = 4'b0001;
                2'b01: leds = 4'b0010;
                2'b10: leds = 4'b0100;
                2'b11: leds = 4'b1000;
            endcase
        end
    end



endmodule