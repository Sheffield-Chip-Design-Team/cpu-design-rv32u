# Design record: RV32u

Your answers to the specification's design decisions, D1 to D8 (the "Design decision"
boxes in the [specification](docs/spec/01-overview.md)). Replace every _italic prompt_
with your answer; `make design-check` fails while any is left. Keep each answer short
and concrete: name the files, signals, addresses and pins.

Name(s): _your name(s)_

## D1 Memory implementation

- **Option:** _one 512x32 macro, two 512x16 macros, or flip-flops with N words (the `RAM_WORDS` parameter)_
- **Wrappers and macro paths:** _your wrapper files, and each macro's instance path in config.json (or none, for flip-flops)_
- **Why:** _the trade-off you made: area, tiles, risk, program size_
- **Area and tiles:** _the estimate or the GDS action's result, and info.yaml `tiles`_
- **Largest program it runs:** _words of code + data + stack that fit_

## D2 Program loader

- **Interface and pins:** _e.g. SPI slave on ui[0..3]: which pin does what_
- **Protocol:** _frame format, bit order, how an address and a word are sent_
- **Reset and hand-off:** _how the core is held in reset while loading, and released_
- **How it is tested:** _test name(s) and what they check_

## D3 I/O registers and memory map

- **Registers:** _a table: address, name, read/write, bits, function_
- **Other I/O addresses:** _what reads and writes elsewhere in the I/O region do_
- **How it is tested:** _test name(s)_

## D4 Halt and done signalling

- **How software signals done:** _e.g. writes a code to a register_
- **How you see it on the board:** _pins, LEDs, what a human or the RP2040 checks_
- **How a trap is visible:** _pin or register_

## D5 Pinout

- **ui[7:0]:** _function of each used pin (also in info.yaml `pinout`)_
- **uo[7:0]:** _function of each used pin_
- **uio[7:0]:** _function and direction of each used pin_

## D6 FSM states and encoding

- **States:** _every state, what it does, and its next states (a table or a diagram, or a link to one in this repo)_
- **Sequence per instruction:** _the states each instruction class passes through_
- **Cycles per instruction:** _with the provided memory, from the `make isa` log: LUI, branches, ALU/ADDI/AUIPC, JAL, JALR, LW, SW_
- **Encoding:** _binary, one-hot, Gray ...: the value of each state_
- **Why:** _CPI versus path length, area, simplicity, safety_

## D7 Module structure and control

- **Modules:** _each module inside rv32u_cpu_ss, what it does, and its file (a block diagram helps)_
- **Interfaces:** _the signals or structs between them_
- **Control signals:** _if you split control from the datapath: every control signal, and a table of its value per state (or a link to one); otherwise how your design decides each step_

## D8 Arithmetic resources

- **ALUs and adders:** _each one, and what it computes_
- **Operand sources:** _for each: its inputs, and when each is selected_
- **Why this arrangement:** _what it shares, what it costs_
