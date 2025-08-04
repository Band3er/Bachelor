# Remote Wake-on-LAN System Using ESP32 and AWS IoT

**Bachelor's Thesis Project - "Design and Implementation of a Remote Control System Based on Wake-on-LAN (WoL)"**

## Overview

This project aims to provide a secure, remote system capable of waking up personal computers over Ethernet using the Wake-on-LAN (WoL) protocol, controlled via a cloud-connected ESP32 microcontroller. The system integrates AWS Lambda, MQTT over TLS, and direct Ethernet communication to ensure reliable and secure remote operations.

## Objectives

- Wake up remote computers securely using WoL packets sent by an ESP32.
- Communicate securely over HTTPS and MQTT (TLS mutual authentication).
- Scan the local network using ARP to identify available devices.
- Authenticate users via AWS Lambda and manage credentials.
- Ensure compatibility with both Windows and Linux targets.
- Provide a scalable and lightweight IoT solution for remote access.

## System Architecture

- **ESP32** with Ethernet interface and FreeRTOS
- **AWS Lambda** for authentication and session management
- **AWS DynamoDB** for storing user credentials and MAC address associations
- **MQTT over TLS** for secure command exchange
- **HTTPS endpoints** to receive commands and send JSON responses
- **ARP Scanner** module and WoL sender


## Technologies Used

- **ESP-IDF** (Espressif IoT Development Framework)
- **FreeRTOS**
- **AWS Lambda (Python)**
- **AWS DynamoDB**
- **MQTT over TLS**
- **Wake-on-LAN (Magic Packet)**
- **ARP protocol**
- **HTTPS client (esp-tls)**

## Testing and Results

- Network packet captures using **Wireshark** validated proper WoL and ARP formats.
- Remote wake-up worked consistently on Windows 10 and Ubuntu 22.04 clients.
- All components ran concurrently under FreeRTOS without memory leakage or watchdog resets.

## Prerequisites

- ESP32 with Ethernet support (e.g., WROVER-Kit + LAN8720)
- AWS account with permissions to:
  - Create **Lambda functions**
  - Create and configure **IoT Core**
  - Set up **DynamoDB**
- Development tools:
  - ESP-IDF 5.x (or higher)
  - Python 3.9+
  - OpenSSL (for certificate generation)
  - Flutter SDK (for building a mobile interface)
