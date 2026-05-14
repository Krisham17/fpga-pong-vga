# Pong on FPGA with VGA — COE758 Project 2

A two-player Pong game implemented entirely in VHDL and synthesized for a Xilinx FPGA. The design generates a 640×480 VGA signal at 60 Hz, renders two paddles and a ball in real time, and reads two pairs of switches for player input. All game logic, physics, and pixel rendering are implemented as concurrent behavioral processes within a single top-level entity.

## Architecture Overview

`PongGame` is a monolithic behavioral entity — there are no game-logic sub-entities. All functionality is handled by eight VHDL processes running concurrently on a 25 MHz pixel clock derived from the board's input clock.

```
CLK (50 MHz)
    │
    ▼ clk_div (÷2)
clk25 (25 MHz) ─────────────────────────────────────────────────────┐
    │                                                               │
    ▼                                                               │
h_pos_counter ──► hPos [0..799] ──► Horizontal_Synchronisation ──► HSYNC
    │                                                               │
    ▼                                                               │
v_pos_counter ──► vPos [0..524] ──► Vertical_Synchronisation ──► VSYNC
    │
    ├── newframe ──► ball_move   (physics update once per frame)
    │           └── paddle_move (SW0–SW3 input → paddle position)
    │
    └── hPos, vPos, ball_pos, paddle_pos ──► draw ──► Rout/Gout/Bout[7:0]
```

## VGA Timing

The design targets standard 640×480 @ 60 Hz VGA. All timing is computed from constants:

| Parameter | Value | Meaning |
|-----------|-------|---------|
| HD  | 640 | Active horizontal pixels |
| HFP | 16  | Horizontal front porch |
| HSP | 96  | Horizontal sync pulse |
| HBP | 48  | Horizontal back porch |
| VD  | 480 | Active vertical lines |
| VFP | 10  | Vertical front porch |
| VSP | 2   | Vertical sync pulse |
| VBP | 33  | Vertical back porch |

Total horizontal period: 800 pixels. Total vertical period: 525 lines.

## Behavioral Processes

| Process | Triggered on | Function |
|---------|-------------|----------|
| `clk_div` | CLK rising edge | Toggles `clk25` — divides input clock by 2 |
| `h_pos_counter` | clk25 rising edge | Increments `hPos` 0→799, then resets; asserts `newframe` when vPos also reaches end |
| `v_pos_counter` | clk25 rising edge, hPos | Increments `vPos` 0→524 at the end of each horizontal line |
| `Horizontal_Synchronisation` | clk25, hPos | Drives `hsync_in` low during the 96-pixel sync pulse window |
| `Vertical_Synchronisation` | clk25, vPos | Drives `vsync_in` low during the 2-line sync pulse window |
| `video_on` | clk25, hPos, vPos | Asserts `videoOn` when hPos ≤ 640 AND vPos ≤ 480 |
| `ball_move` | clk25, newframe | Updates ball position and velocity each frame; handles wall bounce, paddle bounce, and goal detection |
| `paddle_move` | clk25, newframe | Moves each paddle ±2 pixels per frame based on SW input |
| `draw` | clk25, hPos, vPos, videoOn | Selects pixel colour based on whether current scan position is inside the ball, a paddle, a border, or the centre line |

## Game Objects

| Object | Position Signals | Colour |
|--------|-----------------|--------|
| Player 1 paddle (left) | `paddle1_pos_h1=20`, `paddle1_pos_v1` (variable) | Blue (0x00, 0x00, 0xFF) |
| Player 2 paddle (right) | `paddle2_pos_h1=610`, `paddle2_pos_v1` (variable) | Magenta (0xFF, 0x00, 0xFF) |
| Ball (8×8 pixels) | `ball_pos_h1`, `ball_pos_v1` (variable) | Yellow normally, Red when passing through goal |
| Top/bottom borders (20px) | Constants | White (0xFF, 0xFF, 0xFF) |
| Left/right borders (20px) | Constants, with 250-px gap as goal hole | White (opaque) / Green (goal gap) |
| Centre line | `strip=320`, 3px wide, dashed | Black/Green alternating |
| Background | — | Green (0x00, 0xFF, 0x00) |

## Ball Physics

- **Velocity**: `ball_speed_h` and `ball_speed_v` (integer range −3 to 3). Initial value ±2.
- **Wall bounce**: reverses the sign of the relevant velocity component when the ball hits a top/bottom border or a solid portion of the side border.
- **Paddle bounce**: reverses `ball_speed_h` when the ball's bounding box overlaps a paddle.
- **Goal**: if the ball passes through the gap in the side border (between `hole_left_v1=120` and `hole_left_v1+250=370`), it resets to screen centre (320, 240).
- **Colour change**: ball turns red (`ballcolor='1'`) when it enters the goal zone.

## Controls

| Switch | Player | Action |
|--------|--------|--------|
| SW0 | Player 1 (left paddle) | Move up |
| SW1 | Player 1 (left paddle) | Move down |
| SW2 | Player 2 (right paddle) | Move up |
| SW3 | Player 2 (right paddle) | Move down |

Paddle speed: 2 pixels per frame. Paddles are clamped to the playfield (border to border).

## Debug Components

Two Xilinx ChipScope IP cores are instantiated for on-board signal probing. They have no effect on game logic:

- **`icon`** (`sys_icon`) — ChipScope ICON controller; manages the JTAG debug bus.
- **`ila_pong`** (`sys_ila`) — Integrated Logic Analyzer; captures `hsync_in` and `vsync_in` for oscilloscope-style debugging on the FPGA.

## Key Ports

| Port | Dir | Width | Description |
|------|-----|-------|-------------|
| `CLK` | in | 1 | System clock (50 MHz on board → 25 MHz internally) |
| `SW0` | in | 1 | Player 1 paddle up |
| `SW1` | in | 1 | Player 1 paddle down |
| `SW2` | in | 1 | Player 2 paddle up |
| `SW3` | in | 1 | Player 2 paddle down |
| `HSYNC` | out | 1 | VGA horizontal sync (active-low during sync pulse) |
| `VSYNC` | out | 1 | VGA vertical sync (active-low during sync pulse) |
| `DAC_CLK` | out | 1 | Pixel clock output to DAC (= clk25, ~25 MHz) |
| `Rout` | out | 8 | Red channel pixel data |
| `Gout` | out | 8 | Green channel pixel data |
| `Bout` | out | 8 | Blue channel pixel data |

## Files

| File | Description |
|------|-------------|
| `PongGame.vhd` | Top-level entity — all game logic, VGA timing, and pixel rendering |
| `ipcore_dir/icon.vhd` | Xilinx ChipScope ICON controller (auto-generated) |
| `ipcore_dir/ila_pong.vhd` | Xilinx ChipScope ILA (auto-generated) |
| `netgen/synthesis/PongGame_synthesis.vhd` | Post-synthesis netlist (auto-generated) |

## Synthesis Results

**Target device:** xc3s500e-5-fg320 (Xilinx Spartan-3E)

| Resource | Used | Available | Utilization |
|---|---|---|---|
| Slices | 849 | 4,656 | 18% |
| Slice Flip-Flops | 402 | 9,312 | 4% |
| 4-input LUTs | 1,183 | 9,312 | 12% |
| RAMB16s | 1 | 20 | 5% |

- **Max Frequency (post-P&R):** 84.9 MHz (11.772 ns min period; worst path through ChipScope ILA)
- **Synthesis estimate:** 89.3 MHz

## How to Run

**Prerequisites:** Xilinx ISE 14.7 (or open `.vhd` files in Vivado with manual project setup)

```
1. Open the .xise project file in ISE Design Suite
2. Simulate: right-click testbench → Simulate Behavioral Model (ISim)
3. Synthesize: double-click Synthesize-XST
4. Implement: double-click Implement Design
5. Program: double-click Generate Programming File → iMPACT → program the .bit file
Pin assignments: see the .ucf constraint file in src/
```

## Design Decisions & Tradeoffs

- **Monolithic single top-level entity** with all game logic in one file — fast to write, harder to reuse or test individual subsystems independently.
- **Behavioral processes for VGA sync and game logic** — clean and readable but synthesizes to more LUTs than a structural design would; all 8 processes run concurrently on the 25 MHz pixel clock.
- **ChipScope ILA embedded** for real-time hardware debugging (accounts for worst-case timing path at 84.9 MHz post-P&R vs. 89.3 MHz synthesis estimate).
- **No clock period constraint in UCF** — timing closure was not formally verified; the design relies on XST defaults.
- **AI paddle entity declared but not fully wired** — a stub for single-player AI exists in the design but is not connected in the current build.

## Future Improvements

- Add a proper UCF clock period constraint and close timing formally against a target frequency.
- Refactor into a structural hierarchy: VGA controller, game logic, and score display as separate, independently testable modules.
- Replace ChipScope ILA with a lighter debug interface (e.g., UART readout) for production use to reclaim timing margin.
- Add sound output via a PWM buzzer on paddle hit and goal events.
- Fully implement and wire the AI paddle tracking so the game can be played single-player.

## Skills Demonstrated

`VHDL · VGA timing · real-time pixel rendering · game logic FSM · behavioral VHDL · Xilinx ISE · ChipScope ILA · Spartan-3E FPGA`

## License

MIT License — see [LICENSE](../LICENSE) for details.
