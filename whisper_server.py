from fastapi import FastAPI, File, UploadFile, HTTPException
from fastapi.middleware.cors import CORSMiddleware
import httpx
import whisper
import tempfile
import os
import shutil
import json
import urllib.error
import urllib.request
from fastapi import FastAPI, File, UploadFile, Request

app = FastAPI(title="Local Whisper Server")
model = whisper.load_model("base")
HF_OCR_ENDPOINTS = [
    "https://router.huggingface.co/hf-inference/models/microsoft/trocr-large-printed",
    "https://api-inference.huggingface.co/models/microsoft/trocr-large-printed",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost", "http://127.0.0.1"],
    allow_origin_regex=r"http://(localhost|127\.0\.0\.1)(:\d+)?$",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
async def health():
    ffmpeg_path = shutil.which("ffmpeg")
    return {
        "ok": True,
        "ffmpegFound": ffmpeg_path is not None,
        "ffmpegPath": ffmpeg_path,
        "hfApiConfigured": bool(os.getenv("HF_API_KEY", "").strip()),
    }


@app.post("/ocr")
async def ocr(file: UploadFile = File(...)):
    hf_api_key = os.getenv("HF_API_KEY", "").strip()
    if not hf_api_key:
        raise HTTPException(
            status_code=500,
            detail=(
                "HF_API_KEY is not configured on the server. "
                "Set environment variable HF_API_KEY before starting whisper_server.py."
            ),
        )

    image_bytes = await file.read()
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Uploaded image is empty.")

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
            lower_body = body.lower()
            if exc.code == 404 or "cannot post /models/" in lower_body:
                last_error = f"Hugging Face OCR endpoint not found ({endpoint})."
                continue
            raise HTTPException(
                status_code=502,
                detail=f"Hugging Face OCR error {exc.code}: {body}",
            )
        except urllib.error.URLError as exc:
            last_error = f"Failed to reach Hugging Face OCR via {endpoint}: {exc.reason}"
            continue
        except Exception as exc:
            raise HTTPException(status_code=500, detail=f"OCR proxy failed: {exc}")

    if payload is None:
        raise HTTPException(
            status_code=502,
            detail=last_error or "Failed to reach any Hugging Face OCR endpoint.",
        )

    try:
        decoded = json.loads(payload)
    except json.JSONDecodeError:
        raise HTTPException(status_code=502, detail="Invalid OCR response payload.")

    if isinstance(decoded, dict):
        if decoded.get("error"):
            estimated = decoded.get("estimated_time")
            suffix = f" Try again in {estimated}s." if estimated is not None else ""
            raise HTTPException(
                status_code=502,
                detail=f"Hugging Face OCR error: {decoded['error']}{suffix}",
            )
        raw_text = str(decoded.get("generated_text", "")).strip()
    elif isinstance(decoded, list) and decoded and isinstance(decoded[0], dict):
        raw_text = str(decoded[0].get("generated_text", "")).strip()
    else:
        raise HTTPException(status_code=502, detail="Unexpected OCR response format.")

    if not raw_text:
        raise HTTPException(status_code=422, detail="No text detected in image.")

    return {"rawText": raw_text}


@app.post("/transcribe")
async def transcribe(file: UploadFile = File(...)):
    try:
        suffix = os.path.splitext(file.filename or "audio.wav")[1] or ".wav"
        with tempfile.NamedTemporaryFile(delete=False, suffix=suffix) as tmp:
            tmp.write(await file.read())
            temp_path = tmp.name

        result = model.transcribe(temp_path)
        text = (result.get("text") or "").strip()
        return {"text": text}
    except Exception as exc:
        message = str(exc)
        if isinstance(exc, FileNotFoundError) or "[WinError 2]" in message:
            raise HTTPException(
                status_code=500,
                detail=(
                    "Transcription failed: ffmpeg is not installed or not in PATH. "
                    "Install ffmpeg and restart terminal/server. "
                    "Windows: winget install Gyan.FFmpeg"
                ),
            )
        raise HTTPException(status_code=500, detail=f"Transcription failed: {exc}")
    finally:
        try:
            if "temp_path" in locals() and os.path.exists(temp_path):
                os.remove(temp_path)
        except Exception:
            pass

@app.post("/gemini")
async def gemini_proxy(request: Request):
    body = await request.json()
    api_key = body.get("apiKey")
    prompt = body.get("prompt")
    
    headers = {"Content-Type": "application/json"}
    payload = {
        "contents": [{
            "parts": [{"text": prompt}]
        }]
    }
    
    url = f"https://generativelanguage.googleapis.com/v1/models/gemini-1.5-flash:generateContent?key={api_key}"
    
    async with httpx.AsyncClient() as client:
        response = await client.post(url, headers=headers, json=payload)
        return response.json()

if __name__ == "__main__":
    import uvicorn

    uvicorn.run("whisper_server:app", host="127.0.0.1", port=8000, reload=False)
