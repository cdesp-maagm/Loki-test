
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

| Label         | Interface | Broche Zynq | Broche MicroZed | Fait                   |
|:--------------|:----------|:------------|:----------------|:-----------------------|
| INIT          |           | R10         | JX2-9           | Matériel               |
| PG_2V5        |           |             | JX2-10          | Matériel               |
| PG_CARRIER    |           | C7          | JX2-11          | Matériel               |
| PWR_ENABLE    |           |             | JX1-5           | Matériel               |
| RESET         |           |             | JX1-6           | Matériel               |
| VBATT         |           |             | JX1-7           | Matériel               |
| FPGA_DONE     |           | R11         | JX1-8           | Matériel               |
| MAC_SCL       | I2C0      | E9, MIO10   | JX2-2           | `system.tcl`           |
| MAC_SDA       | I2C0      | C6, MIO11   | JX2-3           | `system.tcl`           |
| TEMP_SCL      | I2C1      | D9, MIO12   | JX2-4           | `system.tcl`           |
| TEMP_SDA      | I2C1      | E8, MIO13   | JX2-1           | `system.tcl`           |
| GPS_RESET     | GPIO      | B5, MIO9    | JX2-6           | Preset                 |
| GPS_RX        | UART0     | C5, MIO14   | JX2-7           | `system.tcl`           |
| GPS_TX        | UART0     | C8, MIO15   | JX2-8           | `system.tcl`           |
| SW_1          | GPIO      | G14, EMIO0  | JX2-13          | `system.tcl`, `io.xdc` |
| XADC_0_P      |           | C20         | JX2-17          | `io.xdc`               |
| XADC_0_N      |           | B20         | JX2-19          | `io.xdc`               |
| XADC_1_P      |           | E17         | JX2-23          | `io.xdc`               |
| XADC_1_N      |           | D18         | JX2-25          | `io.xdc`               |
| P2 CS\        |           | V7          | JX1-89          | `io.xdc`               |
| P2 CS\_BMP390 |           | U5          | JX1-94          | `io.xdc`               |
| P2 SDO        |           | V8          | JX1-91          | `io.xdc`               |
| P2 SDI        |           | T5          | JX1-92          | `io.xdc`               |
| P2 SCK        |           | W8          | JX1-93          | `io.xdc`               |
| CLK1PPS       |           | L16         | JX2-47          | `io.xdc`               |
| CLK10M00      |           | K17         | JX2-48          | `io.xdc`               |
| CLK30M72      |           | H16         | JX2-53          | `io.xdc`               |
| TSTAMP        |           | J18         | JX2-54          | `io.xdc`               |
| DAC_IQSEL     |           | G18         | JX2-63          | `io.xdc`               |
| DAC_IQRESET   |           | F20         | JX2-64          | `io.xdc`               |
| DAC_IQWRT     |           | G19         | JX2-67          | `io.xdc`               |
| DAC_IQCLK     |           | J20         | JX2-68          | `io.xdc`               |
| DAC_DA0       |           | G20         | JX2-69          | `io.xdc`               |
| DAC_DA1       |           | H20         | JX2-70          | `io.xdc`               |
| DAC_DA2       |           | K14         | JX2-73          | `io.xdc`               |
| DAC_DA3       |           | H15         | JX2-74          | `io.xdc`               |
| DAC_DA4       |           | J14         | JX2-75          | `io.xdc`               |
| DAC_DA5       |           | G15         | JX2-76          | `io.xdc`               |
| DAC_DA6       |           | N15         | JX2-81          | `io.xdc`               |
| DAC_DA7       |           | L14         | JX2-82          | `io.xdc`               |
| DAC_DA8       |           | N16         | JX2-83          | `io.xdc`               |
| DAC_DA9       |           | L15         | JX2-84          | `io.xdc`               |
| DAC_DA10      |           | M14         | JX2-87          | `io.xdc`               |
| DAC_DA11      |           | K16         | JX2-88          | `io.xdc`               |
| DAC_DA12      |           | M15         | JX2-89          | `io.xdc`               |
| DAC_DA13      |           | J16         | JX2-90          | `io.xdc`               |
| ADA_CNV       |           | U19         | JX1-44          | `system.tcl`, `io.xdc` |
| ADA_CLK_IN_P  |           | R18         | JX1-70          | `system.tcl`, `io.xdc` |
| ADA_CLK_IN_N  |           | T17         | JX1-68          | `system.tcl`, `io.xdc` |
| ADA_CLK_P     |           | P20         | JX1-50          | `system.tcl`, `io.xdc` |
| ADA_CLK_N     |           | N20         | JX1-48          | `system.tcl`, `io.xdc` |
| ADA_CH0_P     |           | P16         | JX1-84          | `system.tcl`, `io.xdc` |
| ADA_CH0_N     |           | P15         | JX1-82          | `system.tcl`, `io.xdc` |
| ADA_CH1_P     |           | W19         | JX1-76          | `system.tcl`, `io.xdc` |
| ADA_CH1_N     |           | W18         | JX1-74          | `system.tcl`, `io.xdc` |
| ADA_CH2_P     |           | W16         | JX1-64          | `system.tcl`, `io.xdc` |
| ADA_CH2_N     |           | V16         | JX1-62          | `system.tcl`, `io.xdc` |
| ADA_CH3_P     |           | W20         | JX1-56          | `system.tcl`, `io.xdc` |
| ADA_CH3_N     |           | V20         | JX1-54          | `system.tcl`, `io.xdc` |
| ADB_CNV       |           | U15         | JX1-43          | `system.tcl`, `io.xdc` |
| ADB_CLK_IN_P  |           | Y18         | JX1-61          | `system.tcl`, `io.xdc` |
| ADB_CLK_IN_N  |           | Y19         | JX1-63          | `system.tcl`, `io.xdc` |
| ADB_CLK_P     |           | N17         | JX1-81          | `system.tcl`, `io.xdc` |
| ADB_CLK_N     |           | P18         | JX1-83          | `system.tcl`, `io.xdc` |
| ADB_CH0_P     |           | N18         | JX1-47          | `system.tcl`, `io.xdc` |
| ADB_CH0_N     |           | P19         | JX1-49          | `system.tcl`, `io.xdc` |
| ADB_CH1_P     |           | T20         | JX1-53          | `system.tcl`, `io.xdc` |
| ADB_CH1_N     |           | U20         | JX1-55          | `system.tcl`, `io.xdc` |
| ADB_CH2_P     |           | R16         | JX1-67          | `system.tcl`, `io.xdc` |
| ADB_CH2_N     |           | R17         | JX1-69          | `system.tcl`, `io.xdc` |
| ADB_CH3_P     |           | V17         | JX1-73          | `system.tcl`, `io.xdc` |
| ADB_CH3_N     |           | V18         | JX1-75          | `system.tcl`, `io.xdc` |
| DAC_G0        |           | K19         | JX2-42          | `io.xdc`               |
| DAC_G1        |           | M17         | JX2-41          | `io.xdc`               |
| DAC_G2        |           | M18         | JX2-43          | `io.xdc`               |
| CLK_PGA       |           | F19         | JX2-62          | `io.xdc`               |
| DATA_PGA      |           | G17         | JX2-61          | `io.xdc`               |
| LTCH_PGA0     |           | E18         | JX2-29          | `io.xdc`               |
| LTCH_PGA1     |           | F16         | JX2-30          | `io.xdc`               |
| LTCH_PGA2     |           | E19         | JX2-31          | `io.xdc`               |
| LTCH_PGA3     |           | F17         | JX2-32          | `io.xdc`               |
| LTCH_PGA4     |           | L19         | JX2-35          | `io.xdc`               |
| LTCH_PGA5     |           | M19         | JX2-36          | `io.xdc`               |
| LTCH_PGA6     |           | L20         | JX2-37          | `io.xdc`               |
| LTCH_PGA7     |           | M20         | JX2-38          | `io.xdc`               |
| Synchro_OUT   |           | U7          | JX1-87          | `io.xdc`               |
| Synchro_IN    |           | T9          | JX1-88          | `io.xdc`               |
