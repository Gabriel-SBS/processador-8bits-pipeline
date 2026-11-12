module data_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk,
    input wire we,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire [DATA_WIDTH-1:0] data_in,
    output wire [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] RAM [0:(1<<ADDR_WIDTH)-1];

    // Inicializa a RAM com zeros
    integer i;
    initial begin
        for (i = 0; i < (1<<ADDR_WIDTH); i = i + 1) begin
            RAM[i] = {DATA_WIDTH{1'b0}};
        end
    end

    // Escrita na RAM
    always @(posedge clk) begin
        if (we)
            RAM[addr] <= data_in;
    end

    // Leitura da RAM
    assign data_out = RAM[addr];

endmodule