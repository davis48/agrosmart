#!/bin/bash

# Script rapide pour générer les données IoT de test
# Usage: ./seed-iot-quick.sh

echo "🌱 Génération rapide des données IoT de test"
echo "============================================="
echo ""

cd backend
node scripts/seed-iot-capteurs.js

echo ""
echo "✅ Terminé!"
echo ""
echo "📱 Pour tester sur mobile:"
echo "   cd mobile && flutter run"
echo ""
echo "🌐 Endpoints disponibles:"
echo "   GET /api/parcelles/:id/iot-metrics"
echo "   GET /api/analytics/stats"
