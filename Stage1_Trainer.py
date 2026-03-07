import tensorflow as tf
from tensorflow.keras import layers, models
from tensorflow.keras.applications import MobileNetV2
import pathlib
import os

# 1. Setup Path and Parameters
data_dir = pathlib.Path(r"D:\Games\pet_pals\Stage1")
output_dir = r"D:\flutter\Pet-Decease-Detection-master\backend\classification_model"

# Ensure output directory exists
os.makedirs(output_dir, exist_ok=True)

img_height, img_width = 224, 224
batch_size = 32
# Increased epochs. 2 is too low for the network to adjust to your specific dataset.
epochs = 15 

# 2. Load Dataset
train_ds = tf.keras.utils.image_dataset_from_directory(
    data_dir,
    validation_split=0.2,
    subset="training",
    seed=123,
    image_size=(img_height, img_width),
    batch_size=batch_size
)

val_ds = tf.keras.utils.image_dataset_from_directory(
    data_dir,
    validation_split=0.2,
    subset="validation",
    seed=123,
    image_size=(img_height, img_width),
    batch_size=batch_size
)

class_names = train_ds.class_names

# --- CRITICAL FOR BACKEND ---
print("\n" + "="*60)
print("PASTE THIS EXACT LINE INTO app.py FOR MODEL1_LABELS:")
labels_dict = {i: name for i, name in enumerate(class_names)}
print(f"MODEL1_LABELS = {labels_dict}")
print("="*60 + "\n")

# Optimize dataset performance
AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

# 3. Data Augmentation
data_augmentation = tf.keras.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.1),
    layers.RandomZoom(0.1),
])

# 4. Build Model using Transfer Learning
base_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
base_model.trainable = False  # Freeze the pre-trained weights

model = models.Sequential([
    layers.Input(shape=(224, 224, 3)),
    data_augmentation,
    # This layer handles normalization internally! 
    # The input to this model must be raw 0-255 arrays.
    layers.Rescaling(1./127.5, offset=-1), 
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dropout(0.2), # Helps prevent overfitting
    layers.Dense(len(class_names), activation='softmax')
])

model.compile(optimizer='adam',
              loss='sparse_categorical_crossentropy',
              metrics=['accuracy'])

# 5. Train the Model
print("Starting training...")
history = model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=epochs
)

# 6. Save H5 Model
h5_path = os.path.join(output_dir, 'animal_classifier_model.h5')
model.save(h5_path)
print(f"\nSaved H5 model to: {h5_path}")

# 7. Convert and Save as TFLite
print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
tflite_model = converter.convert()

tflite_path = os.path.join(output_dir, 'animal_classifier_model.tflite')
with open(tflite_path, "wb") as f:
    f.write(tflite_model)
    
print(f"Successfully saved TFLite model to: {tflite_path}")