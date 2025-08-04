
## ESP-IDF Installation

You can install ESP-IDF in two main ways:

### Option 1: Command Line Interface (CLI)

```bash
# Clone the ESP-IDF repository
git clone --recursive https://github.com/espressif/esp-idf.git
cd esp-idf
git checkout v5.2.1  # Use the latest stable version

# Run the installer
./install.sh esp32

# Export environment variables
. export.sh
```

After installation, use the following commands to build and run your project:

```bash
idf.py build
idf.py flash
idf.py monitor
```

---

### 🔹 Option 2: Visual Studio Code Extension (Recommended for Beginners)

1. Install [Visual Studio Code](https://code.visualstudio.com/)
2. Open the **Extensions** tab and install the official **Espressif IDF** extension
3. Follow the guided installation steps for:
   - ESP-IDF version
   - Python interpreter
   - Required toolchains
4. Open your project folder and use the GUI to build, flash, and monitor the device

More details: [ESP-IDF VSCode Extension](https://github.com/espressif/vscode-esp-idf-extension)

---

## Adding AWS IoT Certificates (for MQTT)

If this project uses secure MQTT communication (e.g., with AWS IoT Core), you need to add the following certificates to your project.

### Go to `components/mqtt_ssl/` directory

Inside there you will find:
- `client.crt` – Device certificate  
- `client.key` – Private key  
- `aws_root.crt` – Amazon Root CA certificate

### 🌐 Step 4: Add your AWS MQTT endpoint

Inside `mqtt.c`:

```c
.broker.address.uri = ""
```

and then, from `https_protocol`:

```c
#define WEB_SERVER ""
#define WEB_PORT ""
#define WEB_URL_POST ""
```

---

## Building the Project

After setting up ESP-IDF and configuring your certificates and endpoint:

```bash
idf.py build
idf.py -p port flash monitor
```

Make sure your Ethernet connection is established  
MQTT connects successfully to AWS IoT  