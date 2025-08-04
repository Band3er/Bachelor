idf_component_register(SRCS "https_protcol.c" "time_sync.c"
                    REQUIRES esp-tls esp_wifi esp_timer nvs_flash
                    INCLUDE_DIRS "."
                    EMBED_TXTFILES server_root_cert.pem
                    )
