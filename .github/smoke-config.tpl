{
    "suite_name": "CF_SMOKE_TESTS",
    "skip_ssl_validation": true,
    "api": "api.${CF_DOMAIN}",
    "apps_domain": "apps.${CF_DOMAIN}",
    "user": "ccadmin",
    "password": "${CC_ADMIN_PASSWORD}",
    "cleanup": true,
    "enable_windows_tests": false,
    "enable_isolation_segment_tests": false
}