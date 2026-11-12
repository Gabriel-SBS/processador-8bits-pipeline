`timescale 1ns / 1ns

module tb_main_fpga();

    // Sinais para a FPGA
    reg CLOCK_50;
    reg KEY; // KEY[0] é o Reset
    wire [9:0] LEDR;

    // Instância do Top Level
    main_fpga dut (
        .CLOCK_50(CLOCK_50),
        .KEY(KEY),
        .LEDR(LEDR)
    );

    // Geração de Clock (50MHz -> Período de 20ns)
    initial CLOCK_50 = 0;
    always #10 CLOCK_50 = ~CLOCK_50;

    initial begin
        KEY = 0;

        $display("----------------------------------------------------------------------------------------");
        $display("         INICIO DO TESTE: MAIN FPGA         ");
        $display("----------------------------------------------------------------------------------------");
        $monitor("Tempo: %0t | Reset: %b | LEDR (Reg A): %h | PC (Interno): %h | Instrucao %h", $time, KEY, LEDR[7:0], dut.pc_wire, dut.instr_wire);
        #50;
        $display("----------------------------------------------------------------------------------------");
        KEY = 1; 
        #1000;
        $display("----------------------------------------------------------------------------------------");
        $display("            FIM DO TESTE ");
		  $display("----------------------------------------------------------------------------------------");
        $finish;
    end

endmodule