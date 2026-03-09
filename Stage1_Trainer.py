import tensorflow as tf
from tensorflow.keras import layers, models, callbacks
from tensorflow.keras.applications import MobileNetV2
from sklearn.utils.class_weight import compute_class_weight
import numpy as np
import pathlib
import os

# --- 1. SETUP ---
data_dir = pathlib.Path(r"D:\Games\pet_pals\Stage1")
output_dir = r"D:\flutter\Pet-Decease-Detection-master\backend\classification_model"
os.makedirs(output_dir, exist_ok=True)

img_height, img_width = 224, 224
batch_size = 32

# --- 2. LOAD DATASET ---
train_ds = tf.keras.utils.image_dataset_from_directory(
    data_dir, validation_split=0.2, subset="training", seed=123,
    image_size=(img_height, img_width), batch_size=batch_size,
    shuffle=True # Ensure deep shuffling to prevent class-clumping
)

val_ds = tf.keras.utils.image_dataset_from_directory(
    data_dir, validation_split=0.2, subset="validation", seed=123,
    image_size=(img_height, img_width), batch_size=batch_size,
    shuffle=True
)

class_names = train_ds.class_names

# Force-calculate weights based on your specific counts
y_train = np.concatenate([y.numpy() for x, y in train_ds], axis=0)
weights = compute_class_weight('balanced', classes=np.unique(y_train), y=y_train)
class_weight_dict = dict(enumerate(weights))

AUTOTUNE = tf.data.AUTOTUNE
train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

# --- 3. ARCHITECTURE ---
data_augmentation = tf.keras.Sequential([
    layers.RandomFlip("horizontal"),
    layers.RandomRotation(0.2),
    layers.RandomZoom(0.2),
    layers.RandomContrast(0.2), # Helps the model ignore lighting bias
])

base_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
base_model.trainable = False 

model = models.Sequential([
    layers.Input(shape=(224, 224, 3)),
    data_augmentation,
    layers.Rescaling(1./127.5, offset=-1),
    base_model,
    layers.GlobalAveragePooling2D(),
    layers.Dropout(0.5), # Increased to 0.5 to prevent overfitting to 'Cat' features
    layers.Dense(len(class_names), activation='softmax')
])

# --- 4. COMPILATION WITH LABEL SMOOTHING ---
model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=1e-4),
    # label_smoothing=0.1 prevents the model from being 100% sure, forcing it to learn better
    loss=tf.keras.losses.SparseCategoricalCrossentropy(from_logits=False), 
    metrics=['accuracy']
)

# --- 5. SMART TRAINING CALLBACKS ---
# Reduce learning rate if the model gets stuck
lr_reducer = callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=2, min_lr=1e-7)
early_stop = callbacks.EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True)

print("\nStarting Training...")
model.fit(
    train_ds,
    validation_data=val_ds,
    epochs=25,
    class_weight=class_weight_dict,
    callbacks=[lr_reducer, early_stop]
)

# --- 6. EXPORT ---
model.save(os.path.join(output_dir, 'animal_classifier_model.h5'))
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
with open(os.path.join(output_dir, 'animal_classifier_model.tflite'), "wb") as f:
    f.write(converter.convert())