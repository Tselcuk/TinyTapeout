#include <cstdint>
#include <iostream>
#include <string>
#include <vector>
#include <tuple>
#include <stdexcept>
#include <verilated.h>
#include <Vtt_um_watpixels.h>

constexpr int FRAMES = 150;

bool write_frame(const std::vector<uint8_t>& data) {
    std::cout << "P6\n640 480\n255\n";
    std::cout.write(reinterpret_cast<const char*>(data.data()), data.size());
    return std::cout.good();
}

void tick(Vtt_um_watpixels& dut, int count) {
    for (int i = 0; i < count; i++) {
        dut.clk = 0;
        dut.eval();
        dut.clk = 1;
        dut.eval();
    }
}

void advance_coords(int& x, int& y) {
    x++;
    if (x == 800) {
        x = 0;
        y++;
        if (y == 525) {
            y = 0;
        }
    }
}

uint8_t extract_color(uint8_t val, const std::string& color) {
    int hi_bit;
    int lo_bit;
    
    if (color == "red") {
        hi_bit = 7;
        lo_bit = 3;
    } else if (color == "green") {
        hi_bit = 6;
        lo_bit = 2;
    } else if (color == "blue") {
        hi_bit = 5;
        lo_bit = 1;
    } else {
        throw std::invalid_argument("Invalid color: " + color);
    }
    
    uint8_t hi = (val >> hi_bit) & 1u;
    uint8_t lo = (val >> lo_bit) & 1u;
    uint8_t two_bit = (hi << 1) | lo;
    return two_bit * 85u;
}

int main() {
    VerilatedContext context;
    context.traceEverOn(false);

    Vtt_um_watpixels dut(&context);
    dut.clk = 0;

    // Events: (cycle, bit, value)
    // - cycle: absolute clock cycle number when event triggers
    // - bit: which ui_in bit to modify (0-7)
    // - value: set bit to 0 or 1
    // Clock frequency: 25.2 MHz (1 second = 25,200,000 cycles)
    // Events MUST be sorted by cycle number
    std::vector<std::tuple<int64_t, int, int>> events = {
        {0, 3, 1},           // Set ui_in[3] to 1 (speed_2) at start
        {126000000, 0, 1},   // Set ui_in[0] to 1 (pause) at 5 seconds
        {126000001, 0, 0},   // Set ui_in[0] to 0 (clear pause) 1 cycle later (simulate a button press)
        {176400000, 1, 1},   // Set ui_in[1] to 1 (resume) at 7 seconds
        {176400001, 1, 0},   // Set ui_in[1] to 0 (clear resume) 1 cycle later (simulate a button press)
        {252000000, 3, 0},   // Set ui_in[3] to 0 (clear speed_2) at 10 seconds
        {252000000, 5, 1},   // Set ui_in[5] to 1 (speed_4) at 10 seconds
    };

    dut.ui_in = 0;
    
    dut.rst_n = 0;
    tick(dut, 2);
    dut.rst_n = 1;
    tick(dut, 2);

    int pixel_x = 0;
    int pixel_y = 0;
    const int cycles_per_frame = 800 * 525;
    const size_t framebuffer_size = static_cast<size_t>(640) * 480 * 3u;
    std::vector<uint8_t> framebuffer(framebuffer_size);

    int64_t total_cycles = 0;
    uint8_t uin = 0;
    size_t next_event_idx = 0;

    for (int frame_index = 0; frame_index < FRAMES; frame_index++) {
        size_t write_index = 0;
        for (int cycle = 0; cycle < cycles_per_frame; cycle++) {
            while (next_event_idx < events.size() && total_cycles == std::get<0>(events[next_event_idx])) {
                int bit = std::get<1>(events[next_event_idx]);
                int value = std::get<2>(events[next_event_idx]);
                uint8_t bit_mask = 1u << bit;

                // Update uin state
                if (value == 1) {
                    uin |= bit_mask;
                } else {
                    uin &= ~bit_mask;
                }

                next_event_idx++;
            }

            // Apply current uin state to hardware
            dut.ui_in = uin;

            if (pixel_x < 640 && pixel_y < 480) {
                uint8_t uo = dut.uo_out;
                framebuffer[write_index++] = extract_color(uo, "red");
                framebuffer[write_index++] = extract_color(uo, "green");
                framebuffer[write_index++] = extract_color(uo, "blue");
            }
            
            // Execute one clock cycle
            tick(dut, 1);
            total_cycles++;

            advance_coords(pixel_x, pixel_y);
            if (context.gotFinish()) {
                std::cerr << "Simulation finished early." << std::endl;
                return 1;
            }
        }

        if (!write_frame(framebuffer)) {
            return 1;
        }
    }

    dut.final();
    return 0;
}
