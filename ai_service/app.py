import os
import logging
from flask import Flask, request, jsonify
import numpy as np
import tensorflow as tf
from PIL import Image

# =====================================================
# Configuration du logging structuré
# =====================================================
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(name)s: %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger('ai_service')

app = Flask(__name__)

# =====================================================
# Configuration & Constantes
# =====================================================
MAX_IMAGE_SIZE = 10 * 1024 * 1024  # 10 MB
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp'}
DISEASE_CLASSES = ['Saine', 'Rouille', 'Tache Foliaire', 'Mildiou']
DISEASE_MODEL_PATH = 'models/disease_model.h5'
IRRIGATION_MODEL_PATH = 'models/irrigation_model.h5'

disease_model = None
irrigation_model = None


# =====================================================
# Chargement des modèles
# =====================================================
def load_models():
    global disease_model, irrigation_model
    try:
        if os.path.exists(DISEASE_MODEL_PATH):
            disease_model = tf.keras.models.load_model(DISEASE_MODEL_PATH)
            logger.info('Disease model loaded from %s', DISEASE_MODEL_PATH)
        else:
            logger.warning('Disease model not found at %s — using mock predictions', DISEASE_MODEL_PATH)

        if os.path.exists(IRRIGATION_MODEL_PATH):
            irrigation_model = tf.keras.models.load_model(IRRIGATION_MODEL_PATH)
            logger.info('Irrigation model loaded from %s', IRRIGATION_MODEL_PATH)
        else:
            logger.warning('Irrigation model not found at %s — using mock predictions', IRRIGATION_MODEL_PATH)
    except Exception as e:
        logger.error('Failed to load models: %s', e, exc_info=True)


# =====================================================
# Validation helpers
# =====================================================
def allowed_file(filename: str) -> bool:
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


def validate_irrigation_input(data: dict) -> list[str]:
    """Validate irrigation prediction inputs, return list of errors."""
    errors = []
    if data is None:
        return ['Request body must be valid JSON']

    temp = data.get('temperature')
    if temp is not None:
        if not isinstance(temp, (int, float)) or temp < -50 or temp > 70:
            errors.append('temperature must be a number between -50 and 70')

    humidity = data.get('humidity')
    if humidity is not None:
        if not isinstance(humidity, (int, float)) or humidity < 0 or humidity > 100:
            errors.append('humidity must be a number between 0 and 100')

    soil_moisture = data.get('soil_moisture')
    if soil_moisture is not None:
        if not isinstance(soil_moisture, (int, float)) or soil_moisture < 0 or soil_moisture > 100:
            errors.append('soil_moisture must be a number between 0 and 100')

    crop_type = data.get('crop_type')
    if crop_type is not None:
        if not isinstance(crop_type, int) or crop_type < 0:
            errors.append('crop_type must be a non-negative integer')

    return errors


def get_recommendation(disease: str) -> str:
    recommendations = {
        'Saine': 'Continuer la surveillance régulière.',
        'Rouille': 'Appliquer un fongicide à base de soufre.',
        'Tache Foliaire': 'Éliminer les feuilles infectées et réduire l\'humidité.',
        'Mildiou': 'Traiter avec de la bouillie bordelaise et améliorer l\'aération.',
    }
    return recommendations.get(disease, 'Consulter un agronome.')


# =====================================================
# Routes
# =====================================================
@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({
        'status': 'healthy',
        'service': 'AgroSmart AI',
        'models': {
            'disease': 'loaded' if disease_model else 'mock',
            'irrigation': 'loaded' if irrigation_model else 'mock',
        },
    }), 200


@app.route('/predict/disease', methods=['POST'])
def predict_disease():
    # --- Validate file presence ---
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided. Send a file with key "image".'}), 400

    file = request.files['image']

    if file.filename == '':
        return jsonify({'error': 'Empty filename'}), 400

    if not allowed_file(file.filename):
        return jsonify({
            'error': f'Invalid file type. Allowed: {", ".join(ALLOWED_EXTENSIONS)}'
        }), 400

    # --- Validate file size ---
    file.seek(0, 2)
    file_size = file.tell()
    file.seek(0)
    if file_size > MAX_IMAGE_SIZE:
        return jsonify({'error': f'File too large. Maximum: {MAX_IMAGE_SIZE // (1024 * 1024)} MB'}), 400

    try:
        image = Image.open(file.stream).convert('RGB')
        image = image.resize((224, 224))
        img_array = np.array(image) / 255.0
        img_array = np.expand_dims(img_array, axis=0)

        if disease_model:
            predictions = disease_model.predict(img_array)
            class_idx = np.argmax(predictions[0])
            confidence = float(predictions[0][class_idx])
            result = DISEASE_CLASSES[class_idx]
        else:
            # Mock prediction
            result = 'Mildiou'
            confidence = 0.85

        logger.info('Disease prediction: %s (confidence: %.2f)', result, confidence)

        return jsonify({
            'disease': result,
            'confidence': round(confidence, 4),
            'recommendation': get_recommendation(result),
        })

    except (IOError, OSError):
        logger.warning('Invalid image file uploaded')
        return jsonify({'error': 'Invalid or corrupted image file'}), 400
    except Exception as e:
        logger.error('Disease prediction failed: %s', e, exc_info=True)
        return jsonify({'error': 'Internal prediction error'}), 500


@app.route('/predict/irrigation', methods=['POST'])
def predict_irrigation():
    data = request.get_json(silent=True)

    # --- Validate input ---
    errors = validate_irrigation_input(data)
    if errors:
        return jsonify({'errors': errors}), 400

    try:
        temp = data.get('temperature', 25)
        humidity = data.get('humidity', 60)
        soil_moisture = data.get('soil_moisture', 50)
        crop_type = data.get('crop_type', 1)

        inputs = np.array([[temp, humidity, soil_moisture, crop_type]])

        if irrigation_model:
            prediction = irrigation_model.predict(inputs)
            water_amount = float(prediction[0][0])
        else:
            # Mock: simplified Hargreaves-based estimation
            water_amount = max(0, (30 - soil_moisture) * 0.5 + (temp - 20) * 0.2)

        water_amount = round(water_amount, 2)
        logger.info('Irrigation prediction: %.2f mm (temp=%.1f, moisture=%.1f)', water_amount, temp, soil_moisture)

        return jsonify({
            'water_amount_mm': water_amount,
            'next_irrigation': 'Demain matin' if water_amount > 5 else 'Pas nécessaire',
        })

    except Exception as e:
        logger.error('Irrigation prediction failed: %s', e, exc_info=True)
        return jsonify({'error': 'Internal prediction error'}), 500


# =====================================================
# Startup
# =====================================================
load_models()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
