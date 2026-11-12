module tb_prog_rom();

    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 16;

    reg  [ADDR_WIDTH-1:0] addr;
    wire [DATA_WIDTH-1:0] data;

    prog_rom #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .addr(addr),
        .data(data)
    );

    initial begin
        $display("-------------------------------------------");
        $display("       INICIO DO TESTE: MEMORIA ROM        ");
        $display("-------------------------------------------");
        $monitor("Tempo: %0t | Endereco: %h | Dado Lido: %h", $time, addr, data);

        addr = 8'h00;
        #10;

        addr = 8'h01;
        #10;

        addr = 8'h05;
        #10;

        addr = 8'hFF;
        #10;
        $display("-------------------------------------------");
        $display("                  FIM DO TESTE ");
        $display("-------------------------------------------");
        $stop;
    end

endmodule