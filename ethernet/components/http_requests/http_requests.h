#pragma once
#include <string.h>
#include <sys/param.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_system.h"
#include "esp_event.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_mac.h"
#include "esp_eth.h"
#include "lwip/err.h"
#include "lwip/sockets.h"
#include "lwip/sys.h"
#include <lwip/netdb.h>
#include "cJSON.h"

#include "scan.h"

#define WEB_SERVER "192.168.100.161"  // change based on the laptop ip
#define WEB_PORT "3000"
#define WEB_PATH "/data"

// test internet conenction
//#define WEB_SERVER "httpbin.org"
//#define WEB_PORT "80"
//#define WEB_PATH "/"

#define TAG "http_requests"

static const char *REQUEST = "GET " WEB_PATH " HTTP/1.0\r\n"
    "Host: "WEB_SERVER":"WEB_PORT"\r\n"
    "User-Agent: esp-idf/1.0 esp32\r\n"
    "\r\n";

typedef struct command {
    bool do_arp;
    bool send_wol;
}command;

void http_get(char recv_buf[128]);
void http_post(cJSON *json);
void http_get_post(void *pvParameters);

double mac_to_double(uint8_t mac[6]);