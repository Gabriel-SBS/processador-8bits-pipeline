# Processador de 8 bits com pipeline de 3 estágios em Verilog

Processador de 8 bits com dois registradores (A e B), pipeline de 3 estágios (busca, decodificação e execução) com *forwarding*, sintetizado com o Quartus Prime para uma FPGA Cyclone V (placa DE0-CV). Desenvolvido em novembro de 2025 no programa de Sistemas Digitais do CEPEDI.

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

- **Dados e endereços de 8 bits; instruções de 16 bits:** `[15:12]` opcode e `[7:0]` imediato ou endereço (bits `[11:8]` não usados).
- **Pipeline:** busca (IF), decodificação (ID) e execução (EX), com registradores IF/ID e ID/EX.
- **Forwarding:** o resultado que a instrução em EX vai gravar em A ou B é repassado direto para a instrução em ID, sem bolhas.
- **Desvios:** resolvidos em EX. Quando o desvio é tomado, IF/ID e ID/EX são esvaziados (*flush*), com custo de 2 ciclos.
- **Memórias:** ROM de programa (256 × 16, leitura assíncrona, carregada de `program.hex`) e RAM de dados (256 × 8, escrita síncrona e leitura assíncrona).

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

ADD e SUB gravam o resultado na memória, no endereço dado pelo imediato, e não em A.

## Na FPGA

O topo `main_fpga.v` liga o processador, a ROM e a RAM ao clock de 50 MHz da placa:

- `KEY[0]` é o reset, sincronizado com 2 flip-flops para evitar metaestabilidade.
- `LEDR[7:0]` mostra o registrador A, e `LEDR[9]` mostra o estado do reset.

O `program.hex` incluído faz escritas indiretas (`STI`), troca de registradores e uma soma, e termina num laço no endereço `0x0C`.

### Resultado da síntese (Quartus Prime 20.1.1 Lite, 5CEBA4F23C7)

| Métrica | Valor |
|---|---|
| Lógica | 1.103 ALMs de 18.480 (6 %) |
| Registradores | 2.118 |
| Pinos | 12 de 224 |
| Fmax (modelo lento, 85 °C) | 79,23 MHz |
| Folga de setup a 50 MHz | 7,378 ns |

As memórias foram implementadas em registradores (0 blocos de RAM) porque a leitura é assíncrona. Os resumos completos estão em [`docs/`](docs/).

## Testbenches

| Testbench | O que testa |
|---|---|
| `tb_cpu_core.v` | roda um programa com LDC, SWP, OR, STA, ADD e JMP e confere 3 posições da RAM (`PASSOU`/`FALHOU`) |
| `tb_data_ram.v` | escrita, sobrescrita e isolamento entre endereços |
| `tb_prog_rom.v` | leitura da ROM carregada de `program.hex` |
| `tb_main_fpga.v` | sistema completo com reset e `program.hex`, acompanhando PC, instrução e LEDs |

## Como rodar

**Quartus:** abra `proc8bits.qpf`, compile e grave na placa. A pinagem já está no `proc8bits.qsf`.

**Simulação com Icarus Verilog:**

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
