idf_component_register( SRCS "main.c"
                        INCLUDE_DIRS "."
                        REQUIRES esp_netif esp_eth wake_on_lan https_prot ethernet_init arp_scan json_c esp_http_client mqtt_ssl process_commands bluetooth
)