import os
import io
import numpy as np
import tensorflow as tf
from google import genai
from fastapi import FastAPI, File, UploadFile
from PIL import Image
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# 1. INITIALIZE GEMINI (New SDK)
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

# 2. LABELS 
# IMPORTANT: If "dog" keeps appearing, check if your training 
# data folders were in this exact alphabetical order.
MODEL1_LABELS = {0: "cat", 1: "dog", 2: "cow", 3: "rabbit", 4: "hen", 5: "none"} 
CAT_DISEASE_LABELS = {0: "Healthy", 1: "Sick"}
DOG_DISEASE_LABELS = {0: "Healthy", 1: "Sick"}

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def load_interp(sub_path):
    path = os.path.join(BASE_DIR, sub_path)
    if not os.path.exists(path):
        print(f"❌ MISSING MODEL: {path}")
        return None
    interp = tf.lite.Interpreter(model_path=path)
    interp.allocate_tensors()
    return interp

model1 = load_interp(r"classification_model/animal_classifier_model.tflite")
cat_model = load_interp(r"disease_models/Cat_Disease_model.tflite")
dog_model = load_interp(r"disease_models/Dog_Disease_model.tflite")

def preprocess_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img = img.resize((224, 224))
    # Standard 0-1 normalization. 
    # Change to (np.array/127.5)-1 if using MobileNetV2 specifically.
    return np.expand_dims(np.array(img, dtype=np.float32) / 255.0, axis=0)

def get_prediction_with_logs(interpreter, input_data, labels, model_name):
    if interpreter is None: return "Missing", 0.0
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    
    probs = interpreter.get_tensor(output_details[0]['index'])[0]
    
    # --- DEBUG LOGGING START ---
    print(f"\n--- Debugging {model_name} ---")
    for i, p in enumerate(probs):
        label = labels.get(i, f"Idx {i}")
        print(f"{label}: {p*100:.2f}%")
    # --- DEBUG LOGGING END ---
    
    idx = np.argmax(probs)
    return labels.get(idx, "Unknown"), float(probs[idx])

@app.post("/analyze-pet")
async def analyze_pet(file: UploadFile = File(...)):
    image_bytes = await file.read()
    input_data = preprocess_image(image_bytes)
    
    # STEP 1: Identify Animal
    species, confidence = get_prediction_with_logs(model1, input_data, MODEL1_LABELS, "Animal Classifier")
    
    # 50% confidence threshold or "none" label
    if confidence < 0.50 or species == "none":
        return {
            "species": "Unknown",
            "diagnosis": "Animal not recognized. Support for more species coming soon!",
            "analysis_source": "System"
        }

    result = {"species": species, "confidence": confidence}

    # STEP 2: Routing Logic
    if species == "cat":
        diag, _ = get_prediction_with_logs(cat_model, input_data, CAT_DISEASE_LABELS, "Cat Model")
        result.update({"analysis_source": "Internal Cat Model", "diagnosis": diag})
    
    elif species == "dog":
        diag, _ = get_prediction_with_logs(dog_model, input_data, DOG_DISEASE_LABELS, "Dog Model")
        result.update({"analysis_source": "Internal Dog Model", "diagnosis": diag})
    
    else:
        # STEP 3: Gemini Fallback
        try:
            img_pil = Image.open(io.BytesIO(image_bytes))
            prompt = f"Analyze this {species} for diseases or injuries. If healthy, say so."
            response = client.models.generate_content(model="gemini-1.5-flash", contents=[prompt, img_pil])
            result.update({"analysis_source": "Gemini AI", "diagnosis": response.text})
        except Exception as e:
            result.update({"analysis_source": "Error", "diagnosis": f"Gemini Error: {str(e)}"})

    return result

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)