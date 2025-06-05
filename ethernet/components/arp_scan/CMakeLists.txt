idf_component_register(SRCS "scan.c"
                       REQUIRES esp_netif nvs_flash esp_eth
                       INCLUDE_DIRS ".")
