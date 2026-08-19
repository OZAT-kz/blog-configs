// ==============================================================================
// ESP32 IoT Greenhouse Sensor & Relay Firmware for Firebase (RU)
// Source: OZAT Engineering Blog (https://ozat.kz)
// GitHub: https://github.com/OZAT-kz/blog-configs/blob/main/esp32_saryagash_greenhouse_firmware_ru.ino
// ==============================================================================

#include <WiFi.h>
#include <Firebase_ESP_Client.h>
#include <DHT.h>

// Конфигурация Wi-Fi и Firebase Realtime Database
#define WIFI_SSID "Saryagash_Greenhouse_4G"
#define WIFI_PASSWORD "AgroKz2026Secure"
#define API_KEY "AIzaSyD-YourFirebaseWebApiKeyHere"
#define DATABASE_URL "https://saryagash-greenhouse-default-rtdb.firebaseio.com/"

// Пины периферии на плате ESP32
#define DHTPIN 4
#define DHTTYPE DHT22
#define SOIL_MOISTURE_ANALOG_PIN 34
#define RELAY_PUMP_PIN 18
#define RELAY_MIST_VENT_PIN 19

DHT dht(DHTPIN, DHTTYPE);
FirebaseData fbdo;
FirebaseAuth auth;
FirebaseConfig config;

unsigned long lastTelemetryMillis = 0;
const long telemetryInterval = 10000; // Телеметрия каждые 10 секунд

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PUMP_PIN, OUTPUT);
  pinMode(RELAY_MIST_VENT_PIN, OUTPUT);
  digitalWrite(RELAY_PUMP_PIN, HIGH); // Реле с низкоуровневым триггером (HIGH = OFF)
  
  dht.begin();
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  Serial.print("Connecting to 4G Wi-Fi...");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println(" Connected!");

  config.api_key = API_KEY;
  config.database_url = DATABASE_URL;
  Firebase.begin(&config, &auth);
  Firebase.reconnectWiFi(true);
}

void loop() {
  // 1. Чтение сенсоров микроклимата теплицы
  if (millis() - lastTelemetryMillis > telemetryInterval) {
    lastTelemetryMillis = millis();
    
    float humidity = dht.readHumidity();
    float temp = dht.readTemperature();
    int rawSoil = analogRead(SOIL_MOISTURE_ANALOG_PIN);
    // Калибровка емкостного датчика влажности (0-100%)
    float soilPct = map(rawSoil, 3200, 1400, 0, 100);
    soilPct = constrain(soilPct, 0.0, 100.0);

    if (!isnan(humidity) && !isnan(temp)) {
      FirebaseJson json;
      json.set("soil_moisture_pct", soilPct);
      json.set("air_temp_c", temp);
      json.set("air_humidity_pct", humidity);
      Firebase.RTDB.setJSON(&fbdo, "/greenhouses/GH-SARYAGASH-01/telemetry", &json);
    }
  }

  // 2. Мгновенное чтение управляющих сигналов из Firebase Realtime DB
  if (Firebase.RTDB.getBool(&fbdo, "/greenhouses/GH-SARYAGASH-01/controls/drip_pump_active")) {
    bool pumpOn = fbdo.boolData();
    digitalWrite(RELAY_PUMP_PIN, pumpOn ? LOW : HIGH);
  }
  
  delay(100);
}
