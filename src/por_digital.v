// -----------------------------------------------------------------------------
// Digital power-up / power-on reset (POR) generator
//
//  * DELAY_LFSR counts from a random power-up state to DELAY_CODE
//    → defines the "settle-time" after VDD is valid.
//  * PULSE_LFSR then runs for PULSE_CYCLES clock edges
//    → defines the *width* of the active-low reset pulse.
//  * A "lock-up" state (all-ones) in the delay LFSR is automatically broken.
//
//  Based on US 6278302 B1, Fig. 1 and accompanying text.
// -----------------------------------------------------------------------------

`default_nettype none

module por_digital #(
    // ------------ design-time knobs -----------------------------------------
    // Length of the first (delay) LFSR and compare value that stops it.
    parameter int DELAY_BITS = 28,
    parameter logic [DELAY_BITS-1:0] DELAY_CODE = 28'hC0_00000,  // 0xC000000

    // Length of the second (pulse-width) LFSR and compare value that stops it.
    parameter int                    PULSE_BITS  = 6,
    parameter logic [PULSE_BITS-1:0] PULSE_CODE  = 6'h20,  // 0x20
    // ------------------------------------------------------------------------
    // Choose taps that give a maximal-length polynomial for your technology.
    // For the defaults:
    //   * 28-bit XNOR taps 27,24 (degree-28 primitive: x^28 + x^25 + 1)
    //   * 6-bit  XNOR taps 5,4  (degree-6  primitive:  x^6  + x^5  + 1)
    // ------------------------------------------------------------------------
    parameter int                    DELAY_TAP_H = 27,
    parameter int                    DELAY_TAP_L = 24,
    parameter int                    PULSE_TAP_H = 5,
    parameter int                    PULSE_TAP_L = 4
) (
    input  wire clk,     // free-running system clock
    output wire reset_n  // active-low POR to the rest of the chip
);
  // ------------------------------------------------------------------------
  // First stage - long delay before reset pulse is allowed to start
  // ------------------------------------------------------------------------
  logic [DELAY_BITS-1:0] delay_lfsr;

  // XNOR feedback bit, masked to break the "all-ones" lock-up state
  wire                   delay_feedback_raw = ~(delay_lfsr[DELAY_TAP_H] ^ delay_lfsr[DELAY_TAP_L]);
  wire                   delay_lock_up = &delay_lfsr;  // all 1's?
  wire                   delay_feedback = delay_feedback_raw & ~delay_lock_up;

  // Keep shifting until we *match* DELAY_CODE, then freeze
  wire                   delay_hit = (delay_lfsr == DELAY_CODE);
  wire                   delay_en = ~delay_hit;  // 1 while counting

  always_ff @(posedge clk) begin
    if (delay_en) delay_lfsr <= {delay_lfsr[DELAY_BITS-2:0], delay_feedback};
  end

  // ------------------------------------------------------------------------
  // Second stage - defines reset-pulse width
  // ------------------------------------------------------------------------
  logic [PULSE_BITS-1:0] pulse_lfsr;

  wire pulse_feedback = ~(pulse_lfsr[PULSE_TAP_H] ^ pulse_lfsr[PULSE_TAP_L]);

  wire pulse_hit = (pulse_lfsr == PULSE_CODE);
  wire pulse_en = delay_hit & ~pulse_hit;  // enable only after delay

  always_ff @(posedge clk) begin
    if (pulse_en) pulse_lfsr <= {pulse_lfsr[PULSE_BITS-2:0], pulse_feedback};
  end

  // ------------------------------------------------------------------------
  // Output flip-flop - guarantees clean, glitch-free reset_n
  //   * reset_n = 0  while pulse LFSR is active
  //   * reset_n = 1  once pulse_hit goes high
  // ------------------------------------------------------------------------
  logic reset_n_q;

  always_ff @(posedge clk) begin
    reset_n_q <= ~pulse_en;  // active-low in patent
  end

  assign reset_n = reset_n_q;

endmodule
