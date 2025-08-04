idf_component_register(SRCS "mqtt.c"
                    REQUIRES mqtt esp_wifi nvs_flash json_c
                    INCLUDE_DIRS "."
                    EMBED_TXTFILES client.crt client.key aws_root.crt
                    )
