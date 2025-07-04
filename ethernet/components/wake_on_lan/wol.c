#include "wol.h"



//#define HOST_IP_ADDR CONFIG_EXAMPLE_PORT
//#define mac 30:65:ec:9e:38:ee

/**
* using port 9
*   as to https://superuser.com/questions/295325/does-it-matter-what-udp-port-a-wol-signal-is-sent-to
*/
#define PORT 9

void udp_client_task(char mac[13]){
    
//char mac[13] = "3065ec9e38ee";
uint8_t magic_packet[102];
memset(magic_packet, 0xFF, 6);

uint8_t target_mac[6];
char slice[3] = {0}; // trebuie 3 pentru terminator null

for (int i = 0; i < 12; i += 2) {
    slice[0] = mac[i];
    slice[1] = mac[i + 1];
    target_mac[i / 2] = (uint8_t)strtol(slice, NULL, 16);
}

for (int i = 0; i < 16; i++) {
    memcpy(&magic_packet[6 + i * 6], target_mac, 6);
}

int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
if (sock < 0) {
    ESP_LOGE(TAG, "Unable to create socket");
}

int broadcastEnable = 1;
setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcastEnable, sizeof(broadcastEnable));

struct sockaddr_in dest_addr;
dest_addr.sin_family = AF_INET;
dest_addr.sin_port = htons(9);
inet_pton(AF_INET, "255.255.255.255", &dest_addr.sin_addr.s_addr);


    int err = sendto(sock, magic_packet, sizeof(magic_packet), 0, (struct sockaddr *)&dest_addr, sizeof(dest_addr));
    if (err < 0) {
        ESP_LOGE(TAG, "Failed to send Wake_on_lan packet err: %d", errno);
    } else {
        ESP_LOGI(TAG, "Wake-on-Lan packet sent successfully");
    }
    //vTaskDelay(2000 / portTICK_PERIOD_MS);


close(sock);    
}