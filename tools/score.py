"""Render the original 133-second Shellshift cue to mono PCM for Godot."""
import array
import math
import sys
import wave


RATE = 22050
audio = array.array("f", [0]) * (133 * RATE)

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

# A bright, lilting major-sixth figure during the years of trust.
for bar in range(13):
    root = [50, 55, 52, 57][bar % 4]
    start = 4 * bar
    for offset, interval in [(0, 0), (0.75, 4), (1.5, 7), (2.5, 9)]:
        note(start + offset, root + interval + 12, 1.5, 0.067, True)
    note(start, root, 4.4, 0.072)
# Carry the same figure into the laboratory, dropping its major third.
for start, root in [(54,50),(69,46),(84,43),(98,42),(111,38),(123,50)]:
    for interval in (0,7):
        note(start,root+interval,15.5,0.046)
    for delay, pitch in [(1,74),(3,77),(6,76)]:
        note(start+delay,pitch,4.2,0.072,True)
for start, pitch in [(55,31),(75,29),(95,30),(115,31)]:
    note(start,pitch,21,0.085)
# Let the final resonance fall away before the receipt appears.
for i in range(3 * RATE):
    audio[len(audio) - 3 * RATE + i] *= 1 - i / (3 * RATE)
with wave.open(sys.argv[1], "wb") as output:
    output.setparams((1,2,RATE,0,"NONE",""))
    output.writeframes(array.array("h",(int(32767*x) for x in audio)).tobytes())
