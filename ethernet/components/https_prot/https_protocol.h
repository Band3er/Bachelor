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
//#include "protocol_examples_common.h"
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

/* Constants that aren't configurable in menuconfig */
#ifdef CONFIG_EXAMPLE_SSL_PROTO_TLS1_3_CLIENT
#define WEB_SERVER "tls13.browserleaks.com"
#define WEB_PORT "443"
#define WEB_URL "https://tls13.browserleaks.com/tls"
#else
#define WEB_SERVER "ed2nge4mtufmvmbvza3bkodfpq0rbfco.lambda-url.eu-central-1.on.aws"
#define WEB_PORT "443"
#define WEB_URL "https://ed2nge4mtufmvmbvza3bkodfpq0rbfco.lambda-url.eu-central-1.on.aws/?id=1"
#endif

#define SERVER_URL_MAX_SZ 256

#define MAX_RESPONSE_SIZE 4096

#define TAG "HTTPS_PROTOCOL"

/* Timer interval once every day (24 Hours) */
#define TIME_PERIOD (86400000000ULL)

static const char HOWSMYSSL_REQUEST[] = "GET " WEB_URL " HTTP/1.1\r\n"
                             "Host: "WEB_SERVER"\r\n"
                             "User-Agent: esp-idf/1.0 esp32\r\n"
                             "\r\n";

#ifdef CONFIG_EXAMPLE_CLIENT_SESSION_TICKETS
static const char LOCAL_SRV_REQUEST[] = "GET " CONFIG_EXAMPLE_LOCAL_SERVER_URL " HTTP/1.1\r\n"
                             "Host: "WEB_SERVER"\r\n"
                             "User-Agent: esp-idf/1.0 esp32\r\n"
                             "\r\n";
#endif

/* Root cert for howsmyssl.com, taken from server_root_cert.pem

   The PEM file was extracted from the output of this command:
   openssl s_client -showcerts -connect www.howsmyssl.com:443 </dev/null

   The CA root cert is the last cert given in the chain of certs.

   To embed it in the app binary, the PEM file is named
   in the component.mk COMPONENT_EMBED_TXTFILES variable.
*/

#if CONFIG_EXAMPLE_USING_ESP_TLS_MBEDTLS
#if defined(CONFIG_EXAMPLE_SSL_PROTO_TLS1_3_CLIENT)
static const int server_supported_ciphersuites[] = {MBEDTLS_TLS1_3_AES_256_GCM_SHA384, MBEDTLS_TLS1_3_AES_128_CCM_SHA256, 0};
static const int server_unsupported_ciphersuites[] = {MBEDTLS_TLS_ECDHE_RSA_WITH_ARIA_128_CBC_SHA256, 0};
#else
static const int server_supported_ciphersuites[] = {MBEDTLS_TLS_RSA_WITH_AES_256_GCM_SHA384, MBEDTLS_TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA256, 0};
static const int server_unsupported_ciphersuites[] = {MBEDTLS_TLS_ECDHE_RSA_WITH_ARIA_128_CBC_SHA256, 0};
#endif // CONFIG_EXAMPLE_SSL_PROTO_TLS1_3_CLIENT
#endif // CONFIG_EXAMPLE_USING_ESP_TLS_MBEDTLS

#ifdef CONFIG_EXAMPLE_CLIENT_SESSION_TICKETS
static esp_tls_client_session_t *tls_client_session = NULL;
static bool save_client_session = false;
#endif

 void https_get_request(esp_tls_cfg_t cfg, const char *WEB_SERVER_URL, const char *REQUEST);

 void https_get_request_using_cacert_buf(void);

 void https_get_request_using_specified_ciphersuites(void);

 void https_get_request_using_global_ca_store(void);

 void https_request_task(void *pvparameters);

 // astas
 static char recv_data[MAX_RESPONSE_SIZE];