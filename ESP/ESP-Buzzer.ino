#include <WiFi.h>
#include <LoRa.h>
#include <SPI.h>

#define DEVICE_ID 6  //Ini ID-nya 6 untuk burung

// Pin Definitions
// LoRa
#define LORA_SS 5
#define LORA_RST 14
#define LORA_DIO0 2

const char* ssid = "ESP32_AP";
const char* password = "12345678";

WiFiServer server(5000);
WiFiClient clients[10];  // Simpan client yang terhubung

const int relayPinSpeaker = 33;
const int relayPinMotor = 32;
// SPIClass hpsi(HSPI);

void setup() {
  Serial.begin(115200);

  pinMode(relayPinSpeaker, OUTPUT);
  pinMode(relayPinMotor, OUTPUT);

  digitalWrite(relayPinSpeaker, LOW);
  digitalWrite(relayPinMotor, LOW);

  WiFi.softAP(ssid, password);
  Serial.println("ESP32 Access Point Started");
  Serial.print("IP Address: ");
  Serial.println(WiFi.softAPIP());

  // hpsi.begin(14, 12, 13, 15);

  // LoRa.setSPI(hpsi);
  LoRa.setPins(LORA_SS, LORA_RST, LORA_DIO0);
  // LoRa.setPins(LORA_SS);
  if (!LoRa.begin(923E6)) {
    Serial.println("Error: Gagal memulai LoRa!");
  } else {
    LoRa.setSyncWord(0xF3);
    Serial.println("LoRa OK!");
  }

  server.begin();
}

void loop() {
  // Cek client baru
  WiFiClient newClient = server.available();
  if (newClient) {
    for (int i = 0; i < 10; i++) {
      if (!clients[i] || !clients[i].connected()) {
        clients[i] = newClient;
        Serial.print("New client connected: ");
        Serial.println(newClient.remoteIP());
        break;
      }
    }
  }

  // Cek pesan dari setiap client
  for (int i = 0; i < 10; i++) {
    if (clients[i] && clients[i].connected()) {
      if (clients[i].available()) {
        String message = clients[i].readString();
        message.trim();
        Serial.print("Received from ");
        Serial.print(clients[i].remoteIP());
        Serial.print(": ");
        Serial.println(message);

        // === Broadcast pesan ke semua client ===
        Serial.println("Broadcast to clients:");
        for (int j = 0; j < 10; j++) {
          if (clients[j] && clients[j].connected()) {
            clients[j].println(message);
            Serial.print("- ");
            Serial.println(clients[j].remoteIP());
          }
        }

        // broadcast terus tiap 0.2s (dari raspy)
          // broadcast ke lora
          LoRa.beginPacket();
          LoRa.print(message);
          LoRa.endPacket();
          Serial.println("Payload Terkirim ke lora: " + message);

        // === Relay lokal saja, tidak dibroadcast ===
        // jalan ketika ada burung saja tiap 10 detik
        if (message.equalsIgnoreCase("on") || message.indexOf("on") != -1) {
          digitalWrite(relayPinSpeaker, HIGH);  // Speaker ON
          digitalWrite(relayPinMotor, HIGH);    // Motor ON
          Serial.println("Relay ON (10s)");
          delay(10000);                        // Relay menyala 10 detik
          digitalWrite(relayPinSpeaker, LOW);  // Speaker OFF
          digitalWrite(relayPinMotor, LOW);    // Motor OFF
          Serial.println("Relay turned OFF after 10 seconds");
        }

      }
    }
  }
}
