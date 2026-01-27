import os
from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from PIL import Image
import io

app = Flask(__name__)

# Load models (Mocking for now if files don't exist)
DISEASE_MODEL_PATH = 'models/disease_model.h5'
IRRIGATION_MODEL_PATH = 'models/irrigation_model.h5'

disease_model = None
irrigation_model = None

def load_models():
    global disease_model, irrigation_model
    try:
        if os.path.exists(DISEASE_MODEL_PATH):
            disease_model = tf.keras.models.load_model(DISEASE_MODEL_PATH)
            print("Disease model loaded.")
        else:
            print("Disease model not found. Using mock.")
            
        if os.path.exists(IRRIGATION_MODEL_PATH):
            irrigation_model = tf.keras.models.load_model(IRRIGATION_MODEL_PATH)
            print("Irrigation model loaded.")
        else:
            print("Irrigation model not found. Using mock.")
    except Exception as e:
        print(f"Error loading models: {e}")

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'service': 'AgriSmart AI'}), 200

@app.route('/predict/disease', methods=['POST'])
def predict_disease():
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'}), 400
    
    file = request.files['image']
    try:
        # Preprocess image
        image = Image.open(file.stream).convert('RGB')
        image = image.resize((224, 224))
        img_array = np.array(image) / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        if disease_model:
            predictions = disease_model.predict(img_array)
            # Assuming classes: [Healthy, Rust, LeafSpot, Blight]
            classes = ['Saine', 'Rouille', 'Tache Foliaire', 'Mildiou']
            class_idx = np.argmax(predictions[0])
            confidence = float(predictions[0][class_idx])
            result = classes[class_idx]
        else:
            # Mock logic
            result = 'Mildiou'
            confidence = 0.85
        
        return jsonify({
            'disease': result,
            'confidence': confidence,
            'recommendation': get_recommendation(result)
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

def get_recommendation(disease):
    recommendations = {
        'Saine': 'Continuer la surveillance régulière.',
        'Rouille': 'Appliquer un fongicide à base de soufre.',
        'Tache Foliaire': 'Éliminer les feuilles infectées et réduire l\'humidité.',
        'Mildiou': 'Traiter avec de la bouillie bordelaise et améliorer l\'aération.'
    }
    return recommendations.get(disease, 'Consulter un agronome.')

@app.route('/predict/irrigation', methods=['POST'])
def predict_irrigation():
    data = request.json
    try:
        # Input: [temp, humidity, soil_moisture, crop_type_id]
        inputs = np.array([[
            data.get('temperature', 25),
            data.get('humidity', 60),
            data.get('soil_moisture', 50),
            data.get('crop_type', 1)
        ]])

        if irrigation_model:
            prediction = irrigation_model.predict(inputs)
            water_amount = float(prediction[0][0])
        else:
            # Mock logic based on Hargreaves formula simplified
            temp = data.get('temperature', 25)
            moisture = data.get('soil_moisture', 50)
            water_amount = max(0, (30 - moisture) * 0.5 + (temp - 20) * 0.2)
            
        return jsonify({
            'water_amount_mm': round(water_amount, 2),
            'next_irrigation': 'Demain matin' if water_amount > 5 else 'Pas nécessaire'
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

load_models()
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
