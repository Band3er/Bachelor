
# Mobile interface

A Flutter project used as a remote interface for sending commands to AWS IoT via MQTT with TLS authentication.

---

## Getting Started

### Prerequisites

- Flutter SDK (3.x recommended)
- Dart SDK
- An emulator or physical Android/iOS device
- MQTT client setup (e.g., [mqtt_client](https://pub.dev/packages/mqtt_client) package)

---

### Flutter Installation

Follow the official guide to install Flutter:

```bash
# Clone the Flutter SDK
git clone https://github.com/flutter/flutter.git
export PATH="\$PATH:`pwd`/flutter/bin"

# Run doctor to check environment
flutter doctor
```

You may need to accept Android licenses and set up Xcode on macOS.

For full setup: [Flutter installation docs](https://docs.flutter.dev/get-started/install)

---

## Project Structure

```
mobile_interface/
├── assets/
│   └── cert/
│       ├── amazon_root.pem
│       ├── certificate.pem.crt
│       └── private.pem.key
├── lib/
├── pubspec.yaml
└── README.md
```

---

## MQTT Certificate Setup

This project uses TLS client authentication to connect securely to AWS IoT Core.

1. **Create the folder structure** in your Flutter project:

```bash
mkdir -p assets/cert
```

2. **Add the following files to `assets/cert/`** (from AWS IoT Core):

- `AmazonRootCA1.pem` – Amazon Root CA certificate
- `certificate.pem.crt` – Device certificate
- `private.pem.key` – Private key

3. **Update `pubspec.yaml`** to include the assets:

```yaml
flutter:
  assets:
    - assets/cert/AmazonRootCA1.pem
    - assets/cert/certificate.pem.crt
    - assets/cert/private.pem.key
```

---

## MQTT Configuration

In your Dart code, set up the MQTT client using the `mqtt_client` package.

Make sure to load the certificates from assets and configure secure connection (see examples in the [mqtt_client](https://pub.dev/packages/mqtt_client) documentation or your own secure client wrapper).

---

## Running the App

Install dependencies:

```bash
flutter pub get
```

Then run the app:

```bash
flutter run
```

You should see logs confirming MQTT connection over TLS and your app ready to send commands to AWS IoT Core.

---

## Resources

- [AWS IoT Core Docs](https://docs.aws.amazon.com/iot/latest/developerguide/)
- [Flutter mqtt_client](https://pub.dev/packages/mqtt_client)
- [Flutter Dev Docs](https://docs.flutter.dev/)
