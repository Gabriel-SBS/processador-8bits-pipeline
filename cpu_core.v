module cpu_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    
    // Interface de Instrução (ROM)
    output wire [ADDR_WIDTH-1:0] i_addr,
    input wire [15:0]            i_data,
    
    // Interface de Dados (RAM)
    output wire [ADDR_WIDTH-1:0] d_addr,
    output wire [DATA_WIDTH-1:0] d_wdata,
    input wire  [DATA_WIDTH-1:0] d_rdata,
    output reg                   d_we,
    
    // Debug
    output wire [DATA_WIDTH-1:0] debug_reg_a,
    output wire [DATA_WIDTH-1:0] debug_reg_b
);

    // Definição da ISA
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


    // Estado do Processador
    reg [ADDR_WIDTH-1:0] PC;
    reg [DATA_WIDTH-1:0] RegA, RegB;

    // Registros de pipeline
    reg [15:0] if_id_instr; 
    reg        if_id_valid;

    // Sinais do estágio ID
    reg [3:0]            id_ex_opcode; 
    reg [7:0]            id_ex_imm;
    reg [DATA_WIDTH-1:0] id_ex_val_a;
    reg [DATA_WIDTH-1:0] id_ex_val_b;
    reg                  id_ex_valid;
 
  
    // Estagio de fetch
    wire branch_taken;
    reg [ADDR_WIDTH-1:0] branch_target;
    
    assign i_addr = PC;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PC <= 0;
            if_id_instr <= 0;
            if_id_valid <= 0;
        end else begin
            if (branch_taken) begin
                PC <= branch_target;
                if_id_valid <= 1'b0; // Flush IF/ID
                if_id_instr <= 16'b0;
            end else begin
                PC <= PC + 1'b1;
                if_id_instr <= i_data; // Captura instrução da ROM
                if_id_valid <= 1'b1;
            end
        end
    end

    // Estagio de decode
    wire [3:0] decode_opcode = if_id_instr[15:12];
    wire [7:0] decode_imm    = if_id_instr[7:0];
    
    reg [DATA_WIDTH-1:0] forward_A_to_ID;
    reg [DATA_WIDTH-1:0] forward_B_to_ID;
    
    // Sinais de Forwarding
    reg ex_writes_A; 
    reg ex_writes_B;
    reg [DATA_WIDTH-1:0] ex_result_A;
    reg [DATA_WIDTH-1:0] ex_result_B;

    always @(*) begin
        // Forwarding para A
        if (ex_writes_A) forward_A_to_ID = ex_result_A;
        else             forward_A_to_ID = RegA;

        // Forwarding para B
        if (ex_writes_B) forward_B_to_ID = ex_result_B;
        else             forward_B_to_ID = RegB;
    end

    // Registro de pipeline ID/EX
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            id_ex_opcode <= CMD_NOP;
            id_ex_imm    <= 0;
            id_ex_val_a  <= 0;
            id_ex_val_b  <= 0;
            id_ex_valid  <= 0;
        end else begin
            if (branch_taken) begin
                // Flush ID/EX se houve pulo
                id_ex_opcode <= CMD_NOP;
                id_ex_valid  <= 1'b0;
            end else if (if_id_valid) begin
                id_ex_opcode <= decode_opcode;
                id_ex_imm    <= decode_imm;
                id_ex_val_a  <= forward_A_to_ID;
                id_ex_val_b  <= forward_B_to_ID;
                id_ex_valid  <= 1'b1;
            end else begin
                // Bolha no pipeline
                id_ex_opcode <= CMD_NOP;
                id_ex_valid  <= 1'b0;
            end
        end
    end

    // Estagio de execução

    // Endereço de dados:
    assign d_addr = (id_ex_opcode == CMD_LDI || id_ex_opcode == CMD_STI) ? id_ex_val_b : id_ex_imm;
    
    // Dado de escrita:
    assign d_wdata = (id_ex_opcode == CMD_STB) ? id_ex_val_b :
                     (id_ex_opcode == CMD_STA || id_ex_opcode == CMD_STI) ? id_ex_val_a :
                     (id_ex_opcode == CMD_ADD) ? (id_ex_val_a + id_ex_val_b) : 
                     (id_ex_opcode == CMD_SUB) ? (id_ex_val_a - id_ex_val_b) : 8'b0;

    // Lógica Combinacional da ALU e Controle de Pulo
    always @(*) begin
        ex_writes_A = 1'b0;
        ex_writes_B = 1'b0;
        d_we        = 1'b0;
        ex_result_A = id_ex_val_a;
        ex_result_B = id_ex_val_b;
        
        branch_target = id_ex_imm;
        
        case (id_ex_opcode)
            CMD_ADD: begin 
                d_we = 1'b1;
            end
            CMD_SUB: d_we = 1'b1;
            
            CMD_LDA: begin
                ex_writes_A = 1'b1;
                ex_result_A = d_rdata;
            end
            
            CMD_STA: d_we = 1'b1;
            
            CMD_LDB: begin
                ex_writes_B = 1'b1;
                ex_result_B = d_rdata;
            end
            
            CMD_STB: d_we = 1'b1;
            
            CMD_LDC: begin
                ex_writes_A = 1'b1;
                ex_result_A = id_ex_imm;
            end
            
            CMD_AND: begin
                ex_writes_A = 1'b1;
                ex_result_A = id_ex_val_a & id_ex_val_b;
            end
            
            CMD_OR: begin
                ex_writes_A = 1'b1;
                ex_result_A = id_ex_val_a | id_ex_val_b;
            end
            
            CMD_LDI: begin
                ex_writes_A = 1'b1;
                ex_result_A = d_rdata;
            end
            
            CMD_STI: d_we = 1'b1;
            
            CMD_SWP: begin
                ex_writes_A = 1'b1;
                ex_writes_B = 1'b1;
                ex_result_A = id_ex_val_b;
                ex_result_B = id_ex_val_a;
            end
            
            default: ;
        endcase
    end

    // Lógica de decisão de Pulo
    assign branch_taken = id_ex_valid && (
                          (id_ex_opcode == CMD_JMP) || 
                          (id_ex_opcode == CMD_JZ && id_ex_val_a == 0)
                          );

    // Atualização dos registradores arquiteturais
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            RegA <= 0;
            RegB <= 0;
        end else if (id_ex_valid) begin
            if (ex_writes_A) RegA <= ex_result_A;
            if (ex_writes_B) RegB <= ex_result_B;
        end
    end

    assign debug_reg_a = RegA;
    assign debug_reg_b = RegB;

endmodule