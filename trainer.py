import os
import shutil
import glob
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
from sklearn.metrics import classification_report, confusion_matrix, precision_recall_fscore_support
from sklearn.utils.class_weight import compute_class_weight

# Suppress minor warnings for cleaner output
warnings.filterwarnings('ignore')
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

# ==========================================
# 1. CONFIGURATION
# ==========================================
class Config:
    # Paths (adjust base path if needed)
    BASE_DIR = Path(r"D:\Games\pet_pals")
    STAGE1_DIR = BASE_DIR / "Stage1"
    STAGE2_DOG_DIR = BASE_DIR / "Stage2" / "stage_2_dog"
    STAGE2_CAT_DIR = BASE_DIR / "Stage2" / "stage_2_cat"
    
    # Temporary directory for flattened Stage 1 data
    TEMP_STAGE1_DIR = Path("./temp_stage1")
    
    # Output directory
    SAVE_DIR = Path("./saved_models_new")
    
    # Image & Training Settings
    IMG_SIZE = (224, 224)
    INPUT_SHAPE = (224, 224, 3)
    BATCH_SIZE = 16
    WORKERS = 1
    
    # Epochs & Learning Rates
    PHASE1_EPOCHS = 15      # Training the top head
    PHASE2_EPOCHS = 20      # Fine-tuning base model layers
    LR_PHASE1 = 1e-3
    LR_PHASE2 = 1e-4

# ==========================================
# 2. UTILITY FUNCTIONS
# ==========================================
def setup_gpu():
    """Enable memory growth for GPUs to prevent memory exhaustion."""
    gpus = tf.config.experimental.list_physical_devices('GPU')
    if gpus:
        try:
            for gpu in gpus:
                tf.config.experimental.set_memory_growth(gpu, True)
            print(f"✅ Enabled GPU memory growth for {len(gpus)} GPU(s).")
        except RuntimeError as e:
            print(f"⚠️ GPU setup error: {e}")
    else:
        print("ℹ️ No GPU found. Running on CPU.")

def clear_memory():
    """Clear Keras session and force garbage collection."""
    tf.keras.backend.clear_session()
    gc.collect()

def flatten_stage1_dataset():
    """Copies images from nested Stage1 (disease subfolders) into flat temp folders (cat/ dog/)."""
    if not Config.STAGE1_DIR.exists():
        raise FileNotFoundError(f"Stage 1 directory not found at {Config.STAGE1_DIR}")
    
    if Config.TEMP_STAGE1_DIR.exists():
        print("🧹 Cleaning up old temporary Stage 1 directory...")
        shutil.rmtree(Config.TEMP_STAGE1_DIR)
        
    os.makedirs(Config.TEMP_STAGE1_DIR / "cat", exist_ok=True)
    os.makedirs(Config.TEMP_STAGE1_DIR / "dog", exist_ok=True)
    
    print("📂 Flattening Stage 1 dataset...")
    for animal in ["cat", "dog"]:
        animal_dir = Config.STAGE1_DIR / animal
        if not animal_dir.exists():
            continue
            
        # Find all images recursively
        images = []
        for ext in ('*.jpg', '*.jpeg', '*.png'):
            images.extend(animal_dir.rglob(ext))
            
        dest_dir = Config.TEMP_STAGE1_DIR / animal
        print(f"Copying {len(images)} images for {animal}...")
        
        for img_path in tqdm(images, desc=f"{animal.capitalize()}", unit="img"):
            # Avoid naming collisions by appending parent directory name
            new_name = f"{img_path.parent.name}_{img_path.name}"
            shutil.copy(img_path, dest_dir / new_name)
            
    print("✅ Stage 1 dataset flattened successfully.\n")

def check_stage2_data(path):
    """Checks if Stage 2 directory exists and contains data."""
    if not path.exists():
        return False
    # Check if there are any subdirectories with images
    subdirs = [d for d in path.iterdir() if d.is_dir()]
    if not subdirs:
        return False
    
    img_count = sum(1 for _ in path.rglob('*.[jp][pn][gG]')) # matches jpg, png, jpeg
    return img_count > 0

# ==========================================
# 3. DATA & MODEL PIPELINE
# ==========================================
class ModelPipeline:
    def __init__(self, task_name, data_dir, num_classes, class_mode):
        self.task_name = task_name
        self.data_dir = data_dir
        self.num_classes = num_classes
        self.class_mode = class_mode
        self.model_path = str(Config.SAVE_DIR / f"{task_name}_model.h5")
        
        Config.SAVE_DIR.mkdir(parents=True, exist_ok=True)
        
    def prepare_data(self):
        """Prepare train and validation generators with augmentation."""
        train_datagen = ImageDataGenerator(
            validation_split=0.2,
            rotation_range=20,
            width_shift_range=0.2,
            height_shift_range=0.2,
            shear_range=0.15,
            zoom_range=0.15,
            horizontal_flip=True,
            fill_mode='nearest',
            brightness_range=[0.8, 1.2]
            # EfficientNet expects unscaled inputs, it handles normalization internally.
        )
        
        test_datagen = ImageDataGenerator(validation_split=0.2)
        
        self.train_gen = train_datagen.flow_from_directory(
            self.data_dir,
            target_size=Config.IMG_SIZE,
            batch_size=Config.BATCH_SIZE,
            class_mode=self.class_mode,
            subset='training',
            shuffle=True
        )
        
        self.val_gen = test_datagen.flow_from_directory(
            self.data_dir,
            target_size=Config.IMG_SIZE,
            batch_size=Config.BATCH_SIZE,
            class_mode=self.class_mode,
            subset='validation',
            shuffle=False
        )
        
        # Compute class weights to handle imbalance
        labels = self.train_gen.classes
        classes = np.unique(labels)
        weights = compute_class_weight('balanced', classes=classes, y=labels)
        self.class_weights = dict(zip(classes, weights))
        print(f"⚖️ Computed Class Weights for {self.task_name}: {self.class_weights}")

        # Save class indices for inference
        self.class_indices = {v: k for k, v in self.train_gen.class_indices.items()}

    def build_model(self):
        """Builds EfficientNetB0 with custom top layers."""
        # 
        base_model = tf.keras.applications.EfficientNetB0(
            weights='imagenet',
            include_top=False,
            input_shape=Config.INPUT_SHAPE
        )
        base_model.trainable = False  # Freeze base model initially
        
        inputs = layers.Input(shape=Config.INPUT_SHAPE)
        x = base_model(inputs, training=False)
        x = layers.GlobalAveragePooling2D()(x)
        x = layers.BatchNormalization()(x)
        x = layers.Dropout(0.4)(x)
        x = layers.Dense(128, activation='relu')(x)
        x = layers.Dropout(0.3)(x)
        
        if self.class_mode == 'binary':
            outputs = layers.Dense(1, activation='sigmoid')(x)
            loss = 'binary_crossentropy'
            metrics = ['accuracy', tf.keras.metrics.Precision(name='precision'), tf.keras.metrics.Recall(name='recall')]
        else:
            outputs = layers.Dense(self.num_classes, activation='softmax')(x)
            loss = 'categorical_crossentropy'
            metrics = ['accuracy', tf.keras.metrics.Precision(name='precision'), tf.keras.metrics.Recall(name='recall')]
            
        self.model = models.Model(inputs, outputs)
        self.base_model = base_model
        
        self.model.compile(
            optimizer=optimizers.Adam(learning_rate=Config.LR_PHASE1),
            loss=loss,
            metrics=metrics
        )
        
    def train(self):
        """Executes two-phase training."""
        self.prepare_data()
        self.build_model()
        
        callbacks_list = [
            callbacks.EarlyStopping(monitor='val_loss', patience=5, restore_best_weights=True, verbose=1),
            callbacks.ReduceLROnPlateau(monitor='val_loss', factor=0.5, patience=3, min_lr=1e-6, verbose=1),
            callbacks.ModelCheckpoint(self.model_path, monitor='val_accuracy', save_best_only=True, verbose=1)
        ]
        
        print(f"\n🚀 --- PHASE 1: Training Top Layers ({self.task_name}) ---")
        history_p1 = self.model.fit(
            self.train_gen,
            validation_data=self.val_gen,
            epochs=Config.PHASE1_EPOCHS,
            class_weight=self.class_weights,
            callbacks=callbacks_list,
            workers=Config.WORKERS
        )
        
        print(f"\n🚀 --- PHASE 2: Fine-Tuning Base Model ({self.task_name}) ---")
        self.base_model.trainable = True
        
        # Freeze the bottom 100 layers and unfreeze the rest
        for layer in self.base_model.layers[:100]:
            layer.trainable = False
            
        if self.class_mode == 'binary':
            new_metrics = ['accuracy', tf.keras.metrics.Precision(name='precision'), tf.keras.metrics.Recall(name='recall')]
        else:
            new_metrics = ['accuracy', tf.keras.metrics.Precision(name='precision'), tf.keras.metrics.Recall(name='recall')]

        self.model.compile(
            optimizer=optimizers.Adam(learning_rate=Config.LR_PHASE2),
            loss=self.model.loss,
            metrics=new_metrics
        )
        
        history_p2 = self.model.fit(
            self.train_gen,
            validation_data=self.val_gen,
            epochs=Config.PHASE2_EPOCHS,
            class_weight=self.class_weights,
            callbacks=callbacks_list,
            workers=Config.WORKERS,
            sample_weight=None
        )
        
        self.evaluate(history_p1, history_p2)

    def evaluate(self, hist1, hist2):
        """Generates plots and evaluation metrics."""
        print(f"\n📊 Evaluating {self.task_name}...")
        
        # Combine histories
        acc = hist1.history['accuracy'] + hist2.history['accuracy']
        val_acc = hist1.history['val_accuracy'] + hist2.history['val_accuracy']
        loss = hist1.history['loss'] + hist2.history['loss']
        val_loss = hist1.history['val_loss'] + hist2.history['val_loss']
        
        # Plot Training Curves 
        plt.figure(figsize=(12, 4))
        plt.subplot(1, 2, 1)
        plt.plot(acc, label='Train Acc')
        plt.plot(val_acc, label='Val Acc')
        plt.axvline(x=Config.PHASE1_EPOCHS-1, color='r', linestyle='--', label='Fine-tune start')
        plt.title(f'{self.task_name} Accuracy')
        plt.legend()
        
        plt.subplot(1, 2, 2)
        plt.plot(loss, label='Train Loss')
        plt.plot(val_loss, label='Val Loss')
        plt.axvline(x=Config.PHASE1_EPOCHS-1, color='r', linestyle='--', label='Fine-tune start')
        plt.title(f'{self.task_name} Loss')
        plt.legend()
        plt.savefig(Config.SAVE_DIR / f"{self.task_name}_curves.png")
        plt.close()
        
        # Predictions and Confusion Matrix
        self.val_gen.reset()
        preds = self.model.predict(self.val_gen, workers=Config.WORKERS)
        y_pred = (preds > 0.5).astype(int).flatten() if self.class_mode == 'binary' else np.argmax(preds, axis=1)
        y_true = self.val_gen.classes
        
        cm = confusion_matrix(y_true, y_pred)
        plt.figure(figsize=(10, 8))
        sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                    xticklabels=self.class_indices.values(), 
                    yticklabels=self.class_indices.values())
        plt.title(f'{self.task_name} Confusion Matrix')
        plt.ylabel('True')
        plt.xlabel('Predicted')
        plt.savefig(Config.SAVE_DIR / f"{self.task_name}_cm.png")
        plt.close()
        
        # Classification Report
        report = classification_report(y_true, y_pred, target_names=list(self.class_indices.values()))
        with open(Config.SAVE_DIR / f"{self.task_name}_report.txt", "w") as f:
            f.write(report)
            f.write("\n\nClass Indices:\n")
            f.write(str(self.class_indices))
            
        print(f"✅ Evaluation artifacts saved for {self.task_name}.")
        clear_memory()

# ==========================================
# 4. INFERENCE SYSTEM
# ==========================================
class PetHealthInferenceSystem:
    def __init__(self):
        self.stage1_model = None
        self.dog_model = None
        self.cat_model = None
        
        # Expected paths
        s1_path = Config.SAVE_DIR / "Stage1_Animal_model.h5"
        dog_path = Config.SAVE_DIR / "Stage2_Dog_Disease_model.h5"
        cat_path = Config.SAVE_DIR / "Stage2_Cat_Disease_model.h5"
        
        if s1_path.exists():
            self.stage1_model = tf.keras.models.load_model(s1_path)
            
        if dog_path.exists():
            self.dog_model = tf.keras.models.load_model(dog_path)
            
        if cat_path.exists():
            self.cat_model = tf.keras.models.load_model(cat_path)

    def predict(self, img_path):
        if not self.stage1_model:
            return "Stage 1 model not loaded. Train the system first."
            
        img = tf.keras.preprocessing.image.load_img(img_path, target_size=Config.IMG_SIZE)
        img_array = tf.keras.preprocessing.image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0) # EfficientNet handles standard scaling
        
        # Stage 1: Cat vs Dog (Assuming 0=Cat, 1=Dog based on binary generator defaults)
        s1_pred = self.stage1_model.predict(img_array, verbose=0)[0][0]
        animal = "Dog" if s1_pred > 0.5 else "Cat"
        s1_conf = s1_pred if animal == "Dog" else 1 - s1_pred
        
        result = f"Stage 1 Prediction: {animal} (Confidence: {s1_conf:.2%})\n"
        
        # Stage 2: Disease
        if animal == "Dog" and self.dog_model:
            d_pred = self.dog_model.predict(img_array, verbose=0)[0]
            class_idx = np.argmax(d_pred)
            result += f"Stage 2 Prediction: Disease Class Index {class_idx} (Confidence: {d_pred[class_idx]:.2%})"
        elif animal == "Cat" and self.cat_model:
            c_pred = self.cat_model.predict(img_array, verbose=0)[0]
            class_idx = np.argmax(c_pred)
            result += f"Stage 2 Prediction: Disease Class Index {class_idx} (Confidence: {c_pred[class_idx]:.2%})"
        else:
            result += f"Stage 2 Prediction: Model for {animal} diseases not found/trained."
            
        return result

# ==========================================
# 5. MAIN MENU EXECUTION
# ==========================================
def main():
    setup_gpu()
    
    while True:
        print("\n" + "="*40)
        print("🐾 Pet Health Detection System Pipeline")
        print("="*40)
        print("1. Train Stage 1 (Cat vs Dog)")
        print("2. Train Stage 2 (Dog Diseases)")
        print("3. Train Stage 2 (Cat Diseases)")
        print("4. Train All Available Stages")
        print("5. Run Inference on an Image")
        print("6. Exit")
        
        choice = input("Enter your choice (1-6): ").strip()
        
        if choice in ['1', '4']:
            flatten_stage1_dataset()
            pipeline = ModelPipeline("Stage1_Animal", Config.TEMP_STAGE1_DIR, num_classes=2, class_mode='binary')
            pipeline.train()
            
        if choice in ['2', '4']:
            if check_stage2_data(Config.STAGE2_DOG_DIR):
                num_classes = len([d for d in Config.STAGE2_DOG_DIR.iterdir() if d.is_dir()])
                pipeline = ModelPipeline("Stage2_Dog_Disease", Config.STAGE2_DOG_DIR, num_classes=num_classes, class_mode='categorical')
                pipeline.train()
            else:
                print(f"⚠️ Skipping Stage 2 Dog: Directory {Config.STAGE2_DOG_DIR} is missing or empty.")
                
        if choice in ['3', '4']:
            if check_stage2_data(Config.STAGE2_CAT_DIR):
                num_classes = len([d for d in Config.STAGE2_CAT_DIR.iterdir() if d.is_dir()])
                pipeline = ModelPipeline("Stage2_Cat_Disease", Config.STAGE2_CAT_DIR, num_classes=num_classes, class_mode='categorical')
                pipeline.train()
            else:
                print(f"⚠️ Skipping Stage 2 Cat: Directory {Config.STAGE2_CAT_DIR} is missing or empty.")
                
        if choice == '5':
            img_path = input("Enter the full path to the image for inference: ").strip()
            # Handle potential quotes in windows paths
            img_path = img_path.replace('"', '').replace("'", "") 
            if os.path.exists(img_path):
                system = PetHealthInferenceSystem()
                print("\n--- Inference Results ---")
                print(system.predict(img_path))
            else:
                print("❌ Image path not found.")
                
        if choice == '6':
            print("Exiting system. Goodbye! 👋")
            break

if __name__ == "__main__":
    main()