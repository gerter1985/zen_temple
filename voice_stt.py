import os, sys, json, wave
from vosk import Model, KaldiRecognizer, SetLogLevel
SetLogLevel(-1)
wav = sys.argv.pop() if len(sys.argv) > 1 else "/tmp/tarot_voice.wav"
base = os.path.dirname(os.path.abspath(__file__))
m = Model(os.path.join(base, "model_ru"))
wf = wave.open(wav, "rb")
rec = KaldiRecognizer(m, wf.getframerate())
txt = []
while True:
    data = wf.readframes(4000)
    if not data: break
    if rec.AcceptWaveform(data): txt.append(json.loads(rec.Result()).get("text", ""))
txt.append(json.loads(rec.FinalResult()).get("text", ""))
print(" ".join(t for t in txt if t).strip())
