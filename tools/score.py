"""Render the original 193-second archive score as PCM using Python."""
import array
import math
import sys
import wave

RATE = 24000
DURATION = 193
audio = array.array("f", [0]) * (DURATION * RATE)


def note(start, pitch, duration, gain, bowed=False):
    frequency = 440 * 2 ** ((pitch - 69) / 12)
    offset = round(start * RATE)
    length = min(round(duration * RATE), len(audio) - offset)
    for i in range(length):
        t = i / RATE
        phase = math.tau * frequency * t
        tail = min(1, (length-i) / (RATE * .38))
        if bowed:
            attack = min(1, t / .85)
            tone = math.sin(phase) + .17 * math.sin(phase * 2.002 + .05 * math.sin(4.5*t))
            envelope = attack * tail * (.87 + .13 * math.sin(1.1*t))
        else:
            attack = 1-math.exp(-t*72)
            tone = math.sin(phase) + math.exp(-2.2*t) * (.26*math.sin(phase*2.001) + .095*math.sin(phase*3.006))
            envelope = attack * tail * math.exp(-t*.94)
        audio[offset+i] += gain * tone * envelope


def theme(start, pitches, spacing, gain=.095):
    for i, (pitch, delay) in enumerate(zip(pitches, spacing)):
        note(start+delay, pitch, 3.3, gain * (1, .78, 1.05, .62)[i])


# At the two counters, the queue moves to a clock with a slightly uneven escapement.
# The clerk's bell becomes the first two notes of the music Rosa hears on the bus.
def counter_bell(start, pitch, gain):
    note(start, pitch, .65, gain)
    note(start, pitch+19, .22, gain*.24)


for i in range(14):
    counter_bell(2.6+i*.89, 76 if i%2 else 71, .027 if i%2 else .043)
note(.75, 50, 8.2, .031, True)
theme(6.3, [62,64], [0,2.1], .055)
note(11.1, 55, 6.1, .037, True)
note(15.2, 45, 4.8, .032, True)
note(17.8, 62, 3.0, .048)
for start, bass in [(22.4,50),(27.9,55),(33.3,47),(38.0,50)]:
    note(start, bass, 4.1, .040, True)
    note(start+.27, bass+7, 3.8, .023, True)
    theme(start+.6, [bass+12,bass+16,bass+19], [0,.66,1.61], .069)
counter_bell(37.2, 74, .055)
counter_bell(37.86, 78, .041)

# Friday afternoon and the early human archive.
theme(43.22, [62,66,69], [0,.62,1.46])
note(46.15,64,2.8,.058)
for start, bass in [(47.4,50),(54.1,47),(59.2,55),(64.8,50),(70.1,55),(75.4,52)]:
    note(start,bass,5.3,.045,True)
    note(start+.22,bass+7,4.8,.025,True)
    theme(start+.4,[bass+12,bass+16,bass+19,bass+21],[0,.78,1.84,3.42],.078)

# The ward doors open. Under the collar and embrace the accompaniment falls away.
note(81.2,50,8.9,.046,True)
note(82.0,57,8.7,.031,True)
theme(83.8,[62,66,69],[0,1.1,2.68],.078)
note(89.6,64,3.8,.049)
note(93.3,62,2.8,.039)

# The council office returns at 2:20. Its answering bell is a semitone flat.
for start, bass in [(96,50),(102.5,47),(111,46),(119.5,43),(126,43),
                    (132,48),(140,49),(149,43),(158,42),(171,38),(183,50)]:
    note(start,bass,9.3,.045,True)
    note(start+.45,bass+7,8.1,.023,True)
theme(112.8,[62,66],[0,1.45],.062)
for start, pitches in [(97.1,[74,73,71]),(121.8,[66,64]),(127.8,[62,65,69]),
                       (158.9,[69,68]),(172.9,[62,61]),(183.7,[62,66])]:
    theme(start,pitches,[0,1.65,3.74],.059)
counter_bell(141.4,74,.045)
counter_bell(142.06,77,.037)
for start in (148.1,152.5,154.0):
    counter_bell(start,65,.030)
for start,pitch in [(97,31),(123,30),(144,31),(158,30),(172,29)]:
    note(start,pitch,17,.053,True)

with wave.open(sys.argv[1], "wb") as output:
    output.setparams((1,2,RATE,0,"NONE",""))
    pcm = array.array("h")
    for i, sample in enumerate(audio):
        fade = min(1, (len(audio)-i) / (3*RATE))
        pcm.append(round(32767*sample*fade))
    output.writeframes(pcm.tobytes())
