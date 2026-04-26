from fastapi import FastAPI, File, UploadFile, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
import httpx
import os
import shutil
import json
import urllib.error
import urllib.request

app = FastAPI(title="CrisisFlow Backend")

# =========================
# CORS (allow frontend)
# =========================
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten later
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# =========================
# HEALTH CHECK
# =========================
@app.get("/health")
async def health():
    ffmpeg_path = shutil.which("ffmpeg")
    return {
        "ok": True,
        "ffmpegFound": ffmpeg_path is not None,
        "ffmpegPath": ffmpeg_path,
        "hfApiConfigured": bool(os.getenv("HF_API_KEY", "").strip()),
    }

# =========================
# OCR (Hugging Face)
# =========================
HF_OCR_ENDPOINTS = [
    "https://router.huggingface.co/hf-inference/models/microsoft/trocr-large-printed",
    "https://api-inference.huggingface.co/models/microsoft/trocr-large-printed",
]

@app.post("/ocr")
async def ocr(file: UploadFile = File(...)):
    hf_api_key = os.getenv("HF_API_KEY", "").strip()
    if not hf_api_key:
        raise HTTPException(status_code=500, detail="HF_API_KEY not configured")

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Empty image")

    payload = None
    last_error = None

    for endpoint in HF_OCR_ENDPOINTS:
        try:
            req = urllib.request.Request(
                endpoint,
                data=image_bytes,
                headers={
                    "Authorization": f"Bearer {hf_api_key}",
                    "Content-Type": "application/octet-stream",
                },
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=90) as response:
                payload = response.read().decode("utf-8")
                break
        except urllib.error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="ignore")
            last_error = body
            continue
        except Exception as exc:
            last_error = str(exc)
            continue

    if payload is None:
        raise HTTPException(status_code=502, detail=last_error or "OCR failed")

    try:
        decoded = json.loads(payload)
    except:
        raise HTTPException(status_code=502, detail="Invalid OCR response")

    if isinstance(decoded, dict):
        if decoded.get("error"):
            raise HTTPException(status_code=502, detail=decoded["error"])
        raw_text = decoded.get("generated_text", "")
    elif isinstance(decoded, list) and decoded:
        raw_text = decoded[0].get("generated_text", "")
    else:
        raise HTTPException(status_code=502, detail="Unexpected OCR format")

    if not raw_text:
        raise HTTPException(status_code=422, detail="No text detected")

    return {"rawText": raw_text.strip()}

# =========================
# TRANSCRIBE (Hugging Face)
# =========================
@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    hf_api_key = os.getenv("HF_API_KEY")
    if not hf_api_key:
        raise HTTPException(status_code=500, detail="HF_API_KEY not set")

    audio_bytes = await file.read()
    if not audio_bytes:
        raise HTTPException(status_code=400, detail="Empty audio file")

   url = "https://router.huggingface.co/hf-inference/models/openai/whisper-tiny"

    headers = {
        "Authorization": f"Bearer {hf_api_key}",
        "Content-Type": file.content_type or "application/octet-stream",
    }

    async with httpx.AsyncClient(timeout=120) as client:
        response = await client.post(url, headers=headers, content=audio_bytes)

    if response.status_code != 200:
        raise HTTPException(
            status_code=502,
            detail=f"HF Error {response.status_code}: {response.text}",
        )

    data = response.json()

    if isinstance(data, list) and len(data) > 0:
        text = data[0].get("generated_text", "")
    else:
        text = data.get("text", "")

    if not text:
        raise HTTPException(status_code=422, detail="Empty transcription")

    return {"text": text.strip()}

# =========================
# GEMINI PROXY
# =========================
@app.post("/gemini")
async def gemini_proxy(request: Request):
    body = await request.json()
    api_key = body.get("apiKey")
    prompt = body.get("prompt")

    url = f"https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key={api_key}"

    payload = {
        "contents": [{
            "parts": [{"text": prompt}]
        }]
    }

    async with httpx.AsyncClient() as client:
        response = await client.post(url, json=payload)

    return response.json()

# =========================
# START SERVER (Render)
# =========================
if __name__ == "__main__":
    import uvicorn

    port = int(os.environ.get("PORT", 10000))
    uvicorn.run("whisper_server:app", host="0.0.0.0", port=port)
