/* Ethernet Basic Example

   This example code is in the Public Domain (or CC0 licensed, at your option.)

   Unless required by applicable law or agreed to in writing, this
   software is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
   CONDITIONS OF ANY KIND, either express or implied.
*/


#include <stdio.h>
#include "esp_netif.h"
#include "lwip/dns.h"
#include "lwip/etharp.h"
#include "lwip/ip4.h"
#include "lwip/ip_addr.h"
#include "lwip/inet.h"

#include "freertos/semphr.h"

#include "esp_eth_driver.h"

#include "wol.h"
#include "ethernet_init.h"
#include "http_requests.h"
#include "scan.h"

#include "cJSON.h"

#define TAG "ethernet_init"

//static const char *TAG = "eth_example";

/** Event handler for Ethernet events */
static void eth_event_handler(void *arg, esp_event_base_t event_base,
                              int32_t event_id, void *event_data)
{
    uint8_t mac_addr[6] = {0};
    /* we can get the ethernet driver handle from event data */
    esp_eth_handle_t eth_handle = *(esp_eth_handle_t *)event_data;

    switch (event_id) {
    case ETHERNET_EVENT_CONNECTED:
        esp_eth_ioctl(eth_handle, ETH_CMD_G_MAC_ADDR, mac_addr);
        ESP_LOGI(TAG, "Ethernet Link Up");
        ESP_LOGI(TAG, "Ethernet HW Addr %02x:%02x:%02x:%02x:%02x:%02x",
                 mac_addr[0], mac_addr[1], mac_addr[2], mac_addr[3], mac_addr[4], mac_addr[5]);
        break;
    case ETHERNET_EVENT_DISCONNECTED:
        ESP_LOGI(TAG, "Ethernet Link Down");
        break;
    case ETHERNET_EVENT_START:
        ESP_LOGI(TAG, "Ethernet Started");
        break;
    case ETHERNET_EVENT_STOP:
        ESP_LOGI(TAG, "Ethernet Stopped");
        break;
    default:
        break;
    }
}

// !!!semafor
SemaphoreHandle_t xSemaphore;


/** Event handler for IP_EVENT_ETH_GOT_IP */
static void got_ip_event_handler(void *arg, esp_event_base_t event_base,
                                 int32_t event_id, void *event_data)
{
    ip_event_got_ip_t *event = (ip_event_got_ip_t *) event_data;
    const esp_netif_ip_info_t *ip_info = &event->ip_info;

    ESP_LOGI(TAG, "Ethernet Got IP Address");
    ESP_LOGI(TAG, "~~~~~~~~~~~");
    ESP_LOGI(TAG, "ETHIP:" IPSTR, IP2STR(&ip_info->ip));
    ESP_LOGI(TAG, "ETHMASK:" IPSTR, IP2STR(&ip_info->netmask));
    ESP_LOGI(TAG, "ETHGW:" IPSTR, IP2STR(&ip_info->gw));
    ESP_LOGI(TAG, "~~~~~~~~~~~");

    xSemaphoreGive(xSemaphore);
}



void vTaskFunction(void *pvParameters){

    esp_netif_t *eth_netif = (esp_netif_t *)pvParameters;
    char recv_buf[512];

    while(1){
    http_get(recv_buf);

    cJSON *json_get = cJSON_Parse(recv_buf);
  
    ESP_LOGI("Http_Recv", "json_get = %s", cJSON_Print(json_get));
        

    command command;
    
    command.do_arp = cJSON_GetNumberValue(cJSON_GetObjectItem(json_get, "do_arp"));
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

    ESP_LOGI("http", "do_arp = %d, send_wol = %d, mac = %s", command.do_arp, command.send_wol, clean_mac);

    // Dacă vrei să convertești la uint8_t[6], o poți face aici:
    //uint8_t mac_bin[6];
    //mac_to_char(clean_mac, mac_bin);  // Presupune că funcția ta e robustă
    // acum ai mac_bin[] pentru WOL/ARP
} else {
    ESP_LOGI("http", "do_arp = %d, send_wol = %d", command.do_arp, command.send_wol);
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
          for(size_t i = 0; i <= 254 && devices[i].online; ++i){
              cJSON* json_obj = cJSON_CreateObject();
              dv.addr = devices[i].ip;
              ip = ip4addr_ntoa(&dv);
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
              //cJSON_Delete(json_obj);
          }
          
          ESP_LOGI("Http_Post", "json_post = %s", cJSON_Print(json_array));
          http_post(json_array);
          cJSON_Delete(json_array);
          command.do_arp = 0;
      } else if(command.send_wol == 1) {
          // set which pc to send the packet
          //udp_client_task(device->mac); - nu e bun oricum
          ESP_LOGI("http", "do_arp = %d, send_wol = %d, mac = %s", command.do_arp, command.send_wol, clean_mac);
        udp_client_task(clean_mac);
        cJSON *json_response = cJSON_CreateObject();
        cJSON_AddStringToObject(json_response, "response", "packet sent");
        http_post(json_response);
        cJSON_Delete(json_response);
        command.send_wol = 0;
      }
      vTaskDelay(pdMS_TO_TICKS(10000));
    }
}



void app_main(void)
{
    xSemaphore = xSemaphoreCreateBinary();
    // Initialize Ethernet driver
    uint8_t eth_port_cnt = 1;
    esp_eth_handle_t *eth_handles;
    ESP_ERROR_CHECK(example_eth_init(&eth_handles, &eth_port_cnt));

    // Initialize TCP/IP network interface aka the esp-netif (should be called only once in application)
    ESP_ERROR_CHECK(esp_netif_init());
    // Create default event loop that running in background
    ESP_ERROR_CHECK(esp_event_loop_create_default());

    esp_netif_t *eth_netifs[eth_port_cnt];
    esp_eth_netif_glue_handle_t eth_netif_glues[eth_port_cnt];

    // Create instance(s) of esp-netif for Ethernet(s)

    // Use ESP_NETIF_DEFAULT_ETH when just one Ethernet interface is used and you don't need to modify
    // default esp-netif configuration parameters.
    esp_netif_config_t cfg = ESP_NETIF_DEFAULT_ETH();
    eth_netifs[0] = esp_netif_new(&cfg);
    eth_netif_glues[0] = esp_eth_new_netif_glue(eth_handles[0]);
    // Attach Ethernet driver to TCP/IP stack
    ESP_ERROR_CHECK(esp_netif_attach(eth_netifs[0], eth_netif_glues[0]));


    // Register user defined event handers
    ESP_ERROR_CHECK(esp_event_handler_register(ETH_EVENT, ESP_EVENT_ANY_ID, &eth_event_handler, NULL));
    ESP_ERROR_CHECK(esp_event_handler_register(IP_EVENT, IP_EVENT_ETH_GOT_IP, &got_ip_event_handler, NULL));

    ESP_ERROR_CHECK(esp_eth_start(eth_handles[0]));

    // Start Ethernet driver state machine

    // ast pana se atribuie ip, daca nu, dupa 10s trece pe ramura de fals
    if (xSemaphoreTake(xSemaphore, pdMS_TO_TICKS(10000)) == pdTRUE) {
        ESP_LOGI("eth", "Conexiune Ethernet stabilită. Continuăm.");
    // Aici poți apela http_get() sau alt cod dependent de conexiune
    } else {
        ESP_LOGE("eth", "Timeout: nu s-a obținut IP de la Ethernet.");
    }
    
    
    


    
    // TODO
    //xTaskCreate(&http_get_post_task, "http_get_post_task", 8192, NULL, 5, NULL);
    //xTaskCreate(arp_scan_task, "arp_scan_task", 4096, NULL, 5, NULL);
    //arp_scan_task(eth_handles[0]);

    //xTaskCreate(&udp_client_task, "udp_client_task", 4096, NULL, 5, NULL);
    xTaskCreate(&vTaskFunction, "arp_wol_task", 4096, eth_netifs[0], 5, NULL);




#if CONFIG_EXAMPLE_ETH_DEINIT_AFTER_S >= 0
    // For demonstration purposes, wait and then deinit Ethernet network
    vTaskDelay(pdMS_TO_TICKS(CONFIG_EXAMPLE_ETH_DEINIT_AFTER_S * 1000));
    ESP_LOGI(TAG, "stop and deinitialize Ethernet network...");
    // Stop Ethernet driver state machine and destroy netif
    for (int i = 0; i < eth_port_cnt; i++) {
        ESP_ERROR_CHECK(esp_eth_stop(eth_handles[i]));
        ESP_ERROR_CHECK(esp_eth_del_netif_glue(eth_netif_glues[i]));
        esp_netif_destroy(eth_netifs[i]);
    }
    esp_netif_deinit();
    ESP_ERROR_CHECK(example_eth_deinit(eth_handles, eth_port_cnt));
    ESP_ERROR_CHECK(esp_event_handler_unregister(IP_EVENT, IP_EVENT_ETH_GOT_IP, got_ip_event_handler));
    ESP_ERROR_CHECK(esp_event_handler_unregister(ETH_EVENT, ESP_EVENT_ANY_ID, eth_event_handler));
    ESP_ERROR_CHECK(esp_event_loop_delete_default());
#endif // EXAMPLE_ETH_DEINIT_AFTER_S > 0
}
