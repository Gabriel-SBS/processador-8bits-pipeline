module tb_cpu_core();

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 8;
    
    // Sinais de teste
    reg clk;
    reg rst_n;
    wire [ADDR_WIDTH-1:0] i_addr;
    reg  [15:0] i_data;
    wire [ADDR_WIDTH-1:0] d_addr;
    wire [DATA_WIDTH-1:0] d_wdata; 
    reg  [DATA_WIDTH-1:0] d_rdata;
    wire d_we; // Sinal de escrita na RAM
    wire [DATA_WIDTH-1:0] debug_reg_a;
    wire [DATA_WIDTH-1:0] debug_reg_b;

    localparam CMD_NOP = 4'b0000; // Nenhuma operação
    localparam CMD_ADD = 4'b0001; // Adição
    localparam CMD_SUB = 4'b0010; // Subtração
    localparam CMD_LDA = 4'b0011; // Carregar A
    localparam CMD_STA = 4'b0100; // Armazenar A
    localparam CMD_LDB = 4'b0101; // Carregar B
    localparam CMD_STB = 4'b0110; // Armazenar B
    localparam CMD_LDC = 4'b0111; // carregar Constante em A
    localparam CMD_JZ  = 4'b1000; // Pular se zero
    localparam CMD_JMP = 4'b1001; // Pular incondicional
    localparam CMD_AND = 4'b1010; // E lógico
    localparam CMD_OR  = 4'b1011; // OU lógico
    localparam CMD_LDI = 4'b1100; // Carregar Indireto (A recebe RAM[B])
    localparam CMD_STI = 4'b1101; // Armazenar Indireto (RAM[B] = A)
    localparam CMD_SWP = 4'b1110; // Trocar registradores

    reg [15:0] test_rom [0:255];
    reg [7:0]  test_ram [0:255]; 

    cpu_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .i_addr(i_addr),
        .i_data(i_data),
        .d_addr(d_addr),
        .d_wdata(d_wdata),
        .d_rdata(d_rdata),
        .d_we(d_we),
        .debug_reg_a(debug_reg_a),
        .debug_reg_b(debug_reg_b)
    );

    initial clk = 0;
    always #10 clk = ~clk;

    // Simula a ROM e RAM
    always @(*) begin
        i_data = test_rom[i_addr];
    end

    always @(*) begin
        d_rdata = test_ram[d_addr];
    end

    // Escrita na RAM
    always @(posedge clk) begin
        if (d_we) begin
            test_ram[d_addr] <= d_wdata;
            $display("Tempo %t | ESCRITA RAM : Addr [%h] = %h", $time, d_addr, d_wdata);
        end
    end

    // Programa de Teste
    initial begin
        rst_n = 0;
        begin : clear_mems
            integer i;
            for(i=0; i<256; i=i+1) begin
                test_rom[i] = {CMD_NOP, 8'h00};
                test_ram[i] = 8'h00;
            end
        end
            // 1. Carrega 5 em A
            // 2. Troca A para B
            // 3. Carrega 3 em A
            // 4. Faz OR entre A e B (3 OR 5 = 7)
            // 5. Armazena resultado em RAM[0x80]
            // 6. Carrega 5 em A
            // 7. Adiciona B (A = 5 + 7 = 12)
            // 8. Armazena resultado em RAM[0x00]
            // 9. Loop infinito
        test_rom[0] = {CMD_LDC, 4'h0, 8'h05}; 
        test_rom[1] = {CMD_SWP, 4'h0, 8'h00}; 
        test_rom[2] = {CMD_LDC, 4'h0, 8'h03}; 
        test_rom[3] = {CMD_OR,  4'h0, 8'h00}; 
        test_rom[4] = {CMD_STA, 4'h0, 8'h80}; 
        test_rom[5] = {CMD_ADD, 4'h0, 8'h00};
        test_rom[6] = {CMD_STA, 4'h0, 8'h81};
        test_rom[7] = {CMD_JMP, 4'h0, 8'h07};
        #20 rst_n = 1;
        
        $display("-------------------------------------------------------------------");
        $display("                  INICIO DO TESTE: CPU CORE                        ");
        $display("-------------------------------------------------------------------");
        $monitor("Tempo %t | PC: %h | A: %h | B: %h | Instr: %h", $time, i_addr, debug_reg_a, debug_reg_b, i_data);
        #300;
        $display("-------------------------------------------------------------------");
        $display("                       FIM DA SIMULACAO ");
        $display("-------------------------------------------------------------------");
        $display("                      VERIFICACAO FINAL");
        $display("-------------------------------------------------------------------");
        
        // Verifica se o OR funcionou e foi salvo corretamente
        if (test_ram[8'h80] === 8'h07)
            $display("PASSOU: RAM[80] contem 07 (Resultado do OR)");
        else
            $display("FALHOU: RAM[80] contem %h, esperava 07", test_ram[8'h80]);
        if (test_ram[8'h00] === 8'h0C)
            $display("PASSOU: RAM[00] contem 0C (Resultado da SOMA 7+5)");
        else
            $display("FALHOU: RAM[00] contem %h, esperava 0C", test_ram[8'h00]);
            
        // Verifica se o STA 0x81 salvou o registrador A
        if (test_ram[8'h81] === 8'h07)
            $display("PASSOU: RAM[81] contem 07 (Valor de A mantido)");
        else
            $display("FALHOU: RAM[81] contem %h, esperava 07", test_ram[8'h81]);
        
        
        $finish;
    end

endmodule