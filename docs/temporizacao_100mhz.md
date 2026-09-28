# Correção de temporização interna — 100 MHz

Configuração final: MAX 10 10M08SCE144C8G, Quartus Prime Lite 24.1std.0.
Clock físico confirmado pelo usuário: 100 MHz (10 ns).

## Escopo e alterações

- `sensor_buchas.bdf` e `sensor_buchas.qsf` foram restaurados, byte a byte,
  à versão que estava funcionando antes da remoção dos monitores.
  Pino 10: `debug` / `adc_convst[1]`; pino 12: `debug_res` / `adc_convst[2]`;
  pino 13: `ncs` / `adc_convst[0]`.
- `uart_tx.v`: somente a soma do checksum passou de combinacional para quatro
  estágios registrados. A soma continua sendo a soma unsigned dos 72 bytes;
  os dois bytes continuam com OR de `0x80`. A máquina de estados inteira,
  divisores, payload, cabeçalho, ordem dos bytes e sinais de controle não mudaram.
- A equivalência de transmissão pressupõe o contrato existente deste projeto:
  o resultado DFT fica estável durante a transmissão, até `done`. O checksum
  agora acompanha `data_in` com quatro ciclos de latência interna; há milhares
  de ciclos antes de seu uso. Isso não é equivalência combinacional para um
  módulo isolado com `data_in` alterado imediatamente antes do checksum.
- `sensor_buchas.sdc`: mantido o clock de 100 MHz, derivadas as incertezas e
  definidos os quatro clocks internos antes sem restrições. Foram removidas
  referências antigas a `host_SCLK`, `inst14` e `inst9` que não correspondiam
  ao circuito atual. Nenhum false path ou multicycle novo foi adicionado.
- Os clocks produzidos por registradores usam um envelope de 20 ns, com
  transições a cada 10 ns (limite conservador do registrador de origem).
  O controle de flash segue a borda negativa de `clk`. A análise mantém os
  caminhos entre esses clocks e o clock principal.

Os cálculos DFT, aquisição, RAM, SPI e máquinas de estados não foram editados.

## Validação final

Compilação completa: 0 erros. Os avisos restantes incluem interfaces externas
sem restrições, avisos do IP fornecido pelo fabricante e análise de potência;
compilação sem erros não significa ausência de todos os avisos do projeto.

Piores margens entre Slow 1200mV 85C, Slow 1200mV 0C e Fast 1200mV 0C:

| Verificação | Slack mínimo |
|---|---:|
| Setup | +0,741 ns |
| Hold | +0,045 ns |
| Recovery | +3,251 ns |
| Removal | +0,244 ns |
| Largura mínima de pulso | +2,717 ns |

TNS = 0 em todas as verificações; zero clocks internos sem restrições.
A margem de hold é pequena: novas alterações exigem recompilação e nova análise.

Simulação Icarus Verilog 12.0: 4.705.052 ciclos, sete quadros completos, dados
zero, todos os bits em um, padrões aleatórios, reinício sem reset e reset
interrompendo transmissão. `tx`, `busy` e `done` foram comparados em cada ciclo
contra uma cópia congelada do módulo anterior. O checksum foi também comparado
com uma soma independente para 1.000 entradas consecutivas variáveis.
Resultado: PASS.

Reproduzir (com Quartus, Python 3 e Icarus Verilog no PATH):

```sh
quartus_sh --flow compile sensor_buchas
python3 scripts/check_timing.py
bash tests/run_uart_timing.sh
```

O relatório da compilação está em `output_files/sensor_buchas.sta.rpt`.
Arquivos de programação: `output_files/sensor_buchas.sof` e `.pof`.
SHA-256 do SOF validado:
`4c8559c7609073e10665e4a3d9b3bcfdad26fe80a3549331db51a73ef63d7834`.

## Limite da validação

Conforme solicitado, a temporização de placa (RAM, ADCs e demais I/Os) foi
adiada: não foram inventados input/output delays nem excluídas essas interfaces
com false paths. O fechamento informado é interno, sob as restrições descritas.
O bitstream ainda precisa do teste funcional na placa; não foi gravado no hardware.
