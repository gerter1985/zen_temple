import sys, wave
try:
    import sounddevice as sd
    rec = sd.rec(int(35 * 16000), samplerate=16000, channels=1, dtype='int16')
    sys.stdin.readline()
    sd.stop()
    with wave.open(sys.argv.pop(), 'wb') as wf:
        wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(16000); wf.writeframes(rec.tobytes())
except Exception:
    pass
