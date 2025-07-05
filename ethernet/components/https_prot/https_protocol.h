#include <string.h>
#include <stdlib.h>
#include <inttypes.h>
#include <time.h>
#include <sys/time.h>
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"
#include "esp_wifi.h"
#include "esp_event.h"
#include "esp_log.h"
#include "esp_system.h"
#include "esp_timer.h"
#include "nvs_flash.h"
#include "nvs.h"
#include "esp_sntp.h"
#include "esp_netif.h"

#include "lwip/err.h"
#include "lwip/sockets.h"
#include "lwip/sys.h"
#include "lwip/netdb.h"
#include "lwip/dns.h"

#include "esp_tls.h"
#include "sdkconfig.h"
#if CONFIG_MBEDTLS_CERTIFICATE_BUNDLE && CONFIG_EXAMPLE_USING_ESP_TLS_MBEDTLS
#include "esp_crt_bundle.h"
#endif
#include "time_sync.h"

#define WEB_SERVER "b7ebk4fv7rmbccprt4uusoutuu0ybmag.lambda-url.eu-central-1.on.aws"
#define WEB_PORT "443"
#define WEB_URL_POST "https://b7ebk4fv7rmbccprt4uusoutuu0ybmag.lambda-url.eu-central-1.on.aws/"

#define SERVER_URL_MAX_SZ 256

#define MAX_RESPONSE_SIZE 4096

#define TAG "HTTPS_PROTOCOL"

/* Timer interval once every day (24 Hours) */
#define TIME_PERIOD (86400000000ULL)

void https_get_request(esp_tls_cfg_t cfg, const char *WEB_SERVER_URL, const char *REQUEST);

void https_get_request_using_cacert_buf(void);

void https_get_request_using_specified_ciphersuites(void);

void https_get_request_using_global_ca_store(void);

void https_request_task(void *pvparameters);

void send_post_request(char* data_send);