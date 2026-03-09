import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image

# Load model
model = tf.keras.models.load_model(r"D:\flutter\Pet-Decease-Detection-master\backend\classification_model\animal_classifier_model.h5")

# Ensure these are EXACTLY the order printed during training
class_names = ['Cat', 'Cow', 'Dog', 'Goat', 'Hen', 'Rabbit', 'Sheep'] 

img_path = "test_image.jpg"

# 1. Load image
img = image.load_img(img_path, target_size=(224, 224))
img_array = image.img_to_array(img)

# 2. Add batch dimension ONLY 
# DO NOT do the /127.5 math here! The model's Rescaling layer does it for you.
img_array = np.expand_dims(img_array, axis=0)

# 3. Predict
predictions = model.predict(img_array)

predicted_class = class_names[np.argmax(predictions)]
confidence = np.max(predictions)

print("-" * 30)
print(f"Predicted Species: {predicted_class}")
print(f"Confidence: {confidence:.2%}")
print("-" * 30)