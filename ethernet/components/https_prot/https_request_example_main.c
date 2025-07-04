/*
 * HTTPS GET Example using plain Mbed TLS sockets
 *
 * Contacts the howsmyssl.com API via TLS v1.2 and reads a JSON
 * response.
 *
 * Adapted from the ssl_client1 example in Mbed TLS.
 *
 * SPDX-FileCopyrightText: The Mbed TLS Contributors
 *
 * SPDX-License-Identifier: Apache-2.0
 *
 * SPDX-FileContributor: 2015-2025 Espressif Systems (Shanghai) CO LTD
 */
#include "https_protocol.h"

#include "freertos/semphr.h"

extern const uint8_t server_root_cert_pem_start[] asm("_binary_server_root_cert_pem_start");
extern const uint8_t server_root_cert_pem_end[] asm("_binary_server_root_cert_pem_end");

//extern const uint8_t local_server_cert_pem_start[] asm("_binary_local_server_cert_pem_start");
//extern const uint8_t local_server_cert_pem_end[] asm("_binary_local_server_cert_pem_end");

int int_to_str(int num, char *buf)
{
    int i = 0;

    if (num == 0)
    {
        buf[0] = '0';
        buf[1] = '\0';
        return 1;
    }

    // Procesare cifre în ordine inversă
    while (num > 0)
    {
        buf[i++] = (num % 10) + '0';
        num /= 10;
    }

    // Inversăm șirul pentru a obține rezultatul corect
    for (int j = 0; j < i / 2; j++)
    {
        char temp = buf[j];
        buf[j] = buf[i - j - 1];
        buf[i - j - 1] = temp;
    }

    buf[i] = '\0'; // Terminator null
    return i;      // Returnează numărul de caractere generate
}

void send_post_request(char *data_send)
{
    ESP_LOGI(TAG, "https_request using crt bundle");

    int content_len = strlen(data_send);

    esp_tls_cfg_t cfg = {
        .crt_bundle_attach = esp_crt_bundle_attach,
    };

    char request[512];
    snprintf(request, sizeof(request),
             "POST / HTTP/1.1\r\n"
             "Host: %s\r\n"
             "User-Agent: esp-idf/1.0 esp32\r\n"
             "Content-Type: application/json\r\n"
             "Content-Length: %d\r\n"
             "\r\n"
             "%s",
             WEB_SERVER, content_len, data_send);

    ESP_LOGI(TAG, "%s", request);

    heap_caps_check_integrity_all(true);

    https_get_request(cfg, WEB_URL_POST, request);
    heap_caps_check_integrity_all(true);
}

#define MAX_HTTPS_RETRIES 3
void https_get_request(esp_tls_cfg_t cfg, const char *WEB_SERVER_URL, const char *REQUEST)
{
    char buf[512];
    int ret, len;
    int attemp = 0;
    while (attemp < MAX_HTTPS_RETRIES)
    {
        esp_tls_t *tls = esp_tls_init();
        if (!tls)
        {
            ESP_LOGE(TAG, "Failed to allocate esp_tls handle!");
            return;
        }
        ESP_LOGI(TAG, "Încercare HTTPS %d/%d", attemp + 1, MAX_HTTPS_RETRIES);
        if (esp_tls_conn_http_new_sync(WEB_SERVER_URL, &cfg, tls) == 1)
        {
            ESP_LOGI(TAG, "Connection established...");
        }
        else
        {
            ESP_LOGE(TAG, "Connection failed...");
            int esp_tls_code = 0, esp_tls_flags = 0;
            esp_tls_error_handle_t tls_e = NULL;
            esp_tls_get_error_handle(tls, &tls_e);
            /* Try to get TLS stack level error and certificate failure flags, if any */
            ret = esp_tls_get_and_clear_last_error(tls_e, &esp_tls_code, &esp_tls_flags);
            if (ret == ESP_OK)
            {
                ESP_LOGE(TAG, "TLS error = -0x%x, TLS flags = -0x%x", esp_tls_code, esp_tls_flags);
            }
            esp_tls_conn_destroy(tls);
            vTaskDelay(pdMS_TO_TICKS(1000 * (attemp + 1)));
            attemp++;
            continue;
        }

        size_t written_bytes = 0;
        do
        {
            ret = esp_tls_conn_write(tls,
                                     REQUEST + written_bytes,
                                     strlen(REQUEST) - written_bytes);
            if (ret >= 0)
            {
                ESP_LOGI(TAG, "%d bytes written", ret);
                written_bytes += ret;
            }
            else if (ret != ESP_TLS_ERR_SSL_WANT_READ && ret != ESP_TLS_ERR_SSL_WANT_WRITE)
            {
                ESP_LOGE(TAG, "esp_tls_conn_write  returned: [0x%02X](%s)", ret, esp_err_to_name(ret));
            }
        } while (written_bytes < strlen(REQUEST));
        esp_tls_conn_destroy(tls);
        return;
    }

    ESP_LOGE(TAG, "Eșec HTTPS după %d încercări", MAX_HTTPS_RETRIES);
}