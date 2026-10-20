
package DelayLineTestbench_cfg is

    constant TB_CLK_PERIOD         : time     := 10 ns;
    constant TB_PERIODS_PER_SAMPLE : positive := 4;
    constant TB_LENGTH             : positive := 10;
    constant TB_DATA_HIGH          : integer  := 6;
    constant TB_DATA_LOW           : integer  := -4;

end DelayLineTestbench_cfg;
