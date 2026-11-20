"""Record the hospital take or the ensemble reel from the playable Godot project."""
import argparse
import json
import subprocess
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PROJECT = ROOT / "godot"
PREVIEWS = ROOT / "previews"
FPS = 24
SCORE = PROJECT / "shift-score.mp3"

# Profile, set, first second on set, shot length. Music cue times come from
# screenplay.gd so an edit to the full film also moves the corresponding score.
ENSEMBLE = [
    (0, 10, 4.5, 3.0),    # Rosa and her mother at the claims window
    (0, 11, 5.5, 3.0),    # The pears make it into the bag.
    (0, 0, 1.75, 9.5),    # Green tests, the knuckle tap, four o'clock
    (0, 1, 5.0, 3.5),     # Two cups at the telescope, before the ward visit
    (1, 1, 3.75, 3.0),    # Nico hears his brother on the radio
    (2, 1, 2.0, 3.0),     # Lea at the witness bench
    (0, 3, 8.75, 5.5),    # Mara fixes Ada's scarf and hugs her
    (2, 4, 10.6, 3.5),    # Lea stamps the proof and looks up at the next run.
    (0, 5, 2.75, 7.0),    # The cup and the empty stool
    (0, 6, 1.5, 3.0),     # Ivo at the railway controls
    (0, 7, 7.75, 3.5),    # Ren holds the gate while a visitor retrieves her papers.
    (0, 8, 1.75, 5.5),    # The transfer and the falling notebook
]


def music_starts():
    import re

    script = (PROJECT / "screenplay.gd").read_text()
    def values(name):
        match = re.search(rf"^const {name} := (\[[^\]]*\])", script, re.MULTILINE)
        return json.loads(match.group(1))
    durations = values("SECONDS")
    starts = {}
    elapsed = 0
    for index in values("SHOT_ORDER"):
        starts[index] = elapsed
        elapsed += durations[index]
    return starts


def score_edit(cuts, starts):
    """Overlap audio handles before picture cuts, preserving the runtime."""
    dissolve = 0.25
    filters = []
    for i, (_, scene, offset, length) in enumerate(cuts):
        handle = dissolve if i else 0.0
        start = starts[scene] + offset - handle
        filters.append(
            f"[1:a]atrim=start={start}:duration={length+handle},asetpts=PTS-STARTPTS[s{i}]"
        )
    last = "s0"
    for i in range(1, len(cuts)):
        filters.append(f"[{last}][s{i}]acrossfade=d={dissolve}:c1=qsin:c2=qsin[a{i}]")
        last = f"a{i}"
    duration = sum(cut[3] for cut in cuts)
    filters.append(
        f"[{last}]volume=7.5dB,afade=in:st=0:d=0.18,"
        f"afade=out:st={duration-.55}:d=0.55[music]"
    )
    return ";".join(filters)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ensemble", action="store_true", help="Record the cast across the prologue")
    ensemble = parser.parse_args().ensemble
    cuts = ENSEMBLE if ensemble else [(0, 3, 0.0, 15.0)]
    movie = PREVIEWS / ("provino-cast.mp4" if ensemble else "provino-ada-mara.mp4")
    duration = sum(cut[3] for cut in cuts)
    PREVIEWS.mkdir(exist_ok=True)
    subprocess.run(["godot", "--headless", "--path", str(PROJECT), "--editor", "--import"], check=True)
    with tempfile.TemporaryDirectory(prefix=".casting-", dir=PREVIEWS) as workdir:
        work = Path(workdir)
        render = [
            "godot", "--path", str(PROJECT), "--audio-driver", "Dummy",
            "--resolution", "160x90", "--position", "-10000,-10000",
            "--disable-vsync", "--fixed-fps", str(FPS),
            "--script", str(ROOT / "tools" / "render_casting.gd"), "--", str(work),
        ]
        if ensemble:
            render.append(json.dumps(cuts))
        subprocess.run(render, check=True)
        if len(list(work.glob("*.jpg"))) != round(duration*FPS):
            raise RuntimeError("The take is incomplete")
        subprocess.run([
            "ffmpeg", "-nostdin", "-hide_banner", "-loglevel", "error",
            "-framerate", str(FPS), "-i", str(work / "%04d.jpg"), "-i", str(SCORE),
            "-filter_complex", score_edit(cuts, music_starts()), "-map", "0:v:0", "-map", "[music]",
            "-t", str(duration), "-vf", "scale=in_range=full:out_color_matrix=bt709,format=yuv420p",
            "-c:v", "libx264", "-crf", "17", "-colorspace", "bt709",
            "-color_primaries", "bt709", "-color_trc", "bt709",
            "-c:a", "aac", "-b:a", "160k", "-movflags", "+faststart", str(work / "take.mp4"),
        ], check=True)
        (work / "take.mp4").replace(movie)
    print(movie)


if __name__ == "__main__":
    main()
