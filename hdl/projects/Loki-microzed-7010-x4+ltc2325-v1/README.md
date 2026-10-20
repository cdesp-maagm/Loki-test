
Interfaçage du module MicroZed
==============================

Ces entrées/sorties sont reliées à des périphériques intégrés dans le
Zynq Processing System à travers des broches MIO.
Elles sont gérées logiciellement à travers des drivers Linux.

| Composant               | Interface | MIO    |
|:------------------------|:----------|:-------|
| Capteur de température  | I2C1      | 12, 13 |
| EEPROM pour adresse MAC | I2C0      | 10, 11 |
| GPS                     | UART0     | 14, 15 |
| GPS (reset)             | GPIO      | 9      |
| Alimentation analogique | GPIO      | 0      |
| XADC 0 à 3              | XADC      |        |

Ces entrées/sorties sont reliées au GPIO du Zynq Processing System
à travers la logique programmable.

| Composant | Direction | EMIO  |
|:----------|:----------|:------|
| Switches  | Entrées   | 0, 1  |
| LED       | Sorties   | 0 à 6 |

Récapitulatif des signaux
-------------------------

| Label        | Interface | Broche     | Fait                   |
|:-------------|:----------|:-----------|:-----------------------|
| TEMP_SDA     | I2C1      | MIO13      | `system.tcl`           |
| MAC_SCL      | I2C0      | MIO10      | `system.tcl`           |
| MAC_SDA      | I2C0      | MIO11      | `system.tcl`           |
| TEMP_SCL     | I2C1      | MIO12      | `system.tcl`           |
| GPS_RESET    | GPIO      | MIO9       | Preset                 |
| GPS_RX       | UART0     | MIO14      | `system.tcl`           |
| GPS_TX       | UART0     | MIO15      | `system.tcl`           |
| INIT         |           |            | Matériel               |
| PG_2V5       |           |            | Matériel               |
| PG_CARRIER   |           |            | Matériel               |
| SW_1         | GPIO      | G14, EMIO0 | `system.tcl`, `io.xdc` |
| XADC_0_P     |           |            |                        |
| XADC_0_N     |           |            |                        |
| XADC_1_P     |           |            |                        |
| XADC_1_N     |           |            |                        |
| LTCH_PGA0    |           |            |                        |
| LTCH_PGA1    |           |            |                        |
| LTCH_PGA2    |           |            |                        |
| LTCH_PGA3    |           |            |                        |
| XADC_3_P     |           |            |                        |
| XADC_2_P     |           |            |                        |
| XADC_3_N     |           |            |                        |
| XADC_2_N     |           |            |                        |
| DAC_G0       |           |            |                        |
| DAC_G1       |           |            |                        |
| DAC_G2       |           |            |                        |
| CLK1PPS      |           |            |                        |
| CLK10M00     |           |            |                        |
| CLK30M72     |           |            |                        |
| TSTAMP       |           |            |                        |
| DATA_PGA     |           |            |                        |
| CLK_PGA      |           |            |                        |
| DAC_IQSEL    |           | G18        | `io.xdc`               |
| DAC_IQRESET  |           | F20        | `io.xdc`               |
| DAC_IQWRT    |           | G19        | `io.xdc`               |
| DAC_IQCLK    |           | J20        | `io.xdc`               |
| DAC_DA0      |           | G20        | `io.xdc`               |
| DAC_DA1      |           | H20        | `io.xdc`               |
| DAC_DA2      |           | K14        | `io.xdc`               |
| DAC_DA3      |           | H15        | `io.xdc`               |
| DAC_DA4      |           | J14        | `io.xdc`               |
| DAC_DA5      |           | G15        | `io.xdc`               |
| DAC_DA6      |           | N15        | `io.xdc`               |
| DAC_DA7      |           | L14        | `io.xdc`               |
| DAC_DA8      |           | N16        | `io.xdc`               |
| DAC_DA9      |           | L15        | `io.xdc`               |
| DAC_DA10     |           | M14        | `io.xdc`               |
| DAC_DA11     |           | K16        | `io.xdc`               |
| DAC_DA12     |           | M15        | `io.xdc`               |
| DAC_DA13     |           | J16        | `io.xdc`               |
| LED_0        | GPIO      | Y12, EMIO0 | `system.tcl`, `io.xdc` |
| LED_1        | GPIO      | V11, EMIO1 | `system.tcl`, `io.xdc` |
| Synchro_OUT+ |           | U7         |                        |
| Synchro_IN+  |           | T9         |                        |
| Synchro_OUT- |           | V7         |                        |
| Synchro_IN-  |           | U10        |                        |
| OUT_0        | GPIO      | V8, EMIO2  | `system.tcl`, `io.xdc` |
| OUT_1        | GPIO      | T5, EMIO3  | `system.tcl`, `io.xdc` |
| OUT_2        | GPIO      | W8, EMIO4  | `system.tcl`, `io.xdc` |
| PWR_ENABLE   |           |            | Matériel               |
| RESET        |           |            | Matériel               |
| VBATT        |           |            | Matériel               |
| FPGA_DONE    |           |            | Matériel               |
| ADA_CNV      |           | U19        | `system.tcl`, `io.xdc` |
| ADB_CNV      |           | U15        | `system.tcl`, `io.xdc` |
| ADB_CH0_P    |           | N18        | `system.tcl`, `io.xdc` |
| ADB_CH0_N    |           | P19        | `system.tcl`, `io.xdc` |
| ADB_CH1_P    |           | T20        | `system.tcl`, `io.xdc` |
| ADB_CH1_N    |           | U20        | `system.tcl`, `io.xdc` |
| ADB_CH2_P    |           | R16        | `system.tcl`, `io.xdc` |
| ADB_CH2_N    |           | R17        | `system.tcl`, `io.xdc` |
| ADB_CH3_P    |           | V17        | `system.tcl`, `io.xdc` |
| ADB_CH3_N    |           | V18        | `system.tcl`, `io.xdc` |
| ADA_CH0_P    |           | P16        | `system.tcl`, `io.xdc` |
| ADA_CH0_N    |           | P15        | `system.tcl`, `io.xdc` |
| ADA_CH1_P    |           | W19        | `system.tcl`, `io.xdc` |
| ADA_CH1_N    |           | W18        | `system.tcl`, `io.xdc` |
| ADA_CH2_P    |           | W16        | `system.tcl`, `io.xdc` |
| ADA_CH2_N    |           | V16        | `system.tcl`, `io.xdc` |
| ADA_CH3_P    |           | W20        | `system.tcl`, `io.xdc` |
| ADA_CH3_N    |           | V20        | `system.tcl`, `io.xdc` |
| ADA_CLK_IN_P |           | R18        | `system.tcl`, `io.xdc` |
| ADA_CLK_IN_N |           | T17        | `system.tcl`, `io.xdc` |
| ADB_CLK_IN_P |           | Y18        | `system.tcl`, `io.xdc` |
| ADB_CLK_IN_N |           | Y19        | `system.tcl`, `io.xdc` |
| ADA_CLK_P    |           | P20        | `system.tcl`, `io.xdc` |
| ADA_CLK_N    |           | N20        | `system.tcl`, `io.xdc` |
| ADB_CLK_P    |           | N17        | `system.tcl`, `io.xdc` |
| ADB_CLK_N    |           | P18        | `system.tcl`, `io.xdc` |
