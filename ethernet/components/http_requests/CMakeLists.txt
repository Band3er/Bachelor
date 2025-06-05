idf_component_register(SRCS "http_requests.c"
                        REQUIRES nvs_flash esp_eth esp_event arp_scan json_c
                       INCLUDE_DIRS ".")