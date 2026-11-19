"""Render the original 68-second Shellshift cue to mono PCM for Godot."""
import array
import math
import sys
import wave


RATE = 22050
audio = array.array("f", [0]) * (68 * RATE)

def note(start, midi, duration, gain, bell=False):
    frequency = 440 * 2 ** ((midi - 69) / 12)
    offset = int(start * RATE)
    length = min(int(duration * RATE), len(audio) - offset)
    for i in range(length):
        t = i / RATE
        phase = math.tau * frequency * t
        envelope = min(1, t / (0.02 if bell else 0.85)) * min(1, (length-i) / (RATE * 0.5))
        if bell:
            envelope *= math.exp(-2.4*t/duration)
        tone = math.sin(phase) + 0.28 * math.sin(phase * (2.01 if bell else 1.004))
        audio[offset+i] += gain * tone * envelope

for start, root in [(0,50),(10,46),(23,43),(35,42),(46,38),(58,50)]:
    for interval in (0,7):
        note(start,root+interval,13.0,0.046)
    for delay, pitch in [(1,74),(3,77),(6,76)]:
        note(start+delay,pitch,4.2,0.072,True)
for start, pitch in [(0, 31), (19, 29), (37, 30), (54, 31)]:
    note(start, pitch, 21, 0.085)
# Let the final resonance fall away before the receipt appears.
for i in range(3 * RATE):
    audio[len(audio) - 3 * RATE + i] *= 1 - i / (3 * RATE)
with wave.open(sys.argv[1], "wb") as output:
    output.setparams((1,2,RATE,0,"NONE",""))
    output.writeframes(array.array("h",(int(32767*x) for x in audio)).tobytes())
