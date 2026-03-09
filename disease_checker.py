import numpy as np
import tensorflow as tf
from PIL import Image
import os

# --- 1. CONFIGURATION ---
# Labels from your folder structure screenshots
CAT_LABELS = ['Dental_Disease', 'Eye_Infection', 'Fungal_Infection', 'normal', 'Panleukopenia', 'Scabies', 'Skin_Allergy'] #
DOG_LABELS = ['Dental_Disease', 'eye_infection', 'Hot_Spots', 'Kennel_Cough', 'Mange', 'normal', 'Parvovirus', 'Skin_Allergy', 'Tick_Infestation'] #

MODEL_PATHS = {
    "cat": r"D:\flutter\Pet-Decease-Detection-master\backend\disease_models\Cat_Disease_model.tflite",
    "dog": r"D:\flutter\Pet-Decease-Detection-master\backend\disease_models\Dog_Disease_model.tflite"
}

IMG_PATH = "test_disease.jpg"

def run_tflite_inference(pet_type):
    """
    Runs inference using the TFLite interpreter for the specified pet type.
    """
    if not os.path.exists(IMG_PATH):
        print(f"❌ Error: {IMG_PATH} not found in current directory.")
        return

    # 1. Select labels and model path
    labels = DOG_LABELS if pet_type.lower() == "dog" else CAT_LABELS
    model_path = MODEL_PATHS.get(pet_type.lower())

    # 2. Load TFLite model and allocate tensors
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()

    # Get input and output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()

    # 3. Preprocess image
    # EfficientNetB0 requires (224, 224) and values in range [0, 255]
    img = Image.open(IMG_PATH).convert('RGB')
    img = img.resize((224, 224))
    img_array = np.array(img, dtype=np.float32)
    img_array = np.expand_dims(img_array, axis=0)

    # 4. Set tensor and Invoke
    interpreter.set_tensor(input_details[0]['index'], img_array)
    interpreter.invoke()

    # 5. Get results
    output_data = interpreter.get_tensor(output_details[0]['index'])[0]
    predicted_idx = np.argmax(output_data)
    
    return {
        "condition": labels[predicted_idx],
        "confidence": output_data[predicted_idx],
        "all_scores": dict(zip(labels, output_data))
    }

# --- 2. EXECUTION ---
if __name__ == "__main__":
    # Choose "dog" or "cat" based on which model you want to test
    pet = "dog" 
    
    print(f"--- Testing {pet.upper()} Disease Model ---")
    result = run_tflite_inference(pet)
    
    if result:
        print(f"Predicted Condition: {result['condition']}")
        print(f"Confidence: {result['confidence']:.2%}")
        
        # Check if the animal is healthy
        if "normal" in result['condition'].lower():
            print("Status: Patient appears healthy.")
        else:
            print("Status: Disease detected. Consult a vet.")