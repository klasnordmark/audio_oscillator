initial reset_n = 0;

// Assert that we're never valid in reset,
// and that valid data won't change without tready
always @(posedge clk) begin
    if (!reset_n) assert (!tvalid);
    if (tvalid && !tready && reset_n) assert ($stable(tdata));
end