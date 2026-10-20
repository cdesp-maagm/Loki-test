
#include <linux/device.h>

#include "../loki-device/loki-device-sysfs.h"
#include "loki-modem-regs.h"

LokiDevice_sysfs_reg_show(clk_frequency, LOKI_MODEM_REG_CLK_FREQUENCY)
static DEVICE_ATTR_RO(clk_frequency);

LokiDevice_sysfs_reg_show(mod_sample_frequency_ref, LOKI_MODEM_REG_MOD_SAMPLE_FREQUENCY_REF)
static DEVICE_ATTR_RO(mod_sample_frequency_ref);

LokiDevice_sysfs_reg_show(mod_cycles_per_sample_max, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE_MAX)
static DEVICE_ATTR_RO(mod_cycles_per_sample_max);

LokiDevice_sysfs_reg_show(mod_osc1_wave_frequency_min, LOKI_MODEM_REG_MOD_OSC1_WAVE_FREQUENCY_MIN)
static DEVICE_ATTR_RO(mod_osc1_wave_frequency_min);

LokiDevice_sysfs_reg_show(mod_osc2_wave_frequency_min, LOKI_MODEM_REG_MOD_OSC2_WAVE_FREQUENCY_MIN)
static DEVICE_ATTR_RO(mod_osc2_wave_frequency_min);

LokiDevice_sysfs_reg_show(mod_gain_integer_width, LOKI_MODEM_REG_MOD_GAIN_INTEGER_WIDTH)
static DEVICE_ATTR_RO(mod_gain_integer_width);

LokiDevice_sysfs_reg_show(mod_gain_fractional_width, LOKI_MODEM_REG_MOD_GAIN_FRACTIONAL_WIDTH)
static DEVICE_ATTR_RO(mod_gain_fractional_width);

LokiDevice_sysfs_reg_show(mod_phase_amplitude_max, LOKI_MODEM_REG_MOD_PHASE_AMPLITUDE_MAX)
static DEVICE_ATTR_RO(mod_phase_amplitude_max);

LokiDevice_sysfs_reg_show(mod_phase_integer_width, LOKI_MODEM_REG_MOD_PHASE_INTEGER_WIDTH)
static DEVICE_ATTR_RO(mod_phase_integer_width);

LokiDevice_sysfs_reg_show(mod_phase_fractional_width, LOKI_MODEM_REG_MOD_PHASE_FRACTIONAL_WIDTH)
static DEVICE_ATTR_RO(mod_phase_fractional_width);

LokiDevice_sysfs_reg_show(demod_channels, LOKI_MODEM_REG_DEMOD_CHANNELS)
static DEVICE_ATTR_RO(demod_channels);

LokiDevice_sysfs_reg_show(demod_channel_output_width, LOKI_MODEM_REG_DEMOD_CHANNEL_OUTPUT_WIDTH)
static DEVICE_ATTR_RO(demod_channel_output_width);

LokiDevice_sysfs_reg_show(demod_power_integer_width, LOKI_MODEM_REG_DEMOD_POWER_INTEGER_WIDTH)
static DEVICE_ATTR_RO(demod_power_integer_width);

LokiDevice_sysfs_reg_show(demod_power_fractional_width, LOKI_MODEM_REG_DEMOD_POWER_FRACTIONAL_WIDTH)
static DEVICE_ATTR_RO(demod_power_fractional_width);

LokiDevice_sysfs_reg_show(demod_sample_frequency_ref, LOKI_MODEM_REG_DEMOD_SAMPLE_FREQUENCY_REF)
static DEVICE_ATTR_RO(demod_sample_frequency_ref);

LokiDevice_sysfs_reg_show(demod_cycles_per_sample_max, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE_MAX)
static DEVICE_ATTR_RO(demod_cycles_per_sample_max);

LokiDevice_sysfs_reg_show(demod_osc_wave_frequency_min, LOKI_MODEM_REG_DEMOD_OSC_WAVE_FREQUENCY_MIN)
static DEVICE_ATTR_RO(demod_osc_wave_frequency_min);

LokiDevice_sysfs_reg_show(demod_fir1_decimation, LOKI_MODEM_REG_DEMOD_FIR1_DECIMATION)
static DEVICE_ATTR_RO(demod_fir1_decimation);

LokiDevice_sysfs_reg_show(demod_fir1_length, LOKI_MODEM_REG_DEMOD_FIR1_LENGTH)
static DEVICE_ATTR_RO(demod_fir1_length);

LokiDevice_sysfs_reg_show(demod_fir1_bandwidth, LOKI_MODEM_REG_DEMOD_FIR1_BANDWIDTH)
static DEVICE_ATTR_RO(demod_fir1_bandwidth);

LokiDevice_sysfs_reg_show(demod_fir2_decimation, LOKI_MODEM_REG_DEMOD_FIR2_DECIMATION)
static DEVICE_ATTR_RO(demod_fir2_decimation);

LokiDevice_sysfs_reg_show(demod_fir2_length, LOKI_MODEM_REG_DEMOD_FIR2_LENGTH)
static DEVICE_ATTR_RO(demod_fir2_length);

LokiDevice_sysfs_reg_show(demod_fir2_bandwidth, LOKI_MODEM_REG_DEMOD_FIR2_BANDWIDTH)
static DEVICE_ATTR_RO(demod_fir2_bandwidth);

LokiDevice_sysfs_reg_show(demod_xy_integer_width, LOKI_MODEM_REG_DEMOD_XY_INTEGER_WIDTH)
static DEVICE_ATTR_RO(demod_xy_integer_width);

LokiDevice_sysfs_reg_show(demod_xy_fractional_width, LOKI_MODEM_REG_DEMOD_XY_FRACTIONAL_WIDTH)
static DEVICE_ATTR_RO(demod_xy_fractional_width);

LokiDevice_sysfs_reg_show(demod_packet_length_max, LOKI_MODEM_REG_DEMOD_PACKET_LENGTH_MAX)
static DEVICE_ATTR_RO(demod_packet_length_max);

LokiDevice_sysfs_reg_show(dac_sample_count, LOKI_MODEM_REG_DAC_SAMPLE_COUNT)
static DEVICE_ATTR_RO(dac_sample_count);

LokiDevice_sysfs_reg_show(adc_sample_count, LOKI_MODEM_REG_ADC_SAMPLE_COUNT)
static DEVICE_ATTR_RO(adc_sample_count);

LokiDevice_sysfs_reg_show(demod_sample_count, LOKI_MODEM_REG_DEMOD_SAMPLE_COUNT)
static DEVICE_ATTR_RO(demod_sample_count);

LokiDevice_sysfs_reg_store_field(restart, LOKI_MODEM_REG_CONTROL, LOKI_MODEM_REG_CONTROL_RESTART_SHIFT, LOKI_MODEM_REG_CONTROL_RESTART_MASK)
static DEVICE_ATTR_WO(restart);

LokiDevice_sysfs_reg_store_field(demod_bypass, LOKI_MODEM_REG_CONTROL, LOKI_MODEM_REG_CONTROL_BYPASS_SHIFT, LOKI_MODEM_REG_CONTROL_BYPASS_MASK)
LokiDevice_sysfs_reg_show_field(demod_bypass, LOKI_MODEM_REG_CONTROL, LOKI_MODEM_REG_CONTROL_BYPASS_SHIFT, LOKI_MODEM_REG_CONTROL_BYPASS_MASK)
static DEVICE_ATTR_RW(demod_bypass);

LokiDevice_sysfs_reg_show_field(demod_mixerless, LOKI_MODEM_REG_CONTROL, LOKI_MODEM_REG_CONTROL_MIXERLESS_SHIFT, LOKI_MODEM_REG_CONTROL_MIXERLESS_MASK)
static DEVICE_ATTR_RO(demod_mixerless);

LokiDevice_sysfs_reg_store_field(test_mode, LOKI_MODEM_REG_CONTROL, LOKI_MODEM_REG_CONTROL_TEST_MODE_SHIFT, LOKI_MODEM_REG_CONTROL_TEST_MODE_MASK)
LokiDevice_sysfs_reg_show_field(test_mode, LOKI_MODEM_REG_CONTROL, LOKI_MODEM_REG_CONTROL_TEST_MODE_SHIFT, LOKI_MODEM_REG_CONTROL_TEST_MODE_MASK)
static DEVICE_ATTR_RW(test_mode);

LokiDevice_sysfs_reg_show(mod_cycles_per_sample, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE)
LokiDevice_sysfs_reg_store(mod_cycles_per_sample, LOKI_MODEM_REG_MOD_CYCLES_PER_SAMPLE)
static DEVICE_ATTR_RW(mod_cycles_per_sample);

LokiDevice_sysfs_reg_show(mod_osc1_step, LOKI_MODEM_REG_MOD_OSC1_STEP)
LokiDevice_sysfs_reg_store(mod_osc1_step, LOKI_MODEM_REG_MOD_OSC1_STEP)
static DEVICE_ATTR_RW(mod_osc1_step);

LokiDevice_sysfs_reg_show(mod_osc1_gain, LOKI_MODEM_REG_MOD_OSC1_GAIN)
LokiDevice_sysfs_reg_store(mod_osc1_gain, LOKI_MODEM_REG_MOD_OSC1_GAIN)
static DEVICE_ATTR_RW(mod_osc1_gain);

LokiDevice_sysfs_reg_show(mod_osc2_step, LOKI_MODEM_REG_MOD_OSC2_STEP)
LokiDevice_sysfs_reg_store(mod_osc2_step, LOKI_MODEM_REG_MOD_OSC2_STEP)
static DEVICE_ATTR_RW(mod_osc2_step);

LokiDevice_sysfs_reg_show(mod_osc2_gain, LOKI_MODEM_REG_MOD_OSC2_GAIN)
LokiDevice_sysfs_reg_store(mod_osc2_gain, LOKI_MODEM_REG_MOD_OSC2_GAIN)
static DEVICE_ATTR_RW(mod_osc2_gain);

LokiDevice_sysfs_reg_show(mod_offset, LOKI_MODEM_REG_MOD_OFFSET)
LokiDevice_sysfs_reg_store(mod_offset, LOKI_MODEM_REG_MOD_OFFSET)
static DEVICE_ATTR_RW(mod_offset);

LokiDevice_sysfs_reg_show(mod_dc_value_max, LOKI_MODEM_REG_MOD_DC_VALUE_MAX)
static DEVICE_ATTR_RO(mod_dc_value_max);

LokiDevice_sysfs_reg_show(mod_dc_value_width, LOKI_MODEM_REG_MOD_DC_VALUE_WIDTH)
static DEVICE_ATTR_RO(mod_dc_value_width);

LokiDevice_sysfs_reg_show(mod_dc_value, LOKI_MODEM_REG_MOD_DC_VALUE)
LokiDevice_sysfs_reg_store(mod_dc_value, LOKI_MODEM_REG_MOD_DC_VALUE)
static DEVICE_ATTR_RW(mod_dc_value);

LokiDevice_sysfs_reg_show(mod_pga_gain_width, LOKI_MODEM_REG_MOD_PGA_GAIN_WIDTH)
static DEVICE_ATTR_RO(mod_pga_gain_width);

LokiDevice_sysfs_reg_show(mod_pga_gain, LOKI_MODEM_REG_MOD_PGA_GAIN)
LokiDevice_sysfs_reg_store(mod_pga_gain, LOKI_MODEM_REG_MOD_PGA_GAIN)
static DEVICE_ATTR_RW(mod_pga_gain);

LokiDevice_sysfs_reg_show(demod_cycles_per_sample, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE)
LokiDevice_sysfs_reg_store(demod_cycles_per_sample, LOKI_MODEM_REG_DEMOD_CYCLES_PER_SAMPLE)
static DEVICE_ATTR_RW(demod_cycles_per_sample);

LokiDevice_sysfs_reg_show(demod_osc_step, LOKI_MODEM_REG_DEMOD_OSC_STEP)
LokiDevice_sysfs_reg_store(demod_osc_step, LOKI_MODEM_REG_DEMOD_OSC_STEP)
static DEVICE_ATTR_RW(demod_osc_step);

LokiDevice_sysfs_reg_show(demod_packet_length, LOKI_MODEM_REG_DEMOD_PACKET_LENGTH)
LokiDevice_sysfs_reg_store(demod_packet_length, LOKI_MODEM_REG_DEMOD_PACKET_LENGTH)
static DEVICE_ATTR_RW(demod_packet_length);

LokiDevice_sysfs_reg_show(clkmon_seconds, LOKI_MODEM_REG_CLKMON_SECONDS)
LokiDevice_sysfs_reg_store(clkmon_seconds, LOKI_MODEM_REG_CLKMON_SECONDS)
static DEVICE_ATTR_RW(clkmon_seconds);

LokiDevice_sysfs_reg_show(clkmon_delta, LOKI_MODEM_REG_CLKMON_DELTA)
LokiDevice_sysfs_reg_store(clkmon_delta, LOKI_MODEM_REG_CLKMON_DELTA)
static DEVICE_ATTR_RW(clkmon_delta);

LokiDevice_sysfs_reg_show(gpio, LOKI_MODEM_REG_GPIO)
LokiDevice_sysfs_reg_store(gpio, LOKI_MODEM_REG_GPIO)
static DEVICE_ATTR_RW(gpio);

static ssize_t channel_cfg_show(struct device *dev, struct device_attribute *attr, char *buf) {
    LokiDevice *self = dev_get_drvdata(dev);
    int channels = LokiDevice_get_reg(self, LOKI_MODEM_REG_DEMOD_CHANNELS);
    int count = 0;
    for (int i = 0; i < LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT * channels; i ++) {
        count += scnprintf(buf + count, PAGE_SIZE - count, "0x%08x ", LokiDevice_get_reg(self, LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + i));
    }
    // Remplacer le dernier espace par un saut de ligne.
    buf[count - 1] = '\n';
    return count;
}

static ssize_t channel_cfg_store(struct device *dev, struct device_attribute *attr, const char *buf, size_t count) {
    LokiDevice *self = dev_get_drvdata(dev);
    int channels = LokiDevice_get_reg(self, LOKI_MODEM_REG_DEMOD_CHANNELS);
    char str[count];
    const char *src = buf;
    for (int i = 0; i < LOKI_MODEM_REG_DEMOD_CHANNEL_CFG_COUNT * channels && *src; i ++) {
        // Copier le buffer de l'emplacement courant jusqu'au prochain espace
        // ou jusqu'à la fin.
        char *dest = str;
        while (*src && *src != ' ') {
            *dest ++ = *src ++;
        }
        *dest = 0;

        int arg;
        if (kstrtoint(str, 0, &arg)) {
            dev_err(self->dev, "Valeur incorrecte pour la voie %d.\n", i);
        }
        else {
            LokiDevice_set_reg(self, LOKI_MODEM_REG_DEMOD_CHANNEL_CFG + i, arg);
        }

        // Avancer jusqu'à la prochaine valeur dans le buffer.
        while (*src && *src == ' ') {
            src ++;
        }
    }

    if (*src) {
        dev_warn(self->dev, "Valeurs en surnombre.\n");
    }

    return count;
}

static DEVICE_ATTR_RW(channel_cfg);

int LokiModem_sysfs_create(LokiDevice *self) {
    LokiDevice_sysfs_create(self);

    LokiDevice_sysfs_create_file(clk_frequency);
    LokiDevice_sysfs_create_file(mod_sample_frequency_ref);
    LokiDevice_sysfs_create_file(mod_cycles_per_sample_max);
    LokiDevice_sysfs_create_file(mod_osc1_wave_frequency_min);
    LokiDevice_sysfs_create_file(mod_osc2_wave_frequency_min);
    LokiDevice_sysfs_create_file(mod_gain_integer_width);
    LokiDevice_sysfs_create_file(mod_gain_fractional_width);
    LokiDevice_sysfs_create_file(mod_phase_amplitude_max);
    LokiDevice_sysfs_create_file(mod_phase_integer_width);
    LokiDevice_sysfs_create_file(mod_phase_fractional_width);
    LokiDevice_sysfs_create_file(demod_channels);
    LokiDevice_sysfs_create_file(demod_channel_output_width);
    LokiDevice_sysfs_create_file(demod_power_integer_width);
    LokiDevice_sysfs_create_file(demod_power_fractional_width);
    LokiDevice_sysfs_create_file(demod_sample_frequency_ref);
    LokiDevice_sysfs_create_file(demod_cycles_per_sample_max);
    LokiDevice_sysfs_create_file(demod_fir1_decimation);
    LokiDevice_sysfs_create_file(demod_fir1_length);
    LokiDevice_sysfs_create_file(demod_fir1_bandwidth);
    LokiDevice_sysfs_create_file(demod_fir2_decimation);
    LokiDevice_sysfs_create_file(demod_fir2_length);
    LokiDevice_sysfs_create_file(demod_fir2_bandwidth);
    LokiDevice_sysfs_create_file(demod_xy_integer_width);
    LokiDevice_sysfs_create_file(demod_xy_fractional_width);
    LokiDevice_sysfs_create_file(demod_packet_length_max);
    LokiDevice_sysfs_create_file(dac_sample_count);
    LokiDevice_sysfs_create_file(adc_sample_count);
    LokiDevice_sysfs_create_file(demod_sample_count);
    LokiDevice_sysfs_create_file(restart);
    LokiDevice_sysfs_create_file(test_mode);
    LokiDevice_sysfs_create_file(mod_cycles_per_sample);
    LokiDevice_sysfs_create_file(mod_osc1_step);
    LokiDevice_sysfs_create_file(mod_osc1_gain);
    LokiDevice_sysfs_create_file(mod_osc2_step);
    LokiDevice_sysfs_create_file(mod_osc2_gain);
    LokiDevice_sysfs_create_file(mod_offset);
    LokiDevice_sysfs_create_file(mod_dc_value_max);
    LokiDevice_sysfs_create_file(mod_dc_value_width);
    LokiDevice_sysfs_create_file(mod_dc_value);
    LokiDevice_sysfs_create_file(mod_pga_gain_width);
    LokiDevice_sysfs_create_file(mod_pga_gain);
    LokiDevice_sysfs_create_file(demod_bypass);
    LokiDevice_sysfs_create_file(demod_mixerless);
    LokiDevice_sysfs_create_file(demod_cycles_per_sample);
    LokiDevice_sysfs_create_file(demod_packet_length);
    LokiDevice_sysfs_create_file(clkmon_seconds);
    LokiDevice_sysfs_create_file(clkmon_delta);
    LokiDevice_sysfs_create_file(channel_cfg);
    LokiDevice_sysfs_create_file(gpio);

    if (!(LokiDevice_get_reg(self, LOKI_MODEM_REG_CONTROL) & LOKI_MODEM_REG_CONTROL_MIXERLESS_SHIFTED_MASK)) {
        LokiDevice_sysfs_create_file(demod_osc_step);
        LokiDevice_sysfs_create_file(demod_osc_wave_frequency_min);
    }

    return 0;
}

void LokiModem_sysfs_remove(LokiDevice *self) {
    LokiDevice_sysfs_remove(self);

    LokiDevice_sysfs_remove_file(clk_frequency);
    LokiDevice_sysfs_remove_file(mod_sample_frequency_ref);
    LokiDevice_sysfs_remove_file(mod_cycles_per_sample_max);
    LokiDevice_sysfs_remove_file(mod_osc1_wave_frequency_min);
    LokiDevice_sysfs_remove_file(mod_osc2_wave_frequency_min);
    LokiDevice_sysfs_remove_file(mod_gain_integer_width);
    LokiDevice_sysfs_remove_file(mod_gain_fractional_width);
    LokiDevice_sysfs_remove_file(mod_phase_amplitude_max);
    LokiDevice_sysfs_remove_file(mod_phase_integer_width);
    LokiDevice_sysfs_remove_file(mod_phase_fractional_width);
    LokiDevice_sysfs_remove_file(demod_channels);
    LokiDevice_sysfs_remove_file(demod_channel_output_width);
    LokiDevice_sysfs_remove_file(demod_power_integer_width);
    LokiDevice_sysfs_remove_file(demod_power_fractional_width);
    LokiDevice_sysfs_remove_file(demod_sample_frequency_ref);
    LokiDevice_sysfs_remove_file(demod_cycles_per_sample_max);
    LokiDevice_sysfs_remove_file(demod_fir1_decimation);
    LokiDevice_sysfs_remove_file(demod_fir1_length);
    LokiDevice_sysfs_remove_file(demod_fir1_bandwidth);
    LokiDevice_sysfs_remove_file(demod_fir2_decimation);
    LokiDevice_sysfs_remove_file(demod_fir2_length);
    LokiDevice_sysfs_remove_file(demod_fir2_bandwidth);
    LokiDevice_sysfs_remove_file(demod_xy_integer_width);
    LokiDevice_sysfs_remove_file(demod_xy_fractional_width);
    LokiDevice_sysfs_remove_file(demod_packet_length_max);
    LokiDevice_sysfs_remove_file(dac_sample_count);
    LokiDevice_sysfs_remove_file(adc_sample_count);
    LokiDevice_sysfs_remove_file(demod_sample_count);
    LokiDevice_sysfs_remove_file(restart);
    LokiDevice_sysfs_remove_file(test_mode);
    LokiDevice_sysfs_remove_file(mod_cycles_per_sample);
    LokiDevice_sysfs_remove_file(mod_osc1_step);
    LokiDevice_sysfs_remove_file(mod_osc1_gain);
    LokiDevice_sysfs_remove_file(mod_osc2_step);
    LokiDevice_sysfs_remove_file(mod_osc2_gain);
    LokiDevice_sysfs_remove_file(mod_offset);
    LokiDevice_sysfs_remove_file(mod_dc_value_max);
    LokiDevice_sysfs_remove_file(mod_dc_value_width);
    LokiDevice_sysfs_remove_file(mod_dc_value);
    LokiDevice_sysfs_remove_file(mod_pga_gain_width);
    LokiDevice_sysfs_remove_file(mod_pga_gain);
    LokiDevice_sysfs_remove_file(demod_bypass);
    LokiDevice_sysfs_remove_file(demod_mixerless);
    LokiDevice_sysfs_remove_file(demod_cycles_per_sample);
    LokiDevice_sysfs_remove_file(demod_packet_length);
    LokiDevice_sysfs_remove_file(clkmon_seconds);
    LokiDevice_sysfs_remove_file(clkmon_delta);
    LokiDevice_sysfs_remove_file(channel_cfg);
    LokiDevice_sysfs_remove_file(gpio);

    if (!(LokiDevice_get_reg(self, LOKI_MODEM_REG_CONTROL) & LOKI_MODEM_REG_CONTROL_MIXERLESS_SHIFTED_MASK)) {
        LokiDevice_sysfs_remove_file(demod_osc_step);
        LokiDevice_sysfs_remove_file(demod_osc_wave_frequency_min);
    }
}
