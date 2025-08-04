idf_component_register( SRCS "command.c"
                        INCLUDE_DIRS "."
                        REQUIRES esp_netif bt json_c mqtt_ssl arp_scan https_prot wake_on_lan lwip
)