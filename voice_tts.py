import os, subprocess, sys, tempfile

args = sys.argv[1:]
txt = (args if args else "Приветствую в школе Оракула Гекаты.")[:600]
base = os.path.dirname(os.path.abspath(__file__))
model = os.path.join(base, "tts_ru", "ruslan.onnx")
out = os.path.join(tempfile.gettempdir(), "master_voice.mp3")
wav = os.path.join(tempfile.gettempdir(), "master_raw.wav")
subprocess.run(["piper", "--model", model, "--output_file", wav], input=txt.encode("utf-8"), stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
subprocess.run(["ffmpeg", "-y", "-i", wav, "-b:a", "192k", out], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
