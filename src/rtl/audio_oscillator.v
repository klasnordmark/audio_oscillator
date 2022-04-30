`default_nettype none `timescale 1ns / 1ns

module audio_oscillator #(
    parameter integer SAMPLE_SIZE = 16
) (
    input wire clk,
    input wire reset_n,
    input wire [31:0] divisor,
    input wire [7:0] duty,
    input wire waveform,
    output reg tvalid,
    output wire [SAMPLE_SIZE-1:0] tdata,
    input wire tready
);

  localparam StateHigh = 0;
  localparam StateLow = 1;
  localparam integer DutyStep = 2 ** 25; // (2**32)/128, 128 parts of the counter range

  reg [31:0] clk_counter;
  reg state;
  reg counter_pulse;

  wire transaction;
  wire [SAMPLE_SIZE-1:0] saw;
  reg [SAMPLE_SIZE-1:0] square;

  assign transaction = tvalid & tready;
  assign tdata       = waveform ? square : saw;
  // The saw waveform is taken directly from the counter
  assign saw         = clk_counter[31:32-SAMPLE_SIZE];

  // The square waveform is set to 1 with each wraparound of the counter,
  // and is set to 0 according to the value of input duty
  always @(posedge clk) begin
    case (state)
      StateHigh: begin
        square <= {1'b0, {SAMPLE_SIZE - 1{1'b1}}};
        if (clk_counter > duty * DutyStep) begin
          state <= StateLow;
        end
      end
      StateLow: begin
        square <= {1'b1, {SAMPLE_SIZE - 1{1'b0}}};
        if (counter_pulse) begin
          state <= StateHigh;
        end
      end
      default: begin
      end
    endcase
    if (!reset_n) begin
      square <= 0;
      state  <= StateHigh;
    end
  end

  // Counter process
  // For desired frequency F with sampling frequency f_s, set divisor to (2^32)/(f_s/F)
  // Note that the oscillator gives trivial waves which will have aliasing issues:
  // Oversample, filter and decimate accordingly.
  always @(posedge clk) begin
    tvalid <= 1;
    if (transaction) begin
      {counter_pulse, clk_counter} <= clk_counter + divisor;
    end
    if (!reset_n) begin
      tvalid        <= 0;
      clk_counter   <= 0;
      counter_pulse <= 0;
    end
  end

`ifdef FORMAL
  `include "formal.v"
`endif

endmodule

`default_nettype wire
