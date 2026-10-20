
use work.LTC2325_pkg.all;

package Loki_cfg is

    constant CLK_FREQUENCY                : positive := 50_000_000;
    constant ADC_CLK_FREQUENCY            : positive := 25_000_000;

    constant GPIO_WIDTH                   : positive := 32;

    -- Configuration du modulateur.
    constant MOD_DAC_DATA_WIDTH           : positive := 14;
    constant MOD_CYCLES_PER_SAMPLE_MAX    : positive := 50_000; -- 1 kHz
    constant MOD_GAIN_INTEGER_WIDTH       : natural  := 7;
    constant MOD_GAIN_FRACTIONAL_WIDTH    : natural  := 11;
    constant MOD_PHASE_AMPLITUDE_MAX      : real     := 1.5925;
    constant MOD_PHASE_FRACTIONAL_WIDTH   : natural  := 7;
    constant MOD_PHASE_INTEGER_WIDTH      : natural  := MOD_DAC_DATA_WIDTH - MOD_PHASE_FRACTIONAL_WIDTH;
    constant MOD_OFFSET_BINARY            : boolean  := true;
    constant MOD_DC_VALUE_MAX             : real     := 125.0;
    constant MOD_PGA_GAIN_WIDTH           : positive := 3;

    -- Configuration du démodulateur.
    constant DEMOD_ADC_DATA_WIDTH         : positive := LTC2325_DATA_WIDTH;
    constant DEMOD_ADC_INVERT_DIFF        : boolean  := false; -- TODO mettre à true dans la version finale
    constant DEMOD_CYCLES_PER_SAMPLE_MAX  : positive := 50_000; -- 1 kHz
    constant DEMOD_XY_INTEGER_WIDTH       : natural  := 2;
    constant DEMOD_XY_FRACTIONAL_WIDTH    : natural  := 18;
    constant DEMOD_MIXERLESS              : boolean  := false;
    constant DEMOD_CHANNELS               : natural  := 4; -- >= 2 ** DEMOD_CHANNEL_OUTPUT_WIDTH
    constant DEMOD_CHANNEL_OUTPUT_WIDTH   : positive := 2;
    constant DEMOD_POWER_FRACTIONAL_WIDTH : natural  := 14;
    constant DEMOD_POWER_INTEGER_WIDTH    : natural  := DEMOD_ADC_DATA_WIDTH - DEMOD_POWER_FRACTIONAL_WIDTH;
    constant DEMOD_OFFSET_BINARY          : boolean  := false;
    constant DEMOD_PGA_GAIN_WIDTH         : positive := 8;
    constant DEMOD_PGA_SCLK_FREQUENCY     : positive := 10_000_000;

    constant CLKMON_SECONDS_MAX           : positive := 31_536_000;
    constant CLKMON_DELTA_MAX             : positive := CLK_FREQUENCY;

    -- Configuration des transferts DMA.
    -- Le nombre d'échantillons max par voie dans un buffer DMA dépend :
    -- * de la taille du registre du DMA indiquant le nombre d'octets par transfert.
    -- * de la taille d'un échantillon mis en forme sur le bus AXI stream.
    --
    -- Le paramètre SG_LENGTH_WIDTH du DMA doit respecter la contrainte suivante :
    --
    -- DEMOD_PACKET_LENGTH_MAX * BYTES_PER_SAMPLE < 2 ** SG_LENGTH_WIDTH
    --
    -- En pratique, cette valeur sera encore ajustée logiciellement pour
    -- que la taille d'un transfert corresponde à un nombre entier de pages mémoire.
    constant SG_LENGTH_WIDTH         : positive := 16; -- Voir instanciation du DMA dans system.tcl
    constant BYTES_PER_SAMPLE        : positive := 8; -- Voir taille des données AXI stream en entrée du DMA
    constant DEMOD_PACKET_LENGTH_MAX : positive := (2 ** SG_LENGTH_WIDTH - 1) / BYTES_PER_SAMPLE;

end Loki_cfg;
