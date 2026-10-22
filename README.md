# STM32WBA55_GPDMA: BNDT decremented by 1 per data beat

Reproduction for a Renode issue, based on
[renode-issue-reproduction-template](https://github.com/renode/renode-issue-reproduction-template).

`GPDMA_CxBR1.BNDT` is the number of **bytes** of the source block. `STM32WBA55_GPDMA`
(`src/Emulator/Peripherals/Peripherals/DMA/STM32WBA_GPDMA.cs`) copies one data beat of
`max(SDW, DDW)` bytes per iteration but decrements `BNDT` by 1, so a block with 16-bit or
32-bit data is copied 2 or 4 times over and the memory after the destination is overwritten.

`test.robot` programs channel 0 for a memory-to-memory transfer of 8 bytes with 32-bit data
and checks that the word after the block is not written. No software is needed.

- branch `main`: the test fails on Renode 1.17.0 and master;
- branch `fix`: the same test with a fixed copy of the model, `STM32WBA55_GPDMA_Fixed.cs`,
  passes.

Files: `test.resc` (STM32WBA52 platform with the GPDMA added), `test.robot`, CI in
`.github/workflows/test.yml`.
