#include <cstdint>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

#include <verilated.h>
#include <Vtt_um_watpixels.h>

struct Config {
    static constexpr int H_VISIBLE = 640;
    static constexpr int V_VISIBLE = 480;
    static constexpr int H_TOTAL = 800;
    static constexpr int V_TOTAL = 525;
    static constexpr int FRAMES = 680;
    static constexpr int MODE = 3;
    static constexpr const char* OUTPUT_DIR = "frames";
};

uint8_t compute_ui(int mode, bool force_resume) {
    uint8_t ui = 0;
    if (mode >= 1 && mode <= 6) {
        ui = (1u << (mode + 1));
    }
    if (force_resume) {
        ui = ui | (1u << 1);
    }
    return ui;
}

bool write_frame(int index, const std::vector<uint8_t>& data) {
    std::ostringstream path;
    path << Config::OUTPUT_DIR << "/frame_" << std::setfill('0') << std::setw(3) << index << ".ppm";
    std::ofstream out(path.str(), std::ios::binary);
    if (!out) return false;
    out << "P6\n" << Config::H_VISIBLE << " " << Config::V_VISIBLE << "\n255\n";
    out.write(reinterpret_cast<const char*>(data.data()), data.size());
    return out.good();
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
    if (x == Config::H_TOTAL) {
        x = 0;
        y++;
        if (y == Config::V_TOTAL) {
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

    const uint8_t ui = compute_ui(Config::MODE, false);
    dut.ui_in = ui;
    
    dut.rst_n = 0;
    tick(dut, 2);
    dut.rst_n = 1;
    tick(dut, 2);

    int pixel_x = 0;
    int pixel_y = 0;
    const int cycles_per_frame = Config::H_TOTAL * Config::V_TOTAL;
    const size_t framebuffer_size = static_cast<size_t>(Config::H_VISIBLE) * Config::V_VISIBLE * 3u;
    std::vector<uint8_t> framebuffer(framebuffer_size);

    for (int frame_index = 0; frame_index < Config::FRAMES; frame_index = frame_index + 1) {
        size_t write_index = 0;
        for (int cycle = 0; cycle < cycles_per_frame; cycle = cycle + 1) {
            if (pixel_x < Config::H_VISIBLE && pixel_y < Config::V_VISIBLE) {
                uint8_t uo = dut.uo_out;
                framebuffer[write_index] = extract_color(uo, "red");
                write_index = write_index + 1;
                framebuffer[write_index] = extract_color(uo, "green");
                write_index = write_index + 1;
                framebuffer[write_index] = extract_color(uo, "blue");
                write_index = write_index + 1;
            }
            tick(dut, 1);
            advance_coords(pixel_x, pixel_y);
            if (context.gotFinish()) {
                std::cerr << "Simulation finished early." << std::endl;
                return 1;
            }
        }

        if (!write_frame(frame_index, framebuffer)) {
            return 1;
        }
    }

    dut.final();
    return 0;
}