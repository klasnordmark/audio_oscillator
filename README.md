# audio_oscillator
A simple oscillator for usage in digital audio synthesizers.

core file can be found in https://github.com/klasnordmark/nordmark_cores for Fusesoc support. The main test bench is, however, written for cocotb which is for the moment not supported in Edalize. With Icarus Verilog and cocotb installed, simply running "make" in the src/tb folder should execute the testbench.

Output is done with a valid/ready handshake as in AXI stream protocols. Samples are given as two's complement signed integers with parametrized bit length. Control is done through three signals:

* divisor sets the frequency of the oscillator. For a desired frequency F and a sampling frequency fs, set divisor to (2**32)/(fs/F).
* duty sets the duty cycle of the square waveform, uniformly dividing the possible range into 128 different values.
* waveform sets the output waveform, 1 for square wave, 0 for saw wave.