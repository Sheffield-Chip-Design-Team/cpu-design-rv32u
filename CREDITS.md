# Credits

**CPU Design Mini-Project - RV32u** is a SHaRC mini-project by James Ashie Kotey. It builds on:

| What | From | License |
|---|---|---|
| The site structure: Quarto configuration, course path, page conventions, `docs/_filters/course.lua`, `scripts/check_site.py`, the site and link-check workflows | [UofT ASIC course template](https://github.com/uoftasic/course-template), by Raj Prajapati and the UofT ASIC Team | MIT |
| The SRAM macro hardening flow: `librelane_plugin_sram_pdn.py`, `odb_stripes.py`, `src/pdn_cfg.tcl`, the macro placement and power configuration | [Tiny Tapeout IHP SRAM example](https://github.com/TinyTapeout/ttihp-cmos5l-sram-example) | Apache-2.0 |
| The Tiny Tapeout project layout: `info.yaml`, `test/`, the GDS and docs workflows, `.devcontainer/` | the [Tiny Tapeout IHP template](https://github.com/TinyTapeout/ttihp-verilog-template), by way of the SHaRC PIOScope TT template | Apache-2.0 |
| The SRAM macros and their behavioural models (`ip/IHP-Open-PDK`) | [IHP-Open-PDK](https://github.com/IHP-GmbH/IHP-Open-PDK), IHP GmbH | Apache-2.0 |
| The core | the RV32I-Micro multi-cycle core specification (SHaRC), a subset of the [RISC-V](https://riscv.org) RV32I ISA | |
| The retire port | modelled on the [RISC-V Formal Interface](https://github.com/YosysHQ/riscv-formal/blob/main/docs/rvfi.md) | |

The verification environment, the reference model, the software flow and the specification pages were written with the help of Claude (Anthropic).
