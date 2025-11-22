`timescale 1ns/1ps
 
module counter_tb;
 
    parameter WIDTH = 4;
    logic clk;
    logic rst_n;
    logic en;
    logic [WIDTH-1:0] count;
 
    counter #(.WIDTH(WIDTH)) dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .count(count)
    );
 
    initial clk = 0;
    always #5 clk = ~clk;
 
    initial begin
        rst_n = 0;
        en = 0;
        #20;
 
        rst_n = 1;
        #10;
 
        en = 1;
        #100;
 
        en = 0;
        #30;
 
        rst_n = 0;
        #20;
        rst_n = 1;
 
        #30;
        $finish;
    end
 
    initial begin
        $monitor("Time=%0t | rst_n=%b | en=%b | count=%0d", $time, rst_n, en, count);
    end
 
endmodule