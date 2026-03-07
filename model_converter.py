import tensorflow as tf
import os

cat_Disease_model = r"D:\Games\pet_pals\disease_models\Cat_Disease_model.h5"
dog_Disease_model = r"D:\Games\pet_pals\disease_models\Dog_Disease_model.h5"

model_array = [cat_Disease_model, dog_Disease_model]

for model_path in model_array:

    print(f"Loading model: {model_path}")

    model = tf.keras.models.load_model(model_path)

    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    tflite_model = converter.convert()

    # Get base path without extension
    base_path = os.path.splitext(model_path)[0]

    # Create .tflite path in same directory
    output_path = base_path + ".tflite"

    with open(output_path, "wb") as f:
        f.write(tflite_model)

    print(f"Conversion complete: {output_path}")