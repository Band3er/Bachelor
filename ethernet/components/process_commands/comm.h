#pragma once
#include <string.h>
#include "esp_netif.h"

#include "cJSON.h"

#include "app_main.h"

#include "scan.h"

#include "https_protocol.h"

#include "wol.h"

void vTaskFunction(void *pvParameters);

typedef struct command {
    int do_arp;
    int send_wol;
    int is_online;
}command;

#define TAG "TASK"