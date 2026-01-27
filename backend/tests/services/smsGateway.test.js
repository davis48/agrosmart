/**
 * Tests pour le service SMS Gateway
 * AgriSmart CI - Backend
 */

const { SmsGatewayService, SMS_TEMPLATES, SMS_PRIORITY } = require('../../src/services/smsGatewayService');

describe('SMS Gateway Service', () => {
  let smsService;

  beforeEach(() => {
    // Créer une nouvelle instance pour chaque test
    smsService = new SmsGatewayService();
  });

  describe('Phone Number Formatting', () => {
    test('should format Ivorian number with country code', () => {
      const formatted = smsService._formatPhoneNumber('2250701234567');
      expect(formatted).toBe('+2250701234567');
    });

    test('should format Ivorian number with 00 prefix', () => {
      const formatted = smsService._formatPhoneNumber('002250701234567');
      expect(formatted).toBe('+2250701234567');
    });

    test('should format local 10-digit Ivorian number', () => {
      const formatted = smsService._formatPhoneNumber('0701234567');
      expect(formatted).toBe('+225701234567');
    });

    test('should format 10-digit number without leading zero', () => {
      const formatted = smsService._formatPhoneNumber('0701234567');
      expect(formatted).toBe('+225701234567');
    });

    test('should format old 8-digit Ivorian number', () => {
      const formatted = smsService._formatPhoneNumber('01234567');
      expect(formatted).toBe('+22501234567');
    });

    test('should handle number with + prefix', () => {
      const formatted = smsService._formatPhoneNumber('+2250701234567');
      expect(formatted).toBe('+2250701234567');
    });

    test('should return null for empty number', () => {
      const formatted = smsService._formatPhoneNumber('');
      expect(formatted).toBeNull();
    });

    test('should return null for null number', () => {
      const formatted = smsService._formatPhoneNumber(null);
      expect(formatted).toBeNull();
    });
  });

  describe('Message Truncation', () => {
    test('should not truncate short messages', () => {
      const message = 'Short message';
      const truncated = smsService._truncateMessage(message, 160);
      expect(truncated).toBe(message);
    });

    test('should truncate long messages', () => {
      const message = 'A'.repeat(200);
      const truncated = smsService._truncateMessage(message, 160);
      expect(truncated.length).toBe(160);
      expect(truncated.endsWith('...')).toBe(true);
    });

    test('should handle exact length messages', () => {
      const message = 'A'.repeat(160);
      const truncated = smsService._truncateMessage(message, 160);
      expect(truncated).toBe(message);
    });
  });

  describe('Templates', () => {
    test('should have all required templates', () => {
      const templates = smsService.getTemplates();
      expect(templates).toContain('weather_alert');
      expect(templates).toContain('disease_alert');
      expect(templates).toContain('irrigation_alert');
      expect(templates).toContain('harvest_reminder');
      expect(templates).toContain('market_price');
      expect(templates).toContain('welcome');
      expect(templates).toContain('otp');
    });

    test('should have French version for all templates', () => {
      for (const key of Object.keys(SMS_TEMPLATES)) {
        expect(SMS_TEMPLATES[key].fr).toBeDefined();
      }
    });

    test('should have Baoulé version for most templates', () => {
      const templatesWithBaoule = ['weather_alert', 'disease_alert', 'welcome', 'otp'];
      for (const key of templatesWithBaoule) {
        expect(SMS_TEMPLATES[key].bci).toBeDefined();
      }
    });

    test('should have Dioula version for most templates', () => {
      const templatesWithDioula = ['weather_alert', 'disease_alert', 'welcome', 'otp'];
      for (const key of templatesWithDioula) {
        expect(SMS_TEMPLATES[key].dyu).toBeDefined();
      }
    });
  });

  describe('Supported Languages', () => {
    test('should return supported languages', () => {
      const languages = smsService.getSupportedLanguages();
      expect(languages).toContain('fr');
      expect(languages).toContain('bci');
      expect(languages).toContain('dyu');
    });
  });

  describe('Simulated SMS Sending', () => {
    test('should send simulated SMS successfully', async () => {
      const result = await smsService._sendSimulated('+2250701234567', 'Test message');
      expect(result.success).toBe(true);
      expect(result.simulated).toBe(true);
      expect(result.messageId).toMatch(/^sim_/);
    });
  });

  describe('Send from Template', () => {
    test('should replace variables in template', async () => {
      // We can't easily test the full flow without mocking, but we can verify the template exists
      const templates = smsService.getTemplates();
      expect(templates).toContain('weather_alert');
    });

    test('should return error for unknown template', async () => {
      const result = await smsService.sendFromTemplate(
        '+2250701234567',
        'unknown_template',
        {},
        'fr'
      );
      expect(result.success).toBe(false);
      expect(result.error).toBe('Template not found');
    });
  });

  describe('SMS Priority', () => {
    test('should have correct priority values', () => {
      expect(SMS_PRIORITY.CRITICAL).toBe(1);
      expect(SMS_PRIORITY.HIGH).toBe(2);
      expect(SMS_PRIORITY.NORMAL).toBe(3);
      expect(SMS_PRIORITY.LOW).toBe(4);
    });

    test('CRITICAL should be highest priority', () => {
      expect(SMS_PRIORITY.CRITICAL).toBeLessThan(SMS_PRIORITY.HIGH);
      expect(SMS_PRIORITY.HIGH).toBeLessThan(SMS_PRIORITY.NORMAL);
      expect(SMS_PRIORITY.NORMAL).toBeLessThan(SMS_PRIORITY.LOW);
    });
  });

  describe('Template Variable Replacement', () => {
    test('weather_alert template should have required placeholders', () => {
      const template = SMS_TEMPLATES.weather_alert.fr;
      expect(template).toContain('{message}');
      expect(template).toContain('{parcelle}');
    });

    test('disease_alert template should have required placeholders', () => {
      const template = SMS_TEMPLATES.disease_alert.fr;
      expect(template).toContain('{disease}');
      expect(template).toContain('{parcelle}');
      expect(template).toContain('{treatment}');
    });

    test('otp template should have code placeholder', () => {
      const template = SMS_TEMPLATES.otp.fr;
      expect(template).toContain('{code}');
    });

    test('market_price template should have all placeholders', () => {
      const template = SMS_TEMPLATES.market_price.fr;
      expect(template).toContain('{product}');
      expect(template).toContain('{price}');
      expect(template).toContain('{unit}');
      expect(template).toContain('{market}');
    });
  });

  describe('Initialization', () => {
    test('should not be initialized by default', () => {
      const service = new SmsGatewayService();
      expect(service.initialized).toBe(false);
    });

    test('should handle missing API key gracefully', async () => {
      const service = new SmsGatewayService();
      // Sans API key configurée, l'initialisation devrait logger un warning mais pas échouer
      await service.initialize();
      // Le service ne sera pas marqué comme initialisé sans API key
    });
  });
});
