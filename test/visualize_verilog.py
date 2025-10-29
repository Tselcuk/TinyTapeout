#!/usr/bin/env python3
"""
Verilator-powered VGA visualiser for the TinyTapeout WatPixels design.

The script Verilates the RTL, clocks the design frame by frame, and captures the
RGB output directly without generating a VCD. Frames are written as PPM images
and combined into a static PNG or animated GIF.
"""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import List, Sequence

from PIL import Image

# VGA geometry (matches src/vga_timing.v)
H_VISIBLE = 640
V_VISIBLE = 480
H_TOTAL = 800
V_TOTAL = 525

TOP_MODULE = "tt_um_watpixels"
SOURCE_FILES = sorted(
    str(p.name)
    for p in (Path(__file__).resolve().parents[1] / "src").glob("*.v")
)

# Runtime defaults
DEFAULT_FRAMES = 2
DEFAULT_PATTERN_MODE = 3
DEFAULT_OUTPUT = "vga_output.gif"
DEFAULT_FRAME_DURATION_MS = 50
DEFAULT_WARMUP_LINES = 4


class SimulationError(RuntimeError):
    """Raised when the Verilator flow fails."""


HARNESS_TEMPLATE = (
    """
#include <verilated.h>
#include "__TOP_INCLUDE__"

#include <algorithm>
#include <cstdint>
#include <cstdlib>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

static constexpr int H_VISIBLE = __H_VISIBLE__;
static constexpr int V_VISIBLE = __V_VISIBLE__;
static constexpr int H_TOTAL = __H_TOTAL__;
static constexpr int V_TOTAL = __V_TOTAL__;

struct SimConfig {
    int frames = 1;
    int mode = 3;
    std::string output_dir;
    int warmup_lines = 4;
    bool verbose = false;
};

static bool parse_args(int argc, char** argv, SimConfig& cfg) {
    for (int i = 1; i < argc; ++i) {
        std::string arg(argv[i]);
        if (arg == "--frames" && i + 1 < argc) {
            cfg.frames = std::atoi(argv[++i]);
        } else if (arg == "--mode" && i + 1 < argc) {
            cfg.mode = std::atoi(argv[++i]);
        } else if (arg == "--output-dir" && i + 1 < argc) {
            cfg.output_dir = argv[++i];
        } else if (arg == "--warmup-lines" && i + 1 < argc) {
            cfg.warmup_lines = std::atoi(argv[++i]);
        } else if (arg == "--verbose") {
            cfg.verbose = true;
        } else {
            std::cerr << "Unknown or incomplete argument: " << arg << std::endl;
            return false;
        }
    }
    if (cfg.frames < 1) cfg.frames = 1;
    if (cfg.warmup_lines < 0) cfg.warmup_lines = 0;
    if (cfg.mode < 0) cfg.mode = 0;
    if (cfg.mode > 6) cfg.mode = 6;
    if (cfg.output_dir.empty()) {
        std::cerr << "Missing --output-dir argument." << std::endl;
        return false;
    }
    return true;
}

static uint8_t compute_ui(int mode, bool force_resume) {
    uint8_t ui = 0;
    switch (mode) {
        case 1: ui |= (1u << 2); break;
        case 2: ui |= (1u << 3); break;
        case 3: ui |= (1u << 4); break;
        case 4: ui |= (1u << 5); break;
        case 5: ui |= (1u << 6); break;
        case 6: ui |= (1u << 7); break;
        default: break;
    }
    if (force_resume) {
        ui |= (1u << 1);
    }
    return ui;
}

static bool write_frame(const SimConfig& cfg, int index, const std::vector<uint8_t>& data) {
    std::ostringstream path;
    path << cfg.output_dir << "/frame_" << std::setfill('0') << std::setw(3) << index << ".ppm";
    std::ofstream out(path.str(), std::ios::binary);
    if (!out) {
        std::cerr << "Unable to open " << path.str() << " for writing." << std::endl;
        return false;
    }
    out << "P6\\n" << H_VISIBLE << " " << V_VISIBLE << "\\n255\\n";
    out.write(reinterpret_cast<const char*>(data.data()), static_cast<std::streamsize>(data.size()));
    return true;
}

int main(int argc, char** argv) {
    VerilatedContext context;
    context.commandArgs(argc, argv);
    context.traceEverOn(false);

    SimConfig cfg;
    if (!parse_args(argc, argv, cfg)) {
        std::cerr << "Usage: " << argv[0]
                  << " --output-dir DIR [--frames N] [--mode M] [--warmup-lines L] [--verbose]" << std::endl;
        return 1;
    }

    __TOP_CLASS__ dut(&context);
    dut.clk = 0;
    dut.ena = 1;
    dut.uio_in = 0;
    dut.uio_oe = 0;

    auto eval_half = [&](int clk) {
        dut.clk = clk;
        dut.eval();
        context.timeInc(1);
    };

    auto tick = [&]() {
        eval_half(0);
        eval_half(1);
    };

    auto advance_coords = [&](int& x, int& y) {
        x += 1;
        if (x == H_TOTAL) {
            x = 0;
            y += 1;
            if (y == V_TOTAL) {
                y = 0;
            }
        }
    };

    const uint8_t ui_initial = compute_ui(cfg.mode, true);
    const uint8_t ui_steady = compute_ui(cfg.mode, false);

    dut.ui_in = ui_initial;
    dut.rst_n = 0;
    for (int i = 0; i < 8; ++i) {
        tick();
    }

    dut.rst_n = 1;
    for (int i = 0; i < 8; ++i) {
        tick();
    }
    dut.ui_in = ui_steady;

    int x = 0;
    int y = 0;

    const int warmup_cycles = cfg.warmup_lines * H_TOTAL;
    for (int i = 0; i < warmup_cycles; ++i) {
        tick();
        advance_coords(x, y);
    }

    while (!(x == 0 && y == 0)) {
        tick();
        advance_coords(x, y);
    }

    const int cycles_per_frame = H_TOTAL * V_TOTAL;
    std::vector<uint8_t> framebuffer(static_cast<size_t>(H_VISIBLE) * V_VISIBLE * 3u, 0);

    for (int frame_index = 0; frame_index < cfg.frames; ++frame_index) {
        std::fill(framebuffer.begin(), framebuffer.end(), 0);
        size_t write_index = 0;
        for (int cycle = 0; cycle < cycles_per_frame; ++cycle) {
            uint8_t uo = dut.uo_out;
            if (x < H_VISIBLE && y < V_VISIBLE) {
                uint8_t r = static_cast<uint8_t>(((((uo >> 7) & 0x1u) << 1) | ((uo >> 3) & 0x1u)) * 85u);
                uint8_t g = static_cast<uint8_t>(((((uo >> 6) & 0x1u) << 1) | ((uo >> 2) & 0x1u)) * 85u);
                uint8_t b = static_cast<uint8_t>(((((uo >> 5) & 0x1u) << 1) | ((uo >> 1) & 0x1u)) * 85u);
                framebuffer[write_index++] = r;
                framebuffer[write_index++] = g;
                framebuffer[write_index++] = b;
            }
            tick();
            advance_coords(x, y);
            if (context.gotFinish()) {
                break;
            }
        }

        if (context.gotFinish()) {
            std::cerr << "Simulation finished early." << std::endl;
            return 1;
        }

        if (write_index != framebuffer.size()) {
            std::cerr << "Frame " << frame_index << " captured " << write_index
                      << " bytes, expected " << framebuffer.size() << std::endl;
            return 1;
        }

        if (cfg.verbose) {
            std::cout << "Captured frame " << frame_index << std::endl;
        }

        if (!write_frame(cfg, frame_index, framebuffer)) {
            return 1;
        }
    }

    dut.final();
    return 0;
}
"""
    .replace("__H_VISIBLE__", str(H_VISIBLE))
    .replace("__V_VISIBLE__", str(V_VISIBLE))
    .replace("__H_TOTAL__", str(H_TOTAL))
    .replace("__V_TOTAL__", str(V_TOTAL))
    .replace("__TOP_INCLUDE__", f"V{TOP_MODULE}.h")
    .replace("__TOP_CLASS__", f"V{TOP_MODULE}")
)


class VerilatorVisualizer:
    """Orchestrates Verilator compilation, execution, and image assembly."""

    def __init__(
        self,
        repo_root: Path,
        frames: int,
        pattern_mode: int,
        output_path: Path,
        frame_duration_ms: int,
        warmup_lines: int,
        verbose: bool = False,
    ) -> None:
        self.repo_root = repo_root
        self.frames = max(1, frames)
        self.pattern_mode = max(0, min(pattern_mode, 6))
        self.output_path = output_path
        self.frame_duration_ms = max(1, frame_duration_ms)
        self.warmup_lines = max(0, warmup_lines)
        self.verbose = verbose

        self.workspace = Path(tempfile.mkdtemp(prefix="tt_vga_verilator_"))
        self.build_dir = self.workspace / "obj_dir"
        self.frames_dir = self.workspace / "frames"
        self.harness_path = self.workspace / "sim_main.cpp"

        self.source_files: Sequence[Path] = [
            self.repo_root / "src" / name for name in SOURCE_FILES
        ]

    def run(self) -> List[Image.Image]:
        try:
            self._ensure_prerequisites()
            self._write_harness()
            self._build_model()
            self._execute_model()
            frames = self._load_frames()
            self._write_output(frames)
            if not frames:
                raise SimulationError("Simulation completed but produced no frames.")
            return frames
        finally:
            shutil.rmtree(self.workspace, ignore_errors=True)

    # ------------------------------------------------------------------ helpers --
    def _ensure_prerequisites(self) -> None:
        if shutil.which("verilator") is None:
            raise SimulationError(
                "verilator not found on PATH. Install Verilator to enable this flow."
            )
        missing = [str(path) for path in self.source_files if not path.exists()]
        if missing:
            raise SimulationError(f"Missing Verilog sources: {', '.join(missing)}")

    def _write_harness(self) -> None:
        self.frames_dir.mkdir(parents=True, exist_ok=True)
        self.harness_path.write_text(HARNESS_TEMPLATE)

    def _build_model(self) -> None:
        cmd = [
            "verilator",
            "--cc",
            "--exe",
            "--build",
            "-j",
            "0",
            "--top-module",
            TOP_MODULE,
            "-o",
            "vga_sim",
            str(self.harness_path.name),
            *(str(path) for path in self.source_files),
        ]
        self._run_command(cmd, cwd=self.workspace, label="Verilator build")

    def _execute_model(self) -> None:
        binary = self.build_dir / "vga_sim"
        if not binary.exists():
            raise SimulationError("Verilator build did not produce the expected executable.")

        cmd = [
            str(binary),
            "--frames",
            str(self.frames),
            "--mode",
            str(self.pattern_mode),
            "--output-dir",
            str(self.frames_dir),
            "--warmup-lines",
            str(self.warmup_lines),
        ]
        if self.verbose:
            cmd.append("--verbose")
        self._run_command(cmd, cwd=self.workspace, label="Simulation")

    def _load_frames(self) -> List[Image.Image]:
        frames: List[Image.Image] = []
        ppm_files = sorted(self.frames_dir.glob("frame_*.ppm"))
        for ppm_path in ppm_files:
            with Image.open(ppm_path) as img:
                frames.append(img.copy())
        return frames

    def _write_output(self, frames: List[Image.Image]) -> None:
        output_dir = self.output_path.expanduser().resolve().parent
        output_dir.mkdir(parents=True, exist_ok=True)

        if not frames:
            return

        if len(frames) == 1:
            target = self.output_path.with_suffix(self.output_path.suffix or ".png")
            frames[0].save(target)
            print(f"Saved image: {target}")
        else:
            target = self.output_path.with_suffix(".gif")
            frames[0].save(
                target,
                save_all=True,
                append_images=frames[1:],
                duration=self.frame_duration_ms,
                loop=0,
            )
            print(f"Saved animation: {target} ({len(frames)} frames)")

    def _run_command(self, cmd: Sequence[str], cwd: Path, label: str) -> None:
        try:
            subprocess.run(
                cmd,
                cwd=str(cwd),
                check=True,
                text=True,
            )
        except subprocess.CalledProcessError as exc:
            raise SimulationError(f"{label} failed with exit code {exc.returncode}.") from exc


# ======================================================================= CLI ===
def build_arg_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Compile the WatPixels TinyTapeout design with Verilator, "
        "simulate VGA output, and render frames.",
    )
    parser.add_argument(
        "--frames",
        type=int,
        default=DEFAULT_FRAMES,
        help=f"Number of frames to capture (default: {DEFAULT_FRAMES}).",
    )
    parser.add_argument(
        "--mode",
        type=int,
        default=DEFAULT_PATTERN_MODE,
        choices=range(0, 7),
        help="Animation speed mode 0-6 (mirrors ui_in[2:7] selection).",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(DEFAULT_OUTPUT),
        help=f"Output image or GIF path (default: {DEFAULT_OUTPUT}).",
    )
    parser.add_argument(
        "--frame-duration",
        type=int,
        default=DEFAULT_FRAME_DURATION_MS,
        help="Frame duration in milliseconds for GIF output (default: 50).",
    )
    parser.add_argument(
        "--warmup-lines",
        type=int,
        default=DEFAULT_WARMUP_LINES,
        help=f"Number of full lines to skip before capturing (default: {DEFAULT_WARMUP_LINES}).",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose logging from the C++ harness.",
    )
    return parser


def main(argv: List[str] | None = None) -> int:
    parser = build_arg_parser()
    args = parser.parse_args(argv)

    repo_root = Path(__file__).resolve().parents[1]
    simulator = VerilatorVisualizer(
        repo_root=repo_root,
        frames=args.frames,
        pattern_mode=args.mode,
        output_path=args.output,
        frame_duration_ms=args.frame_duration,
        warmup_lines=args.warmup_lines,
        verbose=args.verbose,
    )

    try:
        simulator.run()
    except SimulationError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1
    except KeyboardInterrupt:
        print("Interrupted by user.")
        return 130

    print("Done.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
