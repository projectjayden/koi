# this file is primarly used for routing

from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional
import uvicorn
from T5ModelHandler import T5ModelHandler
from contextlib import asynccontextmanager

model_handler = T5ModelHandler() # this loads the models, handles token conversion of inputs and outputs

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("Starting up - loading model...")
    model_handler.load_model()
    print(f"Model loaded: {model_handler.is_loaded()}")
    yield
    # Shutdown (if needed)
    print("Shutting down...")

app = FastAPI(title="T5 ML Service", version="1.0.0", lifespan=lifespan) # builds a T5 api

# input text
class GenerateRequest(BaseModel):
    input_text: str
    max_length: Optional[int] = 512
    temperature: Optional[float] = 0.7

# output text
class GenerateResponse(BaseModel):
    generated_text: str

@app.get("/health") # make sures the model is loaded
async def health_check():
    return {"status": "healthy", "model_loaded": model_handler.is_loaded()}

@app.post("/generate", response_model=GenerateResponse) # sends out the response
async def generate_text(request: GenerateRequest): # takes in the request
    try:
        if not model_handler.is_loaded():
            raise HTTPException(status_code=503, detail="Model not loaded")
        
        generated_text = model_handler.generate(
            input_text=request.input_text,
            max_length=request.max_length,
            temperature=request.temperature
        )
        
        return GenerateResponse(
            generated_text=generated_text
        )
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Generation failed: {str(e)}")

@app.get("/")
async def root():
    return {"message": "T5 ML Service is running"}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8001)