import os

SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY') or 'your-secret-key-change-this'

BABEL_DEFAULT_LOCALE = "ru"

LANGUAGES = {
    "ru": {"flag": "ru", "name": "Русский"},
    "en": {"flag": "us", "name": "English"}
}
WTF_CSRF_ENABLED = False
SESSION_COOKIE_SAMESITE = None
SESSION_COOKIE_SECURE = False
ENABLE_PROXY_FIX = True
HTML_SANITIZATION = False
TALISMAN_ENABLED = False
FEATURE_FLAGS = {
    "ENABLE_TEMPLATE_PROCESSING": True,
     "TAGGING_SYSTEM": True}
# Отключаем предупреждение о CSP
CONTENT_SECURITY_POLICY_WARNING = False

# Отключаем rate limiting (только для локальной разработки!)
RATELIMIT_ENABLED = False