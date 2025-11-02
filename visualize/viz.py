import os
import subprocess
import tempfile
from pathlib import Path
from PIL import Image

class VerilatorVisualizer:
    def __init__(self):
        self.output_path = Path("vga_output.gif")
        self.frame_duration_ms = round(1000 / 60)  # 60 Hz refresh rate
        self.workspace = Path(tempfile.mkdtemp(prefix="tt_vga_verilator_"))
        self.build_dir = self.workspace / "obj_dir"
        self.frames_dir = self.workspace / "frames"
        self.job_count = max(4, os.cpu_count() or 1)

        repo_root = Path(__file__).resolve().parents[1]
        source_dir = repo_root / "src"
        self.source_files = sorted(source_dir.rglob("*.v"))

    def run(self):
        self.frames_dir.mkdir(parents=True, exist_ok=True)

        subprocess.run(
            [
                "verilator", "--cc", "--exe", "--build",
                "-j", str(self.job_count),
                "--top-module", "tt_um_watpixels", "-o", "vga_sim",
                str(Path(__file__).parent / "harness.cpp"),
                *map(str, self.source_files),
            ],
            cwd=self.workspace,
        )

        subprocess.run(
            [str(self.build_dir / "vga_sim")],
            cwd=self.workspace,
        )

        frames = [Image.open(p).copy() for p in sorted(self.frames_dir.glob("frame_*.ppm"))]
        if frames:
            self._write_output(frames)
        return frames

    def _write_output(self, frames):
        self.output_path.parent.mkdir(parents=True, exist_ok=True)
        frames[0].save(self.output_path, save_all=True, append_images=frames[1:],
                      duration=self.frame_duration_ms, loop=0)
        print(f"Saved animation: {self.output_path} ({len(frames)} frames)")

if __name__ == "__main__":
    VerilatorVisualizer().run()
