`default_nettype none
`timescale 1ns/1ns

module audio_oscillator #(parameter WORD_BYTES = 2)
                         (input wire clk,
                          input wire reset_n,
                          input wire [31:0] divisor,
                          input wire [7:0] duty,
                          input wire waveform,
                          output reg tvalid,
                          output wire [8*WORD_BYTES-1:0] tdata,
                          input wire tready);
    
    localparam STATE_HIGH = 0;
    localparam STATE_LOW  = 1;
    localparam DUTY_STEP  = (2**32)/128;
    
    reg [31:0] clk_counter;
    reg state;
    reg counter_pulse;
    
    wire transaction;
    wire [15:0] saw;
    reg [15:0] square;
    
    assign transaction = tvalid & tready;
    assign tdata       = waveform ? square : saw;
    // The saw waveform is taken directly from the counter
    assign saw = clk_counter[31:16];

    // The square waveform is set to 1 with each wraparound of the counter
    always @(posedge clk) begin
        case (state)
            STATE_HIGH: begin
                square <= {1'b0, {8*WORD_BYTES-1{1'b1}}};
                if (clk_counter > duty*DUTY_STEP) begin
                    state <= STATE_LOW;
                end
            end
            STATE_LOW: begin
                square <= {1'b1, {8*WORD_BYTES-1{1'b0}}};
                if (counter_pulse) begin
                    state <= STATE_HIGH;
                end
            end
        endcase
        if (!reset_n) begin
            square <= 0;
            state <= STATE_HIGH;
        end
    end
    
    // Counter process
    // For desired frequency F with sampling frequency f_s, set divisor to (2^32)/(f_s/F)
    // Note that the oscillator gives trivial waves which will have aliasing issues:
    // Oversample, filter and decimate accordingly.
    always @(posedge clk) begin
        tvalid <= 1;
        if (transaction) begin
            {counter_pulse, clk_counter}     <= clk_counter + divisor;
        end        
        if (!reset_n) begin
            tvalid          <= 0;
            clk_counter <= 0;
        end
    end

endmodule
