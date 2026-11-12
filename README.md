# Processador de 8 bits com pipeline de 3 estágios em Verilog

Fiz este processador em novembro de 2025, no programa de Sistemas Digitais do CEPEDI. Ele tem dois registradores (A e B) e um pipeline de 3 estágios (busca, decodificação e execução) com forwarding. Sintetizei no Quartus Prime e gravei numa placa DE0-CV, que usa uma FPGA Cyclone V.

## Arquitetura

```
           ┌──────────┐ i_addr (PC)  ┌──────────┐
           │ prog_rom │◀─────────────│          │
           │ 256 × 16 │─────────────▶│ cpu_core │── debug_reg_a ──▶ LEDR[7:0]
           └──────────┘ i_data       │          │
           ┌──────────┐ d_addr/wdata │ IF → ID  │
           │ data_ram │◀─────────────│   → EX   │
           │ 256 × 8  │─────────────▶│          │
           └──────────┘ d_rdata      └──────────┘
```

Dados e endereços têm 8 bits. As instruções têm 16: os bits `[15:12]` são o opcode, `[7:0]` são o imediato ou o endereço, e `[11:8]` não são usados.

O pipeline tem os estágios IF, ID e EX, separados pelos registradores IF/ID e ID/EX. Quando a instrução em EX vai gravar em A ou B, o valor novo é repassado direto para a instrução que está em ID, então dependências entre instruções seguidas não geram bolha. Os desvios são resolvidos em EX; se o desvio é tomado, IF/ID e ID/EX são esvaziados e se perdem 2 ciclos.

A ROM de programa tem 256 palavras de 16 bits, leitura assíncrona e é carregada de `program.hex`. A RAM de dados tem 256 bytes, com escrita síncrona e leitura assíncrona.

## Conjunto de instruções

| Opcode | Instrução | Efeito |
|---|---|---|
| `0000` | NOP | nada |
| `0001` | ADD imm | `RAM[imm] ← A + B` |
| `0010` | SUB imm | `RAM[imm] ← A − B` |
| `0011` | LDA imm | `A ← RAM[imm]` |
| `0100` | STA imm | `RAM[imm] ← A` |
| `0101` | LDB imm | `B ← RAM[imm]` |
| `0110` | STB imm | `RAM[imm] ← B` |
| `0111` | LDC imm | `A ← imm` |
| `1000` | JZ imm | se `A == 0`, `PC ← imm` |
| `1001` | JMP imm | `PC ← imm` |
| `1010` | AND | `A ← A & B` |
| `1011` | OR | `A ← A \| B` |
| `1100` | LDI | `A ← RAM[B]` (indireto) |
| `1101` | STI | `RAM[B] ← A` (indireto) |
| `1110` | SWP | troca A e B |

Repare que ADD e SUB não gravam em A: o resultado vai para a memória, no endereço do imediato.

## Na FPGA

O topo `main_fpga.v` liga o processador, a ROM e a RAM ao clock de 50 MHz da placa. O botão `KEY[0]` é o reset; ele passa por 2 flip-flops antes de chegar ao processador, para evitar metaestabilidade. Os LEDs `LEDR[7:0]` mostram o registrador A, e o `LEDR[9]` acende quando o reset está solto.

O `program.hex` que está no repositório faz escritas indiretas com `STI`, troca os registradores, soma e termina num laço no endereço `0x0C`.

### Resultado da síntese (Quartus Prime 20.1.1 Lite, 5CEBA4F23C7)

| Métrica | Valor |
|---|---|
| Lógica | 1.103 ALMs de 18.480 (6 %) |
| Registradores | 2.118 |
| Pinos | 12 de 224 |
| Fmax (modelo lento, 85 °C) | 79,23 MHz |
| Folga de setup a 50 MHz | 7,378 ns |

Nenhum bloco de RAM da FPGA foi usado: como as duas memórias têm leitura assíncrona, o Quartus as montou com registradores, e é daí que vêm os 2.118. Os resumos completos estão em [`docs/`](docs/).

## Testbenches

| Testbench | O que testa |
|---|---|
| `tb_cpu_core.v` | roda um programa com LDC, SWP, OR, STA, ADD e JMP e confere 3 posições da RAM (`PASSOU`/`FALHOU`) |
| `tb_data_ram.v` | escrita, sobrescrita e isolamento entre endereços |
| `tb_prog_rom.v` | leitura da ROM carregada de `program.hex` |
| `tb_main_fpga.v` | sistema completo com reset e `program.hex`, acompanhando PC, instrução e LEDs |

## Como rodar

No Quartus, abra `proc8bits.qpf`, compile e grave na placa. A pinagem da DE0-CV já está no `proc8bits.qsf`.

Para simular com o Icarus Verilog:

```bash
iverilog -o sim_cpu testbenchs/tb_cpu_core.v cpu_core.v && vvp sim_cpu
iverilog -o sim_ram testbenchs/tb_data_ram.v data_ram.v && vvp sim_ram
iverilog -o sim_top testbenchs/tb_main_fpga.v main_fpga.v cpu_core.v prog_rom.v data_ram.v && vvp sim_top
```

Os testbenches também rodam no ModelSim pelo NativeLink do Quartus.

## Arquivos

| Arquivo | Conteúdo |
|---|---|
| `cpu_core.v` | núcleo do processador (pipeline, forwarding, ULA, desvios) |
| `prog_rom.v`, `data_ram.v` | memórias de programa e de dados |
| `main_fpga.v` | topo para a placa |
| `program.hex` | programa carregado na ROM |
| `proc8bits.qpf`, `proc8bits.qsf`, `proc8bits.sdc` | projeto do Quartus, pinagem e restrição de clock |
| `testbenchs/` | testbenches |
| `docs/` | resumos de síntese e timing |
