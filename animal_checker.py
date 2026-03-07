import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing import image

# Load model
model = tf.keras.models.load_model(r"D:\flutter\Pet-Decease-Detection-master\backend\classification_model\animal_classifier_model.h5")

# Class names (must match your training folder order)
class_names = ['Cat', 'Cow', 'Deer', 'Dog', 'Goat', 'hamster', 'Hen', 'Rabbit', 'Sheep']  # CHANGE if needed

# Image path
img_path = "test_image.jpg"

# Load image
img = image.load_img(img_path, target_size=(224, 224))
img_array = image.img_to_array(img)

# MobileNetV2 normalization
img_array = (img_array / 127.5) - 1

# Add batch dimension
img_array = np.expand_dims(img_array, axis=0)

# Predict
predictions = model.predict(img_array)

predicted_class = class_names[np.argmax(predictions)]
confidence = np.max(predictions)

print("Predicted Species:", predicted_class)
print("Confidence:", confidence)