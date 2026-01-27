/**
 * Tests unitaires pour le Service Météo
 * AgriSmart CI - Backend
 */

// Mock axios before requiring the service
jest.mock('axios');
const axios = require('axios');
const weatherService = require('../../../src/services/weatherService');

describe('WeatherService', () => {
    beforeEach(() => {
        weatherService.clearCache();
        jest.clearAllMocks();
    });

    describe('getCurrentWeather', () => {
        const mockLat = 5.3600;
        const mockLon = -4.0083;

        const mockOpenMeteoResponse = {
            data: {
                latitude: 5.36,
                longitude: -4.01,
                timezone: 'Africa/Abidjan',
                current: {
                    temperature_2m: 28.5,
                    relative_humidity_2m: 75,
                    is_day: 1,
                    precipitation: 0,
                    rain: 0,
                    weather_code: 1,
                    cloud_cover: 25,
                    wind_speed_10m: 12.5,
                    wind_direction_10m: 180,
                    pressure_msl: 1013.2
                }
            }
        };

        test('should return current weather data', async () => {
            axios.get.mockResolvedValueOnce(mockOpenMeteoResponse);

            const result = await weatherService.getCurrentWeather(mockLat, mockLon);

            expect(result).toHaveProperty('temperature');
            expect(result).toHaveProperty('humidite');
            expect(result).toHaveProperty('vent');
            expect(axios.get).toHaveBeenCalledTimes(1);
        });

        test('should use cache for repeated requests', async () => {
            axios.get.mockResolvedValueOnce(mockOpenMeteoResponse);

            // Premier appel
            await weatherService.getCurrentWeather(mockLat, mockLon);
            // Deuxième appel (devrait utiliser le cache)
            await weatherService.getCurrentWeather(mockLat, mockLon);

            expect(axios.get).toHaveBeenCalledTimes(1);
        });

        test('should throw error when API fails', async () => {
            axios.get.mockRejectedValueOnce(new Error('Network error'));

            await expect(weatherService.getCurrentWeather(mockLat, mockLon))
                .rejects
                .toThrow('Impossible de récupérer les données météo');
        });
    });

    describe('getForecast', () => {
        const mockLat = 5.3600;
        const mockLon = -4.0083;

        const mockForecastResponse = {
            data: {
                latitude: 5.36,
                longitude: -4.01,
                timezone: 'Africa/Abidjan',
                daily: {
                    time: ['2024-01-15', '2024-01-16', '2024-01-17'],
                    temperature_2m_max: [30, 31, 29],
                    temperature_2m_min: [22, 23, 21],
                    precipitation_sum: [0, 5.2, 0],
                    precipitation_probability_max: [10, 80, 20],
                    et0_fao_evapotranspiration: [4.5, 3.8, 4.2],
                    weather_code: [1, 63, 2],
                    uv_index_max: [10, 8, 9],
                    wind_speed_10m_max: [15, 20, 12],
                    wind_direction_10m_dominant: [180, 200, 160]
                },
                hourly: {
                    time: Array(72).fill(0).map((_, i) => `2024-01-${15 + Math.floor(i/24)}T${String(i % 24).padStart(2, '0')}:00`),
                    temperature_2m: Array(72).fill(24),
                    relative_humidity_2m: Array(72).fill(80),
                    rain: Array(72).fill(0),
                    precipitation: Array(72).fill(0),
                    precipitation_probability: Array(72).fill(10),
                    cloud_cover: Array(72).fill(25),
                    evapotranspiration: Array(72).fill(0.2),
                    soil_temperature_0cm: Array(72).fill(26),
                    soil_temperature_6cm: Array(72).fill(25),
                    soil_temperature_18cm: Array(72).fill(24),
                    soil_moisture_0_to_1cm: Array(72).fill(0.35),
                    soil_moisture_1_to_3cm: Array(72).fill(0.32),
                    soil_moisture_3_to_9cm: Array(72).fill(0.30),
                    wind_speed_10m: Array(72).fill(12),
                    wind_direction_10m: Array(72).fill(180),
                    wind_gusts_10m: Array(72).fill(18)
                }
            }
        };

        test('should return forecast data', async () => {
            axios.get.mockResolvedValueOnce(mockForecastResponse);

            const result = await weatherService.getForecast(mockLat, mockLon);

            expect(result).toHaveProperty('previsions');
            expect(Array.isArray(result.previsions)).toBe(true);
            expect(axios.get).toHaveBeenCalledWith(
                expect.any(String),
                expect.objectContaining({
                    params: expect.objectContaining({
                        latitude: mockLat,
                        longitude: mockLon
                    })
                })
            );
        });

        test('should cache forecast results', async () => {
            axios.get.mockResolvedValueOnce(mockForecastResponse);

            await weatherService.getForecast(mockLat, mockLon);
            await weatherService.getForecast(mockLat, mockLon);

            expect(axios.get).toHaveBeenCalledTimes(1);
        });
    });

    describe('getAgriculturalAlerts', () => {
        test('should generate alerts based on weather conditions', async () => {
            const mockLat = 5.3600;
            const mockLon = -4.0083;

            // Mock for getCurrentWeather
            const mockCurrentResponse = {
                data: {
                    latitude: 5.36,
                    longitude: -4.01,
                    current: {
                        temperature_2m: 38,
                        relative_humidity_2m: 75,
                        is_day: 1,
                        precipitation: 0,
                        rain: 0,
                        weather_code: 1,
                        cloud_cover: 25,
                        wind_speed_10m: 12.5,
                        wind_direction_10m: 180,
                        pressure_msl: 1013.2
                    }
                }
            };

            // Mock for getForecast
            const mockForecastResponse = {
                data: {
                    latitude: 5.36,
                    longitude: -4.01,
                    timezone: 'Africa/Abidjan',
                    daily: {
                        time: ['2024-01-15', '2024-01-16', '2024-01-17'],
                        temperature_2m_max: [38, 31, 29],
                        temperature_2m_min: [22, 23, 21],
                        precipitation_sum: [100, 5.2, 0],
                        precipitation_probability_max: [10, 80, 20],
                        et0_fao_evapotranspiration: [4.5, 3.8, 4.2],
                        weather_code: [1, 63, 2],
                        uv_index_max: [10, 8, 9],
                        wind_speed_10m_max: [15, 20, 12],
                        wind_direction_10m_dominant: [180, 200, 160]
                    },
                    hourly: {
                        time: Array(72).fill(0).map((_, i) => `2024-01-${15 + Math.floor(i/24)}T${String(i % 24).padStart(2, '0')}:00`),
                        temperature_2m: Array(72).fill(24),
                        relative_humidity_2m: Array(72).fill(80),
                        rain: Array(72).fill(0),
                        precipitation: Array(72).fill(0),
                        precipitation_probability: Array(72).fill(10),
                        cloud_cover: Array(72).fill(25),
                        evapotranspiration: Array(72).fill(0.2),
                        soil_temperature_0cm: Array(72).fill(26),
                        soil_temperature_6cm: Array(72).fill(25),
                        soil_temperature_18cm: Array(72).fill(24),
                        soil_moisture_0_to_1cm: Array(72).fill(0.35),
                        soil_moisture_1_to_3cm: Array(72).fill(0.32),
                        soil_moisture_3_to_9cm: Array(72).fill(0.30),
                        wind_speed_10m: Array(72).fill(12),
                        wind_direction_10m: Array(72).fill(180),
                        wind_gusts_10m: Array(72).fill(18)
                    }
                }
            };

            // Mock axios to return current weather first, then forecast
            axios.get
                .mockResolvedValueOnce(mockCurrentResponse)
                .mockResolvedValueOnce(mockForecastResponse);

            const alerts = await weatherService.getAgriculturalAlerts(mockLat, mockLon);

            expect(Array.isArray(alerts)).toBe(true);
            // Should have at least one alert due to high temperature (38°C > 35°C) and heavy rain (100mm)
            expect(alerts.length).toBeGreaterThan(0);
        });
    });

    describe('cache management', () => {
        test('should have default cache duration of 30 minutes', () => {
            expect(weatherService.cacheDuration).toBe(30 * 60 * 1000);
        });

        test('should expire cache after duration', async () => {
            const mockResponse = {
                data: {
                    current: {
                        temperature_2m: 25,
                        relative_humidity_2m: 70,
                        is_day: 1,
                        precipitation: 0,
                        rain: 0,
                        weather_code: 1,
                        cloud_cover: 20,
                        wind_speed_10m: 10,
                        wind_direction_10m: 90,
                        pressure_msl: 1012
                    }
                }
            };

            axios.get.mockResolvedValue(mockResponse);

            // Premier appel
            await weatherService.getCurrentWeather(5.36, -4.01);

            // Simuler l'expiration du cache
            weatherService.cacheDuration = 0;

            // Deuxième appel (devrait refaire un appel API)
            await weatherService.getCurrentWeather(5.36, -4.01);

            expect(axios.get).toHaveBeenCalledTimes(2);
        });
    });
});
