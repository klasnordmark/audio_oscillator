import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
import math
import numpy as np
import scipy.signal as signal
import matplotlib.pyplot as plt

def calculate_divisor(f, fs):
    return math.floor((2**32)/(fs/f))

def get_main_freq(fs, buffer):
    n = len(buffer)
    k = np.arange(n)
    T = n/fs
    freqs = k/T
    freqs = freqs[:len(freqs)//2]
    fft_buffer = np.fft.fft(buffer)/n
    fft_buffer = fft_buffer[:n//2]
    fft_buffer[0] = 0 # remove constant component
    return freqs[np.argmax(abs(fft_buffer))]

async def get_buffer(dut, buffer):
    i = 0
    while (i < len(buffer)):
        if (dut.tvalid == 1):
            buffer[i] = dut.tdata.value.signed_integer
            i = i + 1
        await(ClockCycles(dut.clk, 1))
    return buffer

async def reset(dut):
    dut.divisor.value = 0
    dut.duty.value = 64
    dut.waveform.value = 0
    dut.tready.value = 0
    dut.reset_n.value = 0
    await ClockCycles(dut.clk, 5)
    dut.reset_n.value = 1
    await ClockCycles(dut.clk, 5)

# Test will exercise that we get the correct frequency and duty cycle
# Bus behavior is covered by formal assertions
@cocotb.test()
async def test_audio_oscillator(dut):
    clock = Clock(dut.clk, 20, units="ns")
    cocotb.fork(clock.start())

    await reset(dut)

    fs = 44100
    dut.divisor.value = calculate_divisor(220.0, fs)
    dut.tready.value = 1
    dut.duty.value = 64

    # Test 220 Hz
    output = np.zeros(math.floor(fs/4))
    await get_buffer(dut, output)
    max_freq = get_main_freq(fs, output)
    assert(max_freq == 220)

    # Switch to 440 Hz
    dut.divisor.value = calculate_divisor(440.0, fs)
    await get_buffer(dut, output)
    max_freq = get_main_freq(fs, output)
    assert(max_freq == 440)

    # Test square wave with 50% duty cycle
    dut.waveform.value = 1
    await get_buffer(dut, output)
    max_freq = get_main_freq(fs, output)
    assert(max_freq == 440)
    # apart from not checking exactly where in a cycle
    # we start and end, we only have 128 different duty
    # cycle values. (2**16)/128 yields 512, so we use
    # +- 256 as our margins
    average = np.average(output)
    assert((average > -256) & (average < 256))

    # Test square wave with 75% duty cycle
    #16384
    dut.duty.value = 96
    await get_buffer(dut, output)
    max_freq = get_main_freq(fs, output)
    assert(max_freq == 440)
    average = np.average(output)
    print(average)
    assert((average > (16384-256)) & (average < (16384+256)))