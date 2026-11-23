import asyncio, os, sys, tempfile, edge_tts

async def main():
    mode = sys.argv.pop() if len(sys.argv) > 2 else "teach"
    txt = sys.argv.pop() if len(sys.argv) > 1 else "Вітаю у школі майстра."
    rate = "-22%" if mode == "med" else "-8%"
    out = os.path.join(tempfile.gettempdir(), "master_voice.mp3")
    await edge_tts.Communicate(txt, "uk-UA-OstapNeural", rate=rate, pitch="-16Hz").save(out)

asyncio.run(main())
