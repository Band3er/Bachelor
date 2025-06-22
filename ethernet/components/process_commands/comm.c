#include "comm.h"
#include "esp_sntp.h"
#include "time_sync.h"
double mac_to_double(uint8_t mac[6]){
    uint64_t val = 0;
    for(size_t i = 0; i < 6; ++i){
        val = (val << 8) | mac[i];
    }
    return (double)val;
}

//void initialize_sntp(void) {
//    ESP_LOGI(TAG, "Initializing SNTP");
//    esp_sntp_setoperatingmode(SNTP_OPMODE_POLL);
//    esp_sntp_setservername(0, "pool.ntp.org"); // server NTP
//    esp_sntp_init();
//}

void obtain_time(void) {
    esp_sntp_init();

    time_t now = 0;
    struct tm timeinfo = { 0 };
    int retry = 0;
    const int retry_count = 10;

    while (timeinfo.tm_year < (2020 - 1900) && ++retry < retry_count) {
        ESP_LOGI(TAG, "Waiting for system time to be set... (%d/%d)", retry, retry_count);
        vTaskDelay(2000 / portTICK_PERIOD_MS);
        time(&now);
        localtime_r(&now, &timeinfo);
    }
}


#include "esp_bt_device.h"


void vTaskFunction(void *pvParameters){

    xSemaphore_Task = xSemaphoreCreateBinary();
    esp_netif_t *eth_netif = (esp_netif_t *)pvParameters;

    cJSON* json;

    command commands;

    char* mac_address;
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


    // start receiving data from the MQTT
    mqtt_app_start();
    //if (xSemaphoreTake(xSemaphore_Task, portMAX_DELAY) == pdTRUE) {
    //    ESP_LOGI(TAG, "S-a obtinut data de la MQTT");
    //// Aici poți apela http_get() sau alt cod dependent de conexiune
    //} else {
    //    ESP_LOGE(TAG, "S-a obtinut data de la MQTT");
    //}

    while(1){
        while(is_mqtt_data_available()){
            //data = get_mqtt_data();
            strcpy(data, get_mqtt_data());
            
            ESP_LOGI(TAG, "Data received from MQTT: %s", data);
        }

        json = cJSON_Parse(data);

        if(json != NULL){
            ESP_LOGI(TAG, "Data parsed: %s", cJSON_Print(json));
        } else {
            ESP_LOGE(TAG, "Data was not received or parsed correctly");
        }

        commands.do_arp = cJSON_GetNumberValue(cJSON_GetObjectItem(json, "do_arp"));
        commands.send_wol = cJSON_GetNumberValue(cJSON_GetObjectItem(json, "send_wol"));

        //commands.do_arp = 0;
        //commands.send_wol = 0;

        if(commands.do_arp == 1){

            arpScan(eth_netif);
            devices = getDeviceInfos();
            deviceCounts = getDeviceCount(); // online devices
            ESP_LOGI(TAG, "deviceCounts = %" PRIu32, deviceCounts);


            json_array = cJSON_CreateArray();

            for(size_t i = 0; i <= 254 && devices[i].online; ++i){
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

            // set which pc to send the packet
          //udp_client_task(device->mac); - nu e bun oricum
            ESP_LOGI(TAG, "mac de trimis = %s", mac_address);
            udp_client_task(mac_address);

            //cJSON *json_response = cJSON_CreateObject();

            //cJSON_AddStringToObject(json_response, "response", "packet sent");

            //http_post(json_response);
            //send_post_request(const cJSON_PrintUnformatted(json_response));

            //cJSON_Delete(json_response);

            commands.send_wol = 0;
        }
        cJSON_Delete(json);
        //data = NULL;
        strcpy(data, "");
        //free(data);
        vTaskDelay(pdMS_TO_TICKS(10000));
    }
}

/*
void vTaskFunction(void *pvParameters){
    
    esp_netif_t *eth_netif = (esp_netif_t *)pvParameters;
    //char recv_buf[512];
    
    while(1){
         //xSemaphoreTake(xSemaphoreARP, portMAX_DELAY);
    ESP_LOGI("Http_Recv", "I got here actually");

    //cJSON_Delete(json_get_request);

    cJSON *json_get = cJSON_Parse(recv_data);
  
    ESP_LOGI("Http_Recv", "json_get = %s", cJSON_Print(json_get));

    command command;
    
    int id = atoi(cJSON_GetStringValue(cJSON_GetObjectItem(json_get, "id")));
    command.do_arp = atoi(cJSON_GetStringValue(cJSON_GetObjectItem(json_get, "do_arp")));
    command.send_wol = cJSON_GetNumberValue(cJSON_GetObjectItem(json_get, "send_wol"));
    char *mac = cJSON_GetStringValue(cJSON_GetObjectItem(json_get, "mac"));
        char clean_mac[13] = {0};
    if (mac != NULL) {
        // Creează un buffer temporar pentru MAC-ul fără ":".
        //char clean_mac[13] = {0};  // 12 caractere + NULL
        int j = 0;

        for (size_t i = 0; i < strlen(mac) && j < 12; ++i) {
            if (mac[i] != ':') {
                if(mac[i] >= 'A' && mac[i] <= 'Z'){
                    mac[i] += 'a' - 'A';
                }
                clean_mac[j++] = mac[i];
            }
        }

    //ESP_LOGI("http", "id = %d, do_arp = %d, send_wol = %d, mac = %s", id, command.do_arp, command.send_wol, clean_mac);

    // Dacă vrei să convertești la uint8_t[6], o poți face aici:
    //uint8_t mac_bin[6];
    //mac_to_char(clean_mac, mac_bin);  // Presupune că funcția ta e robustă
    // acum ai mac_bin[] pentru WOL/ARP
    } else {
        //ESP_LOGI("http", "id = %d, do_arp = %d, send_wol = ", id, command.do_arp);
    }
    
    //udp_client_task("3065ec9e38ee");
    //print what have i received from the server
    if(command.do_arp == 1){
          uint32_t deviceCounts;
          deviceInfo *devices;
          arpScan(eth_netif);
          devices = getDeviceInfos();
          deviceCounts = getDeviceCount(); // online devices
          ESP_LOGI("Http_Post", "deviceCounts = %" PRIu32, deviceCounts);
          ip4_addr_t dv;
            char *ip;
          cJSON* json_array = cJSON_CreateArray();
          int id = 0;
          for(size_t i = 0; i <= 254 && devices[i].online; ++i){
              cJSON* json_obj = cJSON_CreateObject();
              dv.addr = devices[i].ip;
              ip = ip4addr_ntoa(&dv);
              cJSON_AddNumberToObject(json_obj, "id", id);id++;
              cJSON_AddNumberToObject(json_obj, "online", devices[i].online);
              cJSON_AddStringToObject(json_obj, "ip", ip);
              char mac_str[18];
     
                snprintf(mac_str, sizeof(mac_str),
                        "%02X:%02X:%02X:%02X:%02X:%02X",
                        devices[i].mac[0], devices[i].mac[1], devices[i].mac[2],
                        devices[i].mac[3], devices[i].mac[4], devices[i].mac[5]);

                ESP_LOGI("http_post", "mac = %s", mac_str);
                cJSON_AddStringToObject(json_obj, "mac", mac_str);

              ESP_LOGI("Http_Post", "device.online = %d, device.mac = %f", devices[i].online, mac_to_double(devices[i].mac));
              //ESP_LOGI("Http_post", "device.ip = "PRIu32, devices[i].ip);
              
              ESP_LOGI("Http_post", "device.ip: %s", ip);
              cJSON_AddItemToArray(json_array, json_obj);
              ESP_LOGI("http_post", "json_obj = %s", cJSON_Print(json_obj));
              ESP_LOGI("http_post", "json_array = %s", cJSON_Print(json_array));
              cJSON_Delete(json_obj);
          }
          
          ESP_LOGI("Http_Post", "json_post = %s", cJSON_Print(json_array));
          //http_post(json_array);
          cJSON_Delete(json_array);
          cJSON* json_obj = cJSON_CreateObject();
          cJSON_AddStringToObject(json_obj, "id", "1");
          cJSON_AddStringToObject(json_obj, "do_arp", 0);
          //http_post(json_obj);
          command.do_arp = 0;
      } else if(command.send_wol == 1) {
          // set which pc to send the packet
          //udp_client_task(device->mac); - nu e bun oricum
          //ESP_LOGI("http", "do_arp = %d, send_wol = %d, mac = %s", command.do_arp, command.send_wol, clean_mac);
        udp_client_task(clean_mac);
        cJSON *json_response = cJSON_CreateObject();
        cJSON_AddStringToObject(json_response, "response", "packet sent");
        //http_post(json_response);
        cJSON_Delete(json_response);
        cJSON* json_obj = cJSON_CreateObject();
        cJSON_AddStringToObject(json_obj, "id", "2");
        cJSON_AddStringToObject(json_obj, "send_wol", 0);
        cJSON_AddStringToObject(json_obj, "mac", "0");

        command.send_wol = 0;
      }
      vTaskDelay(pdMS_TO_TICKS(10000));
       //xSemaphoreGive(xSemaphoreHTTPS);
      //vTaskDelete(NULL);
    }
}

*/