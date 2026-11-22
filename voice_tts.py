import sys, asyncio, edge_tts
async def main():
    mode = sys.argv.pop()
    txt = sys.argv.pop()
    rate = "-8%" if mode == "med" else "-2%"
    await edge_tts.Communicate(txt, "uk-UA-OstapNeural", rate=rate, pitch="-10Hz").save("__import__("os").path.join(__import__("tempfile").gettempdir(),"master_voice.mp3")")
asyncio.run(main())
