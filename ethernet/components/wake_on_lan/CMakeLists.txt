idf_component_register(SRCS "wol.c"
                        REQUIRES esp_event nvs_flash esp_eth
                       INCLUDE_DIRS ".")