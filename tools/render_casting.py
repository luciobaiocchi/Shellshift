"""Render the Ada and Mara screen test with Godot, then encode its original score."""
import subprocess
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot"
PREVIEW = ROOT / "previews" / "provino-ada-mara.mp4"


def main():
    PREVIEW.parent.mkdir(exist_ok=True)
    subprocess.run([
        "godot", "--headless", "--path", str(PROJECT), "--editor", "--import",
    ], check=True)
    with tempfile.TemporaryDirectory(prefix=".casting-", dir=PREVIEW.parent) as workdir:
        work = Path(workdir)
        subprocess.run([
            "godot", "--path", str(PROJECT), "--audio-driver", "Dummy",
            "--resolution", "160x90", "--position", "-10000,-10000",
            "--disable-vsync", "--fixed-fps", "24",
            "--script", str(ROOT / "tools" / "render_casting.gd"),
            "--", str(work),
        ], check=True)
        if len(list(work.glob("*.png"))) != 360:
            raise RuntimeError("The 15-second take is incomplete")
        movie = work / "take.mp4"
        subprocess.run([
            "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
            "-framerate", "24", "-i", str(work / "%04d.png"),
            "-ss", "81", "-i", str(PROJECT / "shift-score.mp3"),
            "-map", "0:v:0", "-map", "1:a:0", "-t", "15",
            "-vf", "scale=out_color_matrix=bt709,format=yuv420p",
            "-c:v", "libx264", "-crf", "17",
            "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709",
            "-af", "volume=7.5dB,afade=in:st=0:d=0.18,afade=out:st=14.45:d=0.55",
            "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart",
            str(movie),
        ], check=True)
        movie.replace(PREVIEW)
    print(PREVIEW)


if __name__ == "__main__":
    main()
