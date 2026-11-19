"""Render the original score for the playable shift. Run with Python."""
import array
import math
from pathlib import Path
import random
import wave

RATE = 32000
TAU = math.tau
OUT = Path(__file__).resolve().parents[1] / "godot" / "shift"


def cycle(hz, t, period, phase=0):
    # Quantized partials stay in phase over the sample boundary.
    return math.sin(TAU * round(hz * period) * t / period + phase)


def hum(t, duration):
    fan = 0.069 * cycle(48.8, t, duration) + 0.052 * cycle(97.6, t, duration, 0.3)
    blade = 0.018 * cycle(147, t, duration) * (0.65 + 0.35 * cycle(4.44, t, duration))
    # A remote open fifth occasionally admits a suspended second. No pulse.
    swell = 0.5 - 0.5 * cycle(1/duration, t, duration, math.pi/2)
    chord = 0.044 * cycle(146.83, t, duration) + 0.029 * cycle(220.0, t, duration)
    chord += 0.026 * cycle(164.81, t, duration, 0.7) * swell**2
    return fan + blade + chord * (0.6 + 0.4 * swell)


def loop():
    duration = 24
    size = RATE * duration
    rng = random.Random(317)
    air = array.array("f", (rng.uniform(-1, 1) for _ in range(size)))
    left = 0.0
    right = 0.0
    pcm = array.array("h")
    # Pre-roll both low pass filters from the end of the noise buffer.
    for i in range(-RATE//4, size):
        t = i/RATE
        left += 0.064 * (air[i] - left)
        right += 0.076 * (air[(i+271) % size] - right)
        if i < 0:
            continue
        common = hum(t,duration)
        speed = 0.75 + 0.18 * cycle(1/8,t,duration) + 0.07 * cycle(1/3,t,duration)
        image = 0.006 * cycle(218.75,t,duration,0.3)
        pcm.extend(round(x*32767) for x in (common+0.18*left*speed+image, common+0.18*right*speed-image))
    return pcm


def release():
    duration = 8
    notes = [(0.0, 146.83, .085), (.47, 220.00, .062), (1.2, 293.66, .057),
             (2.17, 369.99, .046), (3.1, 440.00, .027)]
    pcm = array.array("h")
    for i in range(RATE*duration):
        t = i/RATE
        voice = 0.0
        reflection = 0.0
        for j, (start,pitch,level) in enumerate(notes):
            age = t-start
            if age < 0:
                continue
            env = (1-math.exp(-age*3.8))*math.exp(-age*.71)*level
            phase = TAU*pitch*age
            voice += env*(math.sin(phase)+.18*math.sin(phase*2))
            reflection += env*.16*math.sin(phase*1.001 + (j%2)*.55)
        tail = min(1, (duration-t)/1.3)
        pcm.extend(round(x*32767*tail) for x in (voice+reflection,voice-reflection))
    return pcm


def write(name, pcm):
    path = OUT / f"shift_audio_{name}.wav"
    with wave.open(str(path), "wb") as output:
        output.setparams((2,2,RATE,0,"NONE",""))
        output.writeframes(pcm.tobytes())
    print(name, "peak",round(max(abs(sample) for sample in pcm)/32768, 3),
          "loop step L/R", tuple(round((pcm[k]-pcm[k-2])/32768,4) for k in (0,1)))


if __name__ == "__main__":
    write("room",loop())
    write("release",release())
