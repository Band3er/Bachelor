#include "scan.h"

uint32_t deviceCount = 0;
uint32_t maxSubnetDevice = 0;

deviceInfo* deviceInfos;


// switch between the lwip and the normal way of representation of ipv4
uint32_t switch_ip_orientation (uint32_t *ipv4){
    uint32_t ip =   ((*ipv4 & 0xff000000) >> 24)|\
                    ((*ipv4 & 0xff0000) >> 8)|\
                    ((*ipv4 & 0xff00) << 8)|\
                    ((*ipv4 & 0xff) << 24);
    return ip;
}

// get the next ip in numerical order
void nextIP(esp_ip4_addr_t *ip){
    // reconstruct it to normal order
    esp_ip4_addr_t normal_ip;
    normal_ip.addr = switch_ip_orientation(&ip->addr); // switch to the normal way

    // check if ip is the last ip in subnet
    if(normal_ip.addr == UINT32_MAX) return;

    // add one to obtain the next ip address location
    normal_ip.addr += (uint32_t)1;
    ip->addr = switch_ip_orientation(&normal_ip.addr); // switch back the lwip way

    return;
}

// get subnet max device
uint32_t getMaxDevice(){
    return maxSubnetDevice;
}

// get device count
uint32_t getDeviceCount(){
    return deviceCount;
}

// get database
deviceInfo * getDeviceInfos(){
    return deviceInfos;
}

void arpScan(esp_netif_t *lwip_netif){
    ESP_LOGI(TAG, "Starting ARP scan");

    struct netif *netif = (struct netif *)esp_netif_get_netif_impl(lwip_netif);
    

    esp_netif_ip_info_t ip_info;
    esp_netif_get_ip_info(lwip_netif, &ip_info);

    esp_ip4_addr_t target_ipp;
    target_ipp.addr = ip_info.netmask.addr && ip_info.ip.addr;

    uint32_t normal_mask = switch_ip_orientation(&ip_info.netmask.addr);
    ESP_LOGI(TAG, "normal_mask = %"PRIu32, normal_mask);
    maxSubnetDevice = UINT32_MAX - normal_mask - 1;
    ESP_LOGI(TAG, "maxSubnetDevice = %"PRIu32, maxSubnetDevice);

    deviceInfos = calloc(maxSubnetDevice, sizeof(deviceInfo));
    if(deviceInfos == NULL){
        ESP_LOGI(TAG, "Not enough space");
        //return;
    }

    while(1 && netif != NULL){
        uint32_t onlineDevicesCount = 0;

        ESP_LOGI(TAG, "%" PRIu32 " ips to scan", maxSubnetDevice);

        char char_target_ip[IP4ADDR_STRLEN_MAX];
        esp_ip4_addr_t target_ip, last_ip;
        target_ip.addr = target_ipp.addr;
        last_ip.addr = (target_ipp.addr)|(~ip_info.netmask.addr);

        while(target_ip.addr != last_ip.addr){
            esp_ip4_addr_t currAddrs[5];
            int currCount = 0;

             for(int i=0; i<ARP_TABLE_SIZE; i++){
                nextIP(&target_ip); // next ip
                if(target_ip.addr != last_ip.addr){
                    esp_ip4addr_ntoa(&target_ip, char_target_ip, IP4ADDR_STRLEN_MAX);
                    currAddrs[i] = target_ip;
                    ESP_LOGI(TAG, "Success sending ARP to %s", char_target_ip);

                    ip4_addr_t temp;
                    temp.addr = target_ip.addr;
                    etharp_request(netif, &temp);
                    currCount++;
                }
                else break; // ip is last ip in subnet then break
            }
            vTaskDelay(ARPTIMEOUT / portTICK_PERIOD_MS);
       // find received ARP resopnd in ARP table
            for(int i=0; i<currCount; i++){
                const ip4_addr_t *ipaddr_ret = NULL;
                struct eth_addr *eth_ret = NULL;
                char mac[20], char_currIP[IP4ADDR_STRLEN_MAX];

                unsigned int currentIpCount = switch_ip_orientation(&currAddrs[i].addr) - switch_ip_orientation(&target_ipp.addr) - 1; // calculate No. of ip
                ip4_addr_t temp_curr;
                temp_curr.addr = currAddrs[i].addr;
                if(etharp_find_addr(NULL, &temp_curr, &eth_ret, &ipaddr_ret) != -1){ // find in ARP table
                    // print MAC result for ip
                    sprintf(mac, "%02X:%02X:%02X:%02X:%02X:%02X",eth_ret->addr[0],eth_ret->addr[1],eth_ret->addr[2],eth_ret->addr[3],eth_ret->addr[4],eth_ret->addr[5]);
                    esp_ip4addr_ntoa(&currAddrs[i], char_currIP, IP4ADDR_STRLEN_MAX);
                    ESP_LOGI(TAG, "%s's MAC address is %s", char_currIP, mac);

                    // stroing information to database
                    deviceInfos[currentIpCount] = (deviceInfo){1, currAddrs[i].addr}; // storing online status and ip address specified by ip No.
                    memcpy(deviceInfos[currentIpCount].mac, eth_ret->addr, 6); // storing mac address into database specified by ip No.

                    // count total online device
                    onlineDevicesCount++;
                }
                else{ // not fount in arp table
                    if(deviceInfos[currentIpCount].online == 1){ // previously online
                        deviceInfos[currentIpCount].online = 2; // prvonline
                    }
                    else{
                        deviceInfos[currentIpCount].online = 0; // offline

                        deviceInfos[currentIpCount].ip = currAddrs[i].addr;
                    }
                }
            }
        }

        // update deviceCount
        deviceCount = onlineDevicesCount;

        // print network scanning result
        ESP_LOGI(TAG, "%" PRIu32 " devices are on local network", onlineDevicesCount);

        // wait unti next scan cycle
        ESP_LOGI(TAG, "Sacnner now sleeping");

        /* viewing database */
        
        for(int i=0; i<100; i++){
            if(deviceInfos[i].online == 1){
                ESP_LOGI(TAG, "Online %02X:%02X:%02X:%02X:%02X:%02X",\
                deviceInfos[i].mac[0], deviceInfos[i].mac[1],deviceInfos[i].mac[2],deviceInfos[i].mac[3],deviceInfos[i].mac[4],deviceInfos[i].mac[5]);
            }
        }
        

        // sleeping task until next scan cycle
        vTaskDelay( 10*1000 / portTICK_PERIOD_MS);
    }
    /* Loop End...*/
}
