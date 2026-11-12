module tb_data_ram();

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 8;

    reg tb_clk;
    reg tb_we;
    reg [ADDR_WIDTH-1:0] tb_addr;
    reg [DATA_WIDTH-1:0] tb_data_in;
    wire [DATA_WIDTH-1:0] tb_data_out;

    data_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(tb_clk),
        .we(tb_we),
        .addr(tb_addr),
        .data_in(tb_data_in),
        .data_out(tb_data_out)
    );

    initial tb_clk = 0;
    always #10 tb_clk = ~tb_clk;

    initial begin
        $display("-----------------------------------------------------");
        $display("            INICIO DO TESTE: MEMORIA RAM        ");
        $display("-----------------------------------------------------");
        
        tb_we = 0;
        tb_addr = 0;
        tb_data_in = 0;
        #20;

        $display("[tempo=%0t] Escrevendo AAh no endereco 10h...", $time);
        
        @(negedge tb_clk);
        tb_addr = 8'h10;
        tb_data_in = 8'hAA;
        tb_we = 1'b1;
        
        @(negedge tb_clk);
        tb_we = 1'b0;
        tb_addr = 8'h00; 
        #20;
        
        $display("[tempo=%0t] Lendo endereco 10h...", $time);
        tb_addr = 8'h10;
        #5;
        
        if (tb_data_out === 8'hAA)
            $display("SUCESSO: Leu AAh corretamente.");
        else
            $display("ERRO: Leu %h, esperava AAh.", tb_data_out);


        $display("[tempo=%0t] Sobrescrevendo com 55h no endereco 10h...", $time);
        @(negedge tb_clk);
        tb_addr = 8'h10;
        tb_data_in = 8'h55;
        tb_we = 1'b1;
        
        @(negedge tb_clk);
        tb_we = 1'b0;
        
        #5;
        if (tb_data_out === 8'h55)
            $display("SUCESSO: Sobrescreveu para 55h corretamente.");
        else
            $display("ERRO: Leu %h, esperava 55h.", tb_data_out);

        $display("[tempo=%0t] Testando isolamento de enderecos...", $time);
        @(negedge tb_clk);
        tb_addr = 8'h20; tb_data_in = 8'hFF; tb_we = 1;
        @(negedge tb_clk); 
        tb_we = 0;
        
        #5;
        tb_addr = 8'h10; #5;
        if (tb_data_out === 8'h55) $display("OK: Endereco 10h mantido.");
        
        tb_addr = 8'h20; #5;
        if (tb_data_out === 8'hFF) $display("OK: Endereco 20h gravado.");

        $display("-----------------------------------------------------");
        $display("                  FIM DO TESTE ");
        $display("-----------------------------------------------------");
        $finish;
    end

endmodule