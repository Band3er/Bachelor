#include "comm.h"
#include "esp_sntp.h"
#include "time_sync.h"
#include "esp_bt_device.h"
#include "esp_sntp.h"
#include "app_main.h"

double mac_to_double(uint8_t mac[6]){
    uint64_t val = 0;
    for(size_t i = 0; i < 6; ++i){
        val = (val << 8) | mac[i];
    }
    return (double)val;
}

void obtain_time(void) {
    // Setează fusul orar pentru România
    setenv("TZ", "EET-2EEST,M3.5.0/3,M10.5.0/4", 1);
    tzset();

    // Configurează SNTP înainte de init
    esp_sntp_stop(); // în caz că era deja activ
    esp_sntp_setoperatingmode(SNTP_OPMODE_POLL);
    esp_sntp_setservername(0, "pool.ntp.org"); // sau "time.google.com"
    esp_sntp_init();

    time_t now = 0;
    struct tm timeinfo = { 0 };
    int retry = 0;
    const int retry_count = 10;

    while (timeinfo.tm_year < (2025 - 1900) && ++retry < retry_count) {
        ESP_LOGI(TAG, "Aștept sincronizare timp... (%d/%d)", retry, retry_count);
        vTaskDelay(pdMS_TO_TICKS(2000));
        time(&now);
        localtime_r(&now, &timeinfo);
    }

    if (timeinfo.tm_year < (2025 - 1900)) {
        ESP_LOGE(TAG, "Timpul nu a fost setat corect!");
    } else {
        char time_str[64];
        strftime(time_str, sizeof(time_str), "%Y-%m-%d %H:%M:%S", &timeinfo);
        ESP_LOGI(TAG, "Timp sincronizat: %s", time_str);
    }
}


void vTaskFunction(void *pvParameters){

    xSemaphore_Task = xSemaphoreCreateBinary();
    esp_netif_t *eth_netif = (esp_netif_t *)pvParameters;

    cJSON* json;

    command commands;

    char* mac_address;
    char* ip_address;
    uint32_t deviceCounts;
    deviceInfo* devices;
    ip4_addr_t device;
    char *ip;
    int id = 1;
    cJSON* json_array;
    char data[256];


    char mac_str[18];
    const uint8_t* esp_mac = esp_bt_dev_get_address();
    snprintf(mac_str, sizeof(mac_str), "%02x:%02x:%02x:%02x:%02x:%02x",
         esp_mac[0], esp_mac[1], esp_mac[2], esp_mac[3], esp_mac[4], esp_mac[5]);

    int clona;
    for(size_t index = 0; index < 6; ++index){
        id *= esp_mac[index] / 10;
    }
    clona = id;

    mqtt_app_start();

    while(1){
        while(is_mqtt_data_available() == false){
            //data = get_mqtt_data();
            ESP_LOGE(TAG, "No message received");
            vTaskDelay(pdMS_TO_TICKS(1000));
        }
        strcpy(data, get_mqtt_data());
            
        ESP_LOGI(TAG, "Data received from MQTT: %s", data);

        json = cJSON_Parse(data);

        if(json != NULL){
            ESP_LOGI(TAG, "Data parsed: %s", cJSON_Print(json));
        } else {
            ESP_LOGE(TAG, "Data was not received or parsed correctly");
        }

        commands.do_arp = cJSON_GetNumberValue(cJSON_GetObjectItem(json, "do_arp"));
        commands.send_wol = cJSON_GetNumberValue(cJSON_GetObjectItem(json, "send_wol"));
        commands.is_online = cJSON_GetNumberValue(cJSON_GetObjectItem(json, "is_online"));

        

        if(commands.do_arp == 1){

            arpScan(eth_netif);
            devices = getDeviceInfos();
            deviceCounts = getDeviceCount(); // online devices
            ESP_LOGI(TAG, "deviceCounts = %" PRIu32, deviceCounts);


            json_array = cJSON_CreateArray();

            // schimba pana unde itereaza aici
            // max subnet device
            // ai param in scan.c
            for(size_t i = 0; i < deviceCounts; ++i){
                cJSON* json_obj = cJSON_CreateObject();

                device.addr = devices[i].ip;
                ip = ip4addr_ntoa(&device);

                obtain_time();

                time_t now;
                time(&now);
                //ESP_LOGI(TAG, "Current timestamp: %ld", now);
                time_t expiration_time = now + 2 * 3600;

                cJSON_AddNumberToObject(json_obj, "id", id);id++;
                cJSON_AddNumberToObject(json_obj, "online", devices[i].online);
                cJSON_AddStringToObject(json_obj, "ip", ip);
                cJSON_AddStringToObject(json_obj, "esp_mac", mac_str);
                cJSON_AddNumberToObject(json_obj, "timestamp", (double)now);
                cJSON_AddNumberToObject(json_obj, "TTL", (double)expiration_time);
                char mac_str[18];

                snprintf(mac_str, sizeof(mac_str),
                        "%02X:%02X:%02X:%02X:%02X:%02X",
                        devices[i].mac[0], devices[i].mac[1], devices[i].mac[2],
                        devices[i].mac[3], devices[i].mac[4], devices[i].mac[5]);

                //ESP_LOGI(TAG, "mac = %s", mac_str);

                cJSON_AddStringToObject(json_obj, "mac", mac_str);

                ESP_LOGI(TAG, "device.online = %d, device.mac = %f", devices[i].online, mac_to_double(devices[i].mac));
                //ESP_LOGI("Http_post", "device.ip = "PRIu32, devices[i].ip);

                ESP_LOGI(TAG, "device.ip: %s", ip);

                //cJSON_AddItemToArray(json_array, json_obj);

                ESP_LOGI(TAG, "json_obj = %s", cJSON_Print(json_obj));

                char *json_str = cJSON_PrintUnformatted(json_obj);
                send_post_request(json_str);
                free(json_str);


                cJSON_Delete(json_obj);
                //ESP_LOGI(TAG, "json_array = %s", cJSON_Print(json_array));

                //cJSON_Delete(json_obj);
          }
          id = clona;
          ESP_LOGI(TAG, "json_post = %s", cJSON_Print(json_array));

          // aici trebe trimis jsonu la AWS Lambda

          //cJSON_Delete(json_array);

          commands.do_arp = 0;
        }
        if(commands.send_wol == 1){
            mac_address = cJSON_GetStringValue(cJSON_GetObjectItem(json, "mac"));

            ESP_LOGI(TAG, "mac de trimis = %s", mac_address);
            udp_client_task(mac_address);


            commands.send_wol = 0;
        }
        if(commands.is_online == 1){
            ip_address = cJSON_GetStringValue(cJSON_GetObjectItem(json, "ip"));
            char* id_da = cJSON_GetStringValue(cJSON_GetObjectItem(json, "id"));

            cJSON* json_obj = cJSON_CreateObject();
            ESP_LOGI(TAG, "id extras = %s", id_da);

            ESP_LOGI(TAG, "ip de trimis = %s", ip_address);

            bool online = checkIPStatus(eth_netif, ip_address);

            ESP_LOGI(TAG, "The device is online = %d", online);

            cJSON_AddStringToObject(json_obj, "id", id_da);
            cJSON_AddNumberToObject(json_obj, "online", online);

            send_post_request(cJSON_PrintUnformatted(json_obj));

            commands.is_online = 0;
            cJSON_Delete(json_obj);
        }
        cJSON_Delete(json);
        strcpy(data, "");
    }
}