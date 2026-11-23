import sys, json, wave
from vosk import Model, KaldiRecognizer, SetLogLevel
SetLogLevel(-1)
wf = wave.open(sys.argv.pop(), "rb")
rec = KaldiRecognizer(Model(__import__("os").path.join(__import__("os").path.dirname(__file__),"model_uk")), wf.getframerate())
res = []
while True:
    data = wf.readframes(4000)
    if not data: break
    if rec.AcceptWaveform(data):
        res.append(json.loads(rec.Result()).get("text", ""))
res.append(json.loads(rec.FinalResult()).get("text", ""))
print(" ".join(x for x in res if x).strip())
