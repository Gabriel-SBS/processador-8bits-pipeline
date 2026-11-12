module main_fpga (
    input wire CLOCK_50,     // Clock 50MHz
    input wire KEY,    // KEY[0] = Reset
    output wire [9:0] LEDR   // LEDs vermelhos
);

    // Parâmetros do Sistema
    localparam DATA_WIDTH = 8;
    localparam ADDR_WIDTH = 8;

    // Sinais de Interconexão
    wire [ADDR_WIDTH-1:0] pc_wire;
    wire [15:0] instr_wire;
    wire [ADDR_WIDTH-1:0] ram_addr;
    wire [DATA_WIDTH-1:0] ram_wdata, ram_rdata;
    wire ram_we;
    wire [DATA_WIDTH-1:0] debug_a, debug_b;

    // Sincronizador de Reset (Evita metaestabilidade)
    reg rst_reg1, rst_reg2;
    always @(posedge CLOCK_50) begin
        rst_reg1 <= KEY;
        rst_reg2 <= rst_reg1;
    end
    wire rst_n_clean = rst_reg2;

    // 1. Instância do Processador
    cpu_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) cpu (
        .clk(CLOCK_50),
        .rst_n(rst_n_clean),
        .i_addr(pc_wire),
        .i_data(instr_wire),
        .d_addr(ram_addr),
        .d_wdata(ram_wdata),
        .d_rdata(ram_rdata),
        .d_we(ram_we),
        .debug_reg_a(debug_a),
        .debug_reg_b(debug_b)
    );

    // 2. Instância da ROM
    prog_rom #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(16)
    ) rom (
        .addr(pc_wire),
        .data(instr_wire)
    );

    // 3. Instância da RAM
    data_ram #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram (
        .clk(CLOCK_50),
        .we(ram_we),
        .addr(ram_addr),
        .data_in(ram_wdata),
        .data_out(ram_rdata)
    );

    // Debug nos LEDs
    assign LEDR[7:0] = debug_a;
    assign LEDR[9]   = rst_n_clean;
    assign LEDR[8]   = 1'b0; // LED 8 apagado

endmodule