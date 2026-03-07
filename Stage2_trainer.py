import os
import gc
import warnings
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from tqdm import tqdm

import tensorflow as tf
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras import layers, models, callbacks, optimizers
from sklearn.metrics import classification_report, confusion_matrix
from sklearn.utils.class_weight import compute_class_weight

# Suppress minor warnings
warnings.filterwarnings('ignore')
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

# ==========================================
# 1. CONFIGURATION
# ==========================================
class Config:
    BASE_DIR = Path(r"D:\Games\pet_pals")
    # Focus only on Stage 2 (Diseases)
    STAGE2_DOG_DIR = BASE_DIR / "Stage2" / "stage_2_dog"
    STAGE2_CAT_DIR = BASE_DIR / "Stage2" / "stage_2_cat"
    
    SAVE_DIR = Path("./disease_models")
    
    IMG_SIZE = (224, 224)
    INPUT_SHAPE = (224, 224, 3)
    BATCH_SIZE = 16
    
    PHASE1_EPOCHS = 50
    PHASE2_EPOCHS = 30  # Fine-tuning
    LR_PHASE1 = 1e-4
    LR_PHASE2 = 1e-5 # Lowered for safer fine-tuning

# ==========================================
# 2. UTILITY FUNCTIONS
# ==========================================
def setup_gpu():
    gpus = tf.config.experimental.list_physical_devices('GPU')
    if gpus:
        try:
            for gpu in gpus:
                tf.config.experimental.set_memory_growth(gpu, True)
            print(f"✅ GPU ready.")
        except RuntimeError as e:
            print(f"⚠️ GPU error: {e}")

def clear_memory():
    tf.keras.backend.clear_session()
    gc.collect()

# ==========================================
# 3. TRAINING ENGINE
# ==========================================
class DiseaseModelPipeline:
    def __init__(self, task_name, data_dir):
        self.task_name = task_name
        self.data_dir = data_dir
        self.model_path = str(Config.SAVE_DIR / f"{task_name}_model.h5")
        Config.SAVE_DIR.mkdir(parents=True, exist_ok=True)
        
    def prepare_data(self):
        # Augmentation specifically for medical/disease visual cues
        datagen = ImageDataGenerator(
        validation_split=0.2,
        rotation_range=30,      # Increased for disease textures
        width_shift_range=0.2,
        height_shift_range=0.2,
        shear_range=0.2,        # Added shear
        zoom_range=0.2,         # Added zoom
        horizontal_flip=True,
        fill_mode='nearest'
    )
    
        self.train_gen = datagen.flow_from_directory(
            self.data_dir,
            target_size=Config.IMG_SIZE,
            batch_size=Config.BATCH_SIZE,
            class_mode='categorical',
            subset='training',
            shuffle=True
        )
        
        self.val_gen = datagen.flow_from_directory(
            self.data_dir,
            target_size=Config.IMG_SIZE,
            batch_size=Config.BATCH_SIZE,
            class_mode='categorical',
            subset='validation',
            shuffle=False
        )

        self.num_classes = len(self.train_gen.class_indices)
        self.class_indices = {v: k for k, v in self.train_gen.class_indices.items()}
        
        # Balance weights in case one disease has fewer images
        labels = self.train_gen.classes
        weights = compute_class_weight('balanced', classes=np.unique(labels), y=labels)
        self.class_weights = dict(zip(np.unique(labels), weights))

    def build_model(self):
        # Using EfficientNetB0 for high accuracy on textures (skin/fur diseases)
        base_model = tf.keras.applications.EfficientNetB0(
            weights='imagenet', include_top=False, input_shape=Config.INPUT_SHAPE
        )
        base_model.trainable = False 
        
        inputs = layers.Input(shape=Config.INPUT_SHAPE)
        x = base_model(inputs, training=False)
        x = layers.GlobalAveragePooling2D()(x)
        x = layers.Dropout(0.4)(x)
        outputs = layers.Dense(self.num_classes, activation='softmax')(x)
        
        self.model = models.Model(inputs, outputs)
        self.base_model = base_model
        self.model.compile(
            optimizer=optimizers.Adam(learning_rate=Config.LR_PHASE1),
            loss='categorical_crossentropy',
            metrics=['accuracy']
        )

    def train(self):
        self.prepare_data()
        self.build_model()
        
        cb = [
            callbacks.EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True),
            callbacks.ModelCheckpoint(self.model_path, monitor='val_accuracy', save_best_only=True)
        ]

        print(f"\n🔥 Training {self.task_name}...")
        # Phase 1: Top layers
        self.model.fit(self.train_gen, validation_data=self.val_gen, 
                       epochs=Config.PHASE1_EPOCHS, class_weight=self.class_weights, callbacks=cb)
        
        # Phase 2: Fine-Tuning
        print(f"\n🌀 Fine-tuning {self.task_name}...")
        self.base_model.trainable = True
        self.model.compile(optimizer=optimizers.Adam(Config.LR_PHASE2), loss='categorical_crossentropy', metrics=['accuracy'])
        self.model.fit(self.train_gen, validation_data=self.val_gen, 
                       epochs=Config.PHASE2_EPOCHS, class_weight=self.class_weights, callbacks=cb)
        
        print(f"✅ {self.task_name} training complete. Model saved.")
        clear_memory()

# ==========================================
# 4. EXECUTION
# ==========================================
def main():
    setup_gpu()
    
    while True:
        print("\n" + "="*40)
        print("🐾 Pet Disease Detection Trainer")
        print("="*40)
        print("1. Train Dog Disease Model")
        print("2. Train Cat Disease Model")
        print("3. Train Both")
        print("4. Exit")
        
        choice = input("Select option: ")
        
        if choice in ['1', '3']:
            if Config.STAGE2_DOG_DIR.exists():
                trainer = DiseaseModelPipeline("Dog_Disease", Config.STAGE2_DOG_DIR)
                trainer.train()
            else:
                print("❌ Dog directory not found!")

        if choice in ['2', '3']:
            if Config.STAGE2_CAT_DIR.exists():
                trainer = DiseaseModelPipeline("Cat_Disease", Config.STAGE2_CAT_DIR)
                trainer.train()
            else:
                print("❌ Cat directory not found!")
                
        if choice == '4':
            break

if __name__ == "__main__":
    main()