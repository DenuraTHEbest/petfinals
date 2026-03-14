import os
import io
import datetime
import numpy as np
import tensorflow as tf
from google import genai
from fastapi import FastAPI, File, UploadFile
from PIL import Image
from dotenv import load_dotenv

load_dotenv()

app = FastAPI()

# 1. INITIALIZE GEMINI
client = genai.Client(
    api_key=os.getenv("GEMINI_API_KEY"),
    http_options={'api_version': 'v1'}
)

# Updated Diagnostic Block
print("\n--- 🔍 Checking Gemini API Access ---")
try:
    for m in client.models.list():
        # We removed the method filter so we can see every single model name
        print(f"✅ Found Model: {m.name}")
except Exception as e:
    print(f"❌ Gemini Access Check Failed: {e}")
print("------------------------------------\n")

# 2. UPDATED LABELS (Cleaned up formatting to remove underscores and capitalize)
MODEL1_LABELS = {0: "Cat", 1: "Cow", 2: "Dog", 3: "Goat", 4: "Hen", 5: "Rabbit", 6: "Sheep"} 

CAT_DISEASE_LABELS = {
    0: "Dental Disease", 
    1: "Eye Infection", 
    2: "Fungal Infection", 
    3: "Normal", 
    4: "Panleukopenia", 
    5: "Scabies", 
    6: "Skin Allergy"
}

DOG_DISEASE_LABELS = {
    0: "Dental Disease", 
    1: "Eye Infection", 
    2: "Hot Spots", 
    3: "Kennel Cough", 
    4: "Mange", 
    5: "Normal", 
    6: "Parvovirus", 
    7: "Skin Allergy", 
    8: "Tick Infestation"
}

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def log_event(event_type, message):
    timestamp = datetime.datetime.now().strftime("%H:%M:%S")
    icons = {"START": "🚀", "MODEL": "🧠", "GEMINI": "✨", "SUCCESS": "✅", "ERROR": "❌", "INFO": "ℹ️"}
    icon = icons.get(event_type, "🔹")
    print(f"[{timestamp}] {icon} {event_type:8} | {message}")

def load_interp(sub_path):
    path = os.path.join(BASE_DIR, sub_path)
    if not os.path.exists(path):
        log_event("ERROR", f"Missing model: {path}")
        return None
    interp = tf.lite.Interpreter(model_path=path)
    interp.allocate_tensors()
    log_event("SUCCESS", f"Loaded: {os.path.basename(sub_path)}")
    return interp

model1 = load_interp(r"classification_model/animal_classifier_model.tflite")
cat_model = load_interp(r"disease_models/Cat_Disease_model.tflite")
dog_model = load_interp(r"disease_models/Dog_Disease_model.tflite")

def preprocess_image(image_bytes):
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img = img.resize((224, 224))
    # FIX: Removed the / 255.0. 
    # Your models expect values in the 0-255 range.
    return np.expand_dims(np.array(img, dtype=np.float32), axis=0)

def get_prediction(interpreter, input_data, labels, model_name):
    if interpreter is None: return "Missing", 0.0
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    interpreter.set_tensor(input_details[0]['index'], input_data)
    interpreter.invoke()
    
    probs = interpreter.get_tensor(output_details[0]['index'])[0]
    idx = np.argmax(probs)
    
    result_label = labels.get(idx, f"Unknown_Idx_{idx}")
    confidence = float(probs[idx])
    
    log_event("SUCCESS", f"{model_name} Result: {result_label} ({confidence*100:.1f}%)")
    return result_label, confidence

@app.post("/analyze-pet")
async def analyze_pet(file: UploadFile = File(...)):
    print("\n" + "="*50)
    log_event("START", f"New Request: {file.filename}")
    
    image_bytes = await file.read()
    input_data = preprocess_image(image_bytes)
    
    # STEP 1: Identify Animal using your TFLite model
    species_name, confidence = get_prediction(model1, input_data, MODEL1_LABELS, "Animal Classifier")
    species = species_name.lower()

    # Pre-set the result dictionary
    result = {"species": species_name, "confidence": confidence}

    # STEP 2: Routing Logic
    if species == "cat":
        log_event("INFO", "Routing to Internal Cat Model")
        diag, _ = get_prediction(cat_model, input_data, CAT_DISEASE_LABELS, "Cat Model")
        result.update({"diagnosis": diag})
    
    elif species == "dog":
        log_event("INFO", "Routing to Internal Dog Model")
        diag, _ = get_prediction(dog_model, input_data, DOG_DISEASE_LABELS, "Dog Model")
        result.update({"diagnosis": diag})
    
    else:
        # STEP 3: Gemini Fallback for other animals OR Unknown Animals
        log_event("GEMINI", f"Detected {species_name}. Triggering Gemini AI fallback...")
        try:
            img_pil = Image.open(io.BytesIO(image_bytes))
            
            # THE UPGRADED PROMPT
            prompt = f"""
            You are an expert veterinarian. 
            1. First, identify if this animal is a Cow, Goat, Hen, Rabbit, or Sheep.
            2. If it IS one of those, identify the single most likely visible disease or say 'Normal'. 
               Reply ONLY with the condition name (e.g., 'Fowl Pox').
            3. If the animal is NOT a Cat, Cow, Dog, Goat, Hen, Rabbit, or Sheep:
               Reply EXACTLY with this message: 'The data for this species will be updated in an upcoming version. Thank you for your patience as we expand our care capabilities.'
            4. Do not include any other text, punctuation, or explanations.
            """
            
            response = client.models.generate_content(
                model="gemini-2.5-flash-lite", 
                contents=[prompt, img_pil]
            )
            
            clean_diagnosis = response.text.strip()
            result.update({"diagnosis": clean_diagnosis})
            
        except Exception as e:
            log_event("ERROR", f"Gemini Error: {str(e)}")
            result.update({"diagnosis": "Analysis service is temporarily unavailable. Please try again later."})

    print("="*50)
    return result

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)