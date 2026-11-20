"""Record Ada's full in-game film and English captions as a 720p MP4."""
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot"
MOVIE = ROOT / "previews" / "prologo.mp4"
FPS = 24


def main():
    MOVIE.parent.mkdir(exist_ok=True)
    subprocess.run(["godot", "--headless", "--editor", "--path", str(PROJECT), "--import"], check=True)
    with tempfile.TemporaryDirectory(prefix="shellshift-film-") as frames_dir:
        frames = Path(frames_dir)
        subprocess.run([
            "godot", "--path", str(PROJECT), "--audio-driver", "Dummy", "--resolution", "160x90",
            "--position", "-10000,-10000", "--disable-vsync", "--fixed-fps", str(FPS),
            "--script", str(ROOT / "tools" / "render_prologue.gd"), "--", str(frames),
        ], check=True)
        count = len(list(frames.glob("*.jpg")))
        duration = float(subprocess.check_output([
            "ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
            str(PROJECT / "shift-score.mp3"),
        ]))
        if count != round(duration*FPS):
            raise RuntimeError(f"The score lasts {duration} seconds but the film has {count} frames")
        with tempfile.TemporaryDirectory(prefix=".film-", dir=MOVIE.parent) as destination:
            output = Path(destination) / MOVIE.name
            subprocess.run([
                "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
                "-framerate", str(FPS), "-i", str(frames / "%05d.jpg"),
                "-i", str(PROJECT / "shift-score.mp3"), "-map", "0:v:0", "-map", "1:a:0",
                "-t", str(count/FPS), "-vf", "scale=in_range=full:out_range=tv:out_color_matrix=bt709,format=yuv420p",
                "-c:v", "libx264", "-crf", "21", "-maxrate", "3500k", "-bufsize", "7000k",
                "-colorspace", "bt709", "-color_primaries", "bt709", "-color_trc", "bt709", "-color_range", "tv",
                "-c:a", "aac", "-b:a", "160k", "-af", "volume=7.5dB",
                "-movflags", "+faststart", str(output),
            ], check=True)
            metadata = json.loads(subprocess.check_output([
                "ffprobe", "-v", "error", "-show_entries", "stream=codec_type,nb_frames,duration",
                "-of", "json", str(output),
            ]))
            video, audio = metadata["streams"]
            if (int(video["nb_frames"]) != count or audio["codec_type"] != "audio"
                    or abs(float(video["duration"]) - float(audio["duration"])) > 1/FPS
                    or output.stat().st_size > 95_000_000):
                raise RuntimeError("The movie failed its length, track or size check")
            output.replace(MOVIE)
    print(MOVIE)


if __name__ == "__main__":
    main()
