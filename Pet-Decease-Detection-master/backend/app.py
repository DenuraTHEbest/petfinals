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
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

print("\n--- 🔍 Checking Gemini API Access ---")
try:
    for m in client.models.list():
        if "generateContent" in m.supported_methods:
            print(f"✅ Available Model: {m.name}")
except Exception as e:
    print(f"❌ Could not list models: {e}")
print("------------------------------------\n")
# 2. UPDATED LABELS (Deer removed, indices shifted)
# Alphabetical order of your training folders
MODEL1_LABELS = {0: "Cat", 1: "Cow", 2: "Dog", 3: "Goat", 4: "Hen", 5: "Rabbit", 6: "Sheep"} 

CAT_DISEASE_LABELS = {0: "Dental_Disease", 1: "Eye_Infection", 2: "Fungal_Infection", 3:"normal", 4:"Panleukopenia", 5:"Scabies", 6:"Skin_Allergy"}
DOG_DISEASE_LABELS = {0: "Dental_Disease", 1: "eye_infection", 2: "Hot_Spots", 3: "Kennel_Cough", 4:"Mange", 5:"normal", 6:"Parvovirus", 7:"Skin_Allergy", 8:"Tick_Infestation"}

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
    
    # STEP 1: Identify Animal
    species_name, confidence = get_prediction(model1, input_data, MODEL1_LABELS, "Animal Classifier")
    species = species_name.lower()

    result = {"species": species_name, "confidence": confidence}

    # STEP 2: Routing Logic
    if species == "cat":
        log_event("INFO", "Routing to Internal Cat Model")
        diag, _ = get_prediction(cat_model, input_data, CAT_DISEASE_LABELS, "Cat Model")
        result.update({"analysis_source": "Internal Cat Model", "diagnosis": diag})
    
    elif species == "dog":
        log_event("INFO", "Routing to Internal Dog Model")
        diag, _ = get_prediction(dog_model, input_data, DOG_DISEASE_LABELS, "Dog Model")
        result.update({"analysis_source": "Internal Dog Model", "diagnosis": diag})
    
    else:
        # STEP 3: Gemini Fallback for Cow, Hen, Goat, Rabbit, Sheep
        log_event("GEMINI", f"Detected {species_name}. Triggering Gemini AI fallback...")
        try:
            img_pil = Image.open(io.BytesIO(image_bytes))
            prompt = f"Analyze this {species_name} for visible diseases, infections, or injuries. If it looks healthy, say 'The animal appears healthy'."
            response = client.models.generate_content(
            model="gemini-1.5-flash-latest", 
            contents=[prompt, img_pil]
)
            result.update({"analysis_source": "Gemini AI", "diagnosis": response.text})
        except Exception as e:
            log_event("ERROR", f"Gemini Error: {str(e)}")
            result.update({"analysis_source": "Error", "diagnosis": "Gemini analysis failed."})

    print("="*50)
    return result

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)