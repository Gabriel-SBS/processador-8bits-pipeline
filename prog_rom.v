module prog_rom #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 16
)(
    input wire [ADDR_WIDTH-1:0] addr,
    output reg [DATA_WIDTH-1:0] data
);

    // Memória ROM definida pelos parâmetros
    reg [DATA_WIDTH-1:0] ROM [0:(1<<ADDR_WIDTH)-1];

    initial begin
        // Carrega o arquivo HEX na memória ROM
        $readmemh("program.hex", ROM);
    end

    always @(*) begin
        // Leitura assíncrona
        data = ROM[addr];
    end

endmodule