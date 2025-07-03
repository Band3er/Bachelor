#include "scan.h"

uint32_t deviceCount = 0;
uint32_t maxSubnetDevice = 0;

deviceInfo *deviceInfos;

// switch between the lwip and the normal way of representation of ipv4
uint32_t switch_ip_orientation(uint32_t *ipv4)
{
    uint32_t ip = ((*ipv4 & 0xff000000) >> 24) |
                  ((*ipv4 & 0xff0000) >> 8) |
                  ((*ipv4 & 0xff00) << 8) |
                  ((*ipv4 & 0xff) << 24);
    return ip;
}

// get the next ip in numerical order
void nextIP(esp_ip4_addr_t *ip)
{
    // reconstruct it to normal order
    esp_ip4_addr_t normal_ip;
    normal_ip.addr = switch_ip_orientation(&ip->addr); // switch to the normal way

    // check if ip is the last ip in subnet
    if (normal_ip.addr == UINT32_MAX)
        return;

    // add one to obtain the next ip address location
    normal_ip.addr += (uint32_t)1;
    ip->addr = switch_ip_orientation(&normal_ip.addr); // switch back the lwip way

    return;
}

// get subnet max device
uint32_t getMaxDevice()
{
    return maxSubnetDevice;
}

// get device count
uint32_t getDeviceCount()
{
    return deviceCount;
}

// get database
deviceInfo *getDeviceInfos()
{
    return deviceInfos;
}

void arpScan(esp_netif_t *lwip_netif)
{
    ESP_LOGI(TAG, "Starting ARP scan");

    char char_target[IP4ADDR_STRLEN_MAX];

    struct netif *netif = (struct netif *)esp_netif_get_netif_impl(lwip_netif);
    esp_ip4_addr_t clone;
    clone.addr = netif->ip_addr.u_addr.ip4.addr;
    esp_ip4addr_ntoa(&clone, char_target, IP4ADDR_STRLEN_MAX);
    ESP_LOGI(TAG, "netif->ip_addr.u_addr.ip4.addr = %s", char_target);

    esp_netif_ip_info_t ip_info;
    esp_netif_get_ip_info(lwip_netif, &ip_info);
    esp_ip4addr_ntoa(&ip_info.ip, char_target, IP4ADDR_STRLEN_MAX);
    ESP_LOGI(TAG, "ip_info.ip.addr = %s", char_target);

    esp_ip4_addr_t target_ipp;
    target_ipp.addr = ip_info.netmask.addr & ip_info.ip.addr;
    esp_ip4addr_ntoa(&target_ipp, char_target, IP4ADDR_STRLEN_MAX);
    ESP_LOGI(TAG, "target_ipp.addr = %s", char_target);
    esp_ip4addr_ntoa(&ip_info.netmask, char_target, IP4ADDR_STRLEN_MAX);
    ESP_LOGI(TAG, "ip_info.netmask = %s", char_target);
    esp_ip4addr_ntoa(&ip_info.netmask, char_target, IP4ADDR_STRLEN_MAX);
    ESP_LOGI(TAG, "ip_info.netmask = %s", char_target);

    uint32_t normal_mask = switch_ip_orientation(&ip_info.netmask.addr);
    // esp_ip4addr_ntoa(&normal_mask.addr, char_target, IP4ADDR_STRLEN_MAX);
    // ESP_LOGI(TAG, "normal_mask = %s", char_target);

    maxSubnetDevice = UINT32_MAX - normal_mask - 1;
    ESP_LOGI(TAG, "maxSubnetDevice = %" PRIu32, maxSubnetDevice);

    deviceInfos = calloc(maxSubnetDevice, sizeof(deviceInfo));
    if (deviceInfos == NULL)
    {
        ESP_LOGE(TAG, "Eșec la alocarea memoriei deviceInfos");
        return;
    }
    if (deviceInfos == NULL)
    {
        ESP_LOGI(TAG, "Not enough space");
    }

    deviceInfo *onlineDevices = calloc(maxSubnetDevice, sizeof(deviceInfo));
    if (onlineDevices == NULL)
    {
        ESP_LOGI(TAG, "Not enough space for onlineDevices array");
        return;
    }
    uint32_t deviceIndex = 0;
    while (1 && netif != NULL)
    {
        uint32_t onlineDevicesCount = 0;

        ESP_LOGI(TAG, "%" PRIu32 " ips to scan", maxSubnetDevice);

        char char_target_ip[IP4ADDR_STRLEN_MAX];
        esp_ip4_addr_t target_ip, last_ip;
        target_ip.addr = target_ipp.addr;
        last_ip.addr = (target_ipp.addr) | (~ip_info.netmask.addr);

        while (target_ip.addr != last_ip.addr)
        {
            esp_ip4_addr_t currAddrs[5];
            int currCount = 0;

            for (int i = 0; i < ARP_TABLE_SIZE; i++)
            {
                nextIP(&target_ip); // next ip
                if (target_ip.addr != last_ip.addr)
                {
                    esp_ip4addr_ntoa(&target_ip, char_target_ip, IP4ADDR_STRLEN_MAX);
                    currAddrs[i] = target_ip;
                    ESP_LOGI(TAG, "Success sending ARP to %s", char_target_ip);

                    ip4_addr_t temp;
                    temp.addr = target_ip.addr;
                    etharp_request(netif, &temp);
                    currCount++;
                }
                else
                    break; // ip is last ip in subnet then break
            }
            vTaskDelay(ARPTIMEOUT / portTICK_PERIOD_MS);
            // find received ARP resopnd in ARP table
            for (int i = 0; i < currCount; i++)
            {
                const ip4_addr_t *ipaddr_ret = NULL;
                struct eth_addr *eth_ret = NULL;
                char mac[20], char_currIP[IP4ADDR_STRLEN_MAX];

                unsigned int currentIpCount = switch_ip_orientation(&currAddrs[i].addr) - switch_ip_orientation(&target_ipp.addr) - 1; // calculate No. of ip
                ip4_addr_t temp_curr;
                temp_curr.addr = currAddrs[i].addr;
                if (etharp_find_addr(NULL, &temp_curr, &eth_ret, &ipaddr_ret) != -1)
                { // find in ARP table
                    // print MAC result for ip
                    sprintf(mac, "%02X:%02X:%02X:%02X:%02X:%02X", eth_ret->addr[0], eth_ret->addr[1], eth_ret->addr[2], eth_ret->addr[3], eth_ret->addr[4], eth_ret->addr[5]);
                    esp_ip4addr_ntoa(&currAddrs[i], char_currIP, IP4ADDR_STRLEN_MAX);
                    ESP_LOGI(TAG, "%s's MAC address is %s", char_currIP, mac);
                    onlineDevices[deviceIndex] = (deviceInfo){1, currAddrs[i].addr}; // online + IP
                    memcpy(onlineDevices[deviceIndex].mac, eth_ret->addr, 6);
                    deviceIndex++;
                }
                else
                { // not fount in arp table
                    if (deviceInfos[currentIpCount].online == 1 || deviceInfos[currentIpCount].online == 2)
                    {                                           // previously online
                        deviceInfos[currentIpCount].online = 2; // prvonline
                    }
                    else
                    {
                        deviceInfos[currentIpCount].online = 0; // offline

                        deviceInfos[currentIpCount].ip = currAddrs[i].addr;
                    }
                }
            }
        }

        deviceInfos = onlineDevices;
        deviceCount = deviceIndex; // number of online devices

        ESP_LOGI(TAG, "Stored %" PRIu32 " online devices in compact format", deviceCount);
        break;
    }
    /* Loop End...*/
}

bool checkIPStatus(esp_netif_t *lwip_netif, const char *ip_str_to_check)
{
    ip4_addr_t ip_check;
    ip4addr_aton(ip_str_to_check, &ip_check);

    struct netif *netif = (struct netif *)esp_netif_get_netif_impl(lwip_netif);
    if (!netif)
    {
        ESP_LOGE(TAG, "Netif NULL");
        return false;
    }
    // sterge intrarea ARP din cache (daca exista)
    etharp_cleanup_netif(netif);

    // Trimite cerere ARP catre IP-ul dorit
    etharp_request(netif, &ip_check);
    vTaskDelay(ARPTIMEOUT / portTICK_PERIOD_MS);

    const ip4_addr_t *ipaddr_ret = NULL;
    struct eth_addr *eth_ret = NULL;
    if (etharp_find_addr(NULL, &ip_check, &eth_ret, &ipaddr_ret) != -1)
    {
        char mac[18];
        sprintf(mac, "%02X:%02X:%02X:%02X:%02X:%02X",
                eth_ret->addr[0], eth_ret->addr[1], eth_ret->addr[2],
                eth_ret->addr[3], eth_ret->addr[4], eth_ret->addr[5]);
        ESP_LOGI(TAG, "Dispozitivul %s is online. MAC: %s", ip_str_to_check, mac);
        return true;
    }

    ESP_LOGI(TAG, "The device %s didn't respond to ARP", ip_str_to_check);
    return false;
}
