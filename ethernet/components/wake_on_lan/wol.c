#include "wol.h"

#define WOL_PORT 9
#define MAC_STRING_LEN 12
#define MAC_BYTES 6
#define MAGIC_PACKET_LEN 102
#define BROADCAST_IP "255.255.255.255"

void udp_client_task(char mac_str[MAC_STRING_LEN + 1]) {
    uint8_t magic_packet[MAGIC_PACKET_LEN] = {0};
    uint8_t target_mac[MAC_BYTES] = {0};
    char byte_str[3] = {0}; // 2 cifre hex + terminator null

    // Headerul pachetului magic: 6 octeti FF
    memset(magic_packet, 0xFF, 6);

    // Convertirea stringului MAC în bytes binari
    for (int i = 0; i < MAC_STRING_LEN; i += 2) {
        byte_str[0] = mac_str[i];
        byte_str[1] = mac_str[i + 1];
        target_mac[i / 2] = (uint8_t)strtol(byte_str, NULL, 16);
    }

    // Pachetul magic conține 16 repetari ale adresei MAC
    for (int i = 0; i < 16; ++i) {
        memcpy(&magic_packet[6 + i * MAC_BYTES], target_mac, MAC_BYTES);
    }

    // Crearea socketului UDP
    int sock = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP);
    if (sock < 0) {
        ESP_LOGE(TAG, "Eroare la crearea socketului UDP");
        return;
    }
    int broadcast = 1;
    // Activarea optiunii de broadcast
    setsockopt(sock, SOL_SOCKET, SO_BROADCAST, &broadcast, sizeof(broadcast));

    // Configurarea adresei de destinatie
    struct sockaddr_in dest_addr = {
        .sin_family = AF_INET,
        .sin_port = htons(WOL_PORT)
    };
    inet_pton(AF_INET, BROADCAST_IP, &dest_addr.sin_addr.s_addr);

    // Trimiterea pachetului
    int err = sendto(sock, magic_packet, sizeof(magic_packet), 0,
                     (struct sockaddr *)&dest_addr, sizeof(dest_addr));
    if (err < 0) {
        ESP_LOGE(TAG, "Trimiterea pachetului WoL a esuat. Cod eroare: %d", errno);
    } else {
        ESP_LOGI(TAG, "Pachet Wake-on-LAN trimis cu succes");
    }

    // Pauza scurta pentru a asigura finalizarea transmiterii
    vTaskDelay(pdMS_TO_TICKS(2000));

    // inchiderea socketului
    close(sock);
}
