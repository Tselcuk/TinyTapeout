import os
import subprocess
import shutil
from pathlib import Path
import imageio_ffmpeg

class VerilatorVisualizer:
    def __init__(self):
        self.workspace = Path(__file__).parent
        self.build_dir = self.workspace / "obj_dir"
        self.output_path = self.workspace / "vga_output.mp4"

        self.job_count = os.cpu_count() or 1

        repo_root = Path(__file__).resolve().parents[1]
        source_dir = repo_root / "src"
        self.source_files = sorted(source_dir.rglob("*.v"))

        self.ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()

    def run(self):
        if self.build_dir.exists():
            shutil.rmtree(self.build_dir)

        verilator_cmd = [
                "verilator", "--cc", "--exe", "--build",
                "-j", str(self.job_count),
                "--top-module", "tt_um_watpixels", "-o", "vga_sim",
                str(Path(__file__).parent / "harness.cpp"),
                *map(str, self.source_files),
        ]
        print(f"Running Verilator: {' '.join(verilator_cmd)}")
        subprocess.run(verilator_cmd, cwd=self.workspace, check=True)

        self._run_simulation_to_mp4()

    def _run_simulation_to_mp4(self):
        self.output_path.parent.mkdir(parents=True, exist_ok=True)

        sim_cmd = [str(self.build_dir / "vga_sim")]
        ffmpeg_cmd = [
            self.ffmpeg_exe,
            "-y",
            "-f", "image2pipe",
            "-vcodec", "ppm",
            "-framerate", "60",
            "-i", "-",
            "-vf", "fps=60",
            "-c:v", "libx264",
            "-pix_fmt", "yuv420p",
            "-r", "60",
            str(self.output_path)
        ]

        print(f"Running simulation piped to FFmpeg...")
        sim_process = subprocess.Popen(
            sim_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            cwd=self.workspace
        )

        ffmpeg_process = subprocess.Popen(
            ffmpeg_cmd,
            stdin=sim_process.stdout,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        sim_process.stdout.close()

        sim_stderr = sim_process.stderr.read()
        _, ffmpeg_stderr = ffmpeg_process.communicate()

        sim_returncode = sim_process.wait()

        if sim_returncode != 0:
            raise subprocess.CalledProcessError(
                sim_returncode, sim_cmd, sim_stderr.decode()
            )

        if ffmpeg_process.returncode != 0:
            raise subprocess.CalledProcessError(
                ffmpeg_process.returncode, ffmpeg_cmd, ffmpeg_stderr.decode()
            )

        print(f"Saved animation: {self.output_path}")

if __name__ == "__main__":
    VerilatorVisualizer().run()
