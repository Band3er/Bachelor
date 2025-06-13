#pragma once
#include "stdint.h"

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "esp_log.h"
#include "nvs_flash.h"
#include "esp_netif.h"
#include "esp_netif_net_stack.h"
#include "lwip/ip4_addr.h"
#include "lwip/etharp.h"
#include "lwip/ip_addr.h"
#include "scan.h"
#include "esp_eth_driver.h"

#define TAG "arp_scan"

#define ARPTIMEOUT 500 // adjust to be biiger TODO
#define ARP_TABLE_SIZE 5

typedef struct deviceInfo{
    int online;
    uint32_t ip;
    uint8_t mac[6];
} deviceInfo;

void arpScan();
uint32_t getDeviceCount();
deviceInfo * getDeviceInfos();
uint32_t getMaxDevice();