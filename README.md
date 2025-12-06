<div dir="rtl">

# کانتینر Mihomo برای Mikrotik (پشتیبانی از قوانین ایران)

کانتینر **Mihomo** برای Mikrotik RouterOS آماده استفاده است و یک درگاه تونل پایدار با پشتیبانی از **پورت ترکیبی** (SOCKS + HTTPS روی پورت 10808)، مسیریابی مستقیم برای آی‌پی‌ها و دامنه‌های ایران، و ⚠️ **احراز هویت HWID برای پنل Remnawave** ⚠️ فراهم می‌کند. این کانتینر به صورت خودکار اطلاعات دستگاه مانند مدل، نسخه سیستم‌عامل و شماره سریال را ارسال می‌کند که برای پنل‌هایی که هویت کلاینت را بررسی می‌کنند ضروری است.

## ویژگی‌های کلیدی:
- پورت ترکیبی 10808 (SOCKS + HTTPS)  با پسورد و بدون پسورد
- ⚠️ **احراز هویت HWID برای پنل Remnawave** ⚠️  
- مسیریابی مستقیم برای رنج‌های آی‌پی و دامنه‌های ایران  
- سازگار کامل با سیستم کانتینر Mikrotik RouterOS  
- نصب آسان با دستورات استاندارد RouterOS
- پشتیبانی از وایرگارد
- پشتیبانی از vless reality ولینک ساب </div>

## تنظیمات شبکه:
```
/interface/bridge/add name=containers
/ip/address/add address=172.17.0.1/24 interface=containers
/ip/firewall/nat/add chain=srcnat action=masquerade src-address=172.17.0.0/24
/interface/veth/add name=veth2 address=172.17.0.2/24 gateway=172.17.0.1
/interface/bridge/port add bridge=containers interface=veth2
```

## متغیرهای محیطی (Environment Variables):
قبل از ایجاد کانتینر، این متغیرها را تنظیم کنید تا Mihomo دستگاه Mikrotik شما را شناسایی کرده و به پنل متصل شود:

```
/container envs add list=MIHOMO key=UI_SECRET value=your_password
/container envs add list=MIHOMO key=MIXED_PORT value=10808
/container envs add list=MIHOMO key=CLIENT_USER_AGENT value=Mihomo/1.19.16
/container envs add list=MIHOMO key=CLIENT_DEVICE_MODEL value=your_mikrotik_model
/container envs add list=MIHOMO key=CLIENT_VER_OS value=your_routeros_version
/container envs add list=MIHOMO key=CLIENT_DEVICE_OS value=RouterOS
/container envs add list=MIHOMO key=CLIENT_HWID value=your_mikrotik_serial
/container envs add list=MIHOMO key=SUB1 value=your_subscription_url
/container envs add list=MIHOMO key=MIXED_PORT_AUTH value=user:passwod#اگر یوزرپسورد نمیخواهید خالی بگذارید

```

### گزینه جایگزین:
```
/container envs add list=MIHOMO key=SRV1 value=your_vless_link
```

### نکته:
```
برای دریافت مدل، شماره سریال و نسخه سیستم‌عامل Mikrotik خود از دستور /system/routerboard/print استفاده کنید.
```

## نصب کانتینر:
```
/container add envlists=MIHOMO interface=veth2 logging=no \
remote-image=registry-1.docker.io/samuraii40/mihomo-mikrotik-iranrules \
root-dir=MIHOMO dns=1.1.1.1,1.0.0.1 start-on-boot=yes comment="MIHOMO"
```
در ضمن شما میتونید با منگل کل ترافیک یک کلاینت را تانل کنید و از میهومو عبور بدین
# Mihomo Mikrotik Container (Iran Rules Support)

The **Mihomo** container for Mikrotik RouterOS is ready-to-use and provides a stable tunnel gateway with **mixed-port support** (SOCKS + HTTPS on port 10808), direct routing for Iranian IPs and domains, and ⚠️ **HWID AUTHENTICATION FOR REMNAWAVE PANEL** ⚠️. The container automatically sends device metadata such as model, OS version, and serial number, which is required for panels that validate client identity.

## Key Features
- Mixed port 10808 (SOCKS + HTTPS)  
- ⚠️ **HWID AUTHENTICATION FOR REMNAWAVE PANEL** ⚠️  
- Direct routing for Iranian IP ranges and domains  
- Full compatibility with Mikrotik RouterOS container system  
- Easy deployment using standard RouterOS commands  
- Automatic device detail reporting (model, OS version, serial number, etc.)

## Network Setup
```
/interface/bridge/add name=containers
/ip/address/add address=172.17.0.1/24 interface=containers
/ip/firewall/nat/add chain=srcnat action=masquerade src-address=172.17.0.0/24
/interface/veth/add name=veth2 address=172.17.0.2/24 gateway=172.17.0.1
/interface/bridge/port add bridge=containers interface=veth2
```

## Environment Variables
Before creating the container, set these environment variables so Mihomo can identify your Mikrotik device and authenticate with your panel:

```
/container envs add list=MIHOMO key=UI_SECRET value=your_password
/container envs add list=MIHOMO key=MIXED_PORT value=10808
/container envs add list=MIHOMO key=CLIENT_USER_AGENT value=Mihomo/1.19.16
/container envs add list=MIHOMO key=CLIENT_DEVICE_MODEL value=your_mikrotik_model
/container envs add list=MIHOMO key=CLIENT_VER_OS value=your_routeros_version
/container envs add list=MIHOMO key=CLIENT_DEVICE_OS value=RouterOS
/container envs add list=MIHOMO key=CLIENT_HWID value=your_mikrotik_serial
/container envs add list=MIHOMO key=SUB1 value=your_subscription_url
/container envs add list=MIHOMO key=MIXED_PORT_AUTH value=user:passwod#If you do not want a username and password, leave it empty
```

### Alternative
```
/container envs add list=MIHOMO key=SRV1 value=your_vless_link
```

### Tip
```
Use /system/routerboard/print on your Mikrotik to get model, serial, and OS version for environment variables.
```

## Container Installation
```
/container add envlists=MIHOMO interface=veth2 logging=no \
remote-image=registry-1.docker.io/samuraii40/mihomo-mikrotik-iranrules \
root-dir=MIHOMO dns=1.1.1.1,1.0.0.1 start-on-boot=yes comment="MIHOMO"
```
## For use Wireguard/AmneziaWG 2.0 configs mount awg configurations dir
```
/container mounts add dst=/etc/mihomo/awg name=MIHOMO_AWG src=/docker_configs/mihomo_mikrotik/awg
```
and copy your config files wireguard/amneziawg to mount dir /docker_configs/mihomo_mikrotik/awg
---

**Special thanks to wiktorbgu**

https://hub.docker.com/r/wiktorbgu/mihomo-mikrotik
