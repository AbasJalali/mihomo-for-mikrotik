# ==============================================================================
# 1. تنظیمات اولیه و متغیرها (لطفاً مقادیر زیر را ویرایش کنید)
# ==============================================================================
:local MIHOMO_IP "172.17.0.2/24"
:local GATEWAY_IP "172.17.0.1/24"
:local CONTAINER_NET "172.17.0.0/24"
:local MIHOMO_BRIDGE "containers"

# متغیرهای محیطی ثابت شما (که تزریق می‌شوند)
:local UI_SECRET "YOUR_PASSWORD_HERE"           
:local SUB_ADDRESS "https://YOUR_SUB_ADDRESS_HERE" 
:local MIXED_PORT "10808"
:local USER_AGENT "Mihomo/1.19.16"
:local DEVICE_MODEL "mikrotik ax3"
:local VER_OS "7"
:local DEVICE_OS "RouterOS"
:local HWID "HG109YXXYYT"

# لینک‌های خام فایل‌های شما
:local ENTRYPOINT_URL "https://raw.githubusercontent.com/AbasJalali/mihomo-for-mikrotik/refs/heads/main/entrypoint.sh"
:local IMAGE_URL "https://github.com/AbasJalali/mihomo-for-mikrotik/raw/refs/heads/main/mihomoarm64.tar.gz"
:local IMAGE_FILE "mihomoarm64.tar.gz"
:local IMAGE_NAME "mihomo/mihomo" 

:log info "Starting Mihomo Automated Setup Script (Entrypoint Injection)..."

# ==============================================================================
# 2. پاکسازی محیط قبلی
# ==============================================================================
/container remove [find name=MIHOMO]
/ip address remove [find address=$GATEWAY_IP]
/interface bridge remove [find name=$MIHOMO_BRIDGE]
/file remove [find name=awg]
/file remove [find name=entrypoint.sh]
/file remove [find name=$IMAGE_FILE]
:log info "Previous container and files removed."


# ==============================================================================
# 3. دانلود و لود ایمیج و فایل‌های کانفیگ
# ==============================================================================

:log info "Downloading custom image and config files from GitHub..."

# دانلود ایمیج کانتینر
/tool fetch url=$IMAGE_URL dst=$IMAGE_FILE

# لود کردن ایمیج در میکروتیک
/container import file=$IMAGE_FILE

# ایجاد دایرکتوری awg و دانلود فایل‌های کانفیگ/اسکریپت
/file add name=awg type=directory
/tool fetch url=$ENTRYPOINT_URL dst=entrypoint.sh
:log info "Entrypoint script downloaded and image imported successfully."

# ==============================================================================
# 4. تنظیم شبکه (Bridge و NAT)
# ==============================================================================
:log info "Setting up network bridge and NAT..."
/interface bridge add name=$MIHOMO_BRIDGE
/ip address add address=$GATEWAY_IP interface=$MIHOMO_BRIDGE
/ip firewall nat add chain=srcnat action=masquerade src-address=$CONTAINER_NET comment="Mihomo Container NAT"


# ==============================================================================
# 5. ساخت و راه‌اندازی کانتینر با متغیرهای تزریق شده
# ==============================================================================

# ترکیب تمام متغیرهای محیطی
:local finalEnv ("EXTERNAL_CONTROLLER_ADDRESS=0.0.0.0,UI_PORT=9090,LOG_LEVEL=info" . \
    ",UI_SECRET=" . $UI_SECRET . \
    ",MIXED_PORT=" . $MIXED_PORT . \
    ",CLIENT_USER_AGENT=" . $USER_AGENT . \
    ",CLIENT_DEVICE_MODEL=" . $DEVICE_MODEL . \
    ",CLIENT_VER_OS=" . $VER_OS . \
    ",CLIENT_DEVICE_OS=" . $DEVICE_OS . \
    ",CLIENT_HWID=" . $HWID . \
    ",SUB1=" . $SUB_ADDRESS)
:log info "Creating and starting container..."

/container add \
    name=MIHOMO \
    image=$IMAGE_NAME \
    interface=$MIHOMO_BRIDGE \
    address=$MIHOMO_IP \
    veth-mac-address="" \
    hostname="mihomo" \
    root-dir=disk \
    environment=$finalEnv \
    cmd="/entrypoint.sh" # ⬅️ اجرای اسکریپت تزریق شده

/container start MIHOMO
:log info "MIHOMO container created and started successfully!"

# ==============================================================================
# 6. اطلاعات اتصال
# ==============================================================================
:put ""
:put "✅ Setup Complete!"
:put "---------------------------------------"
:put ("Web Panel: http://" . [:pick $MIHOMO_IP 0 ([:find $MIHOMO_IP "/"])] . ":9090")
:put ("Secret: " . $UI_SECRET)
