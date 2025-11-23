#!/bin/sh
HWID="${CLIENT_HWID:-}"
DEVICE_OS="${CLIENT_DEVICE_OS:-}"
VER_OS="${CLIENT_VER_OS:-}"
DEVICE_MODEL="${CLIENT_DEVICE_MODEL:-}"
USER_AGENT="${CLIENT_USER_AGENT:-Mihomo/1.19.16}"


if ! lsmod | grep nf_tables >/dev/null 2>&1; then
  export DISABLE_NFTABLES=1
  if apk info -e nftables >/dev/null 2>&1; then
    apk del nftables >/dev/null 2>&1
  fi
else
    if apk info -e iptables iptables-legacy >/dev/null 2>&1; then
      apk del iptables iptables-legacy >/dev/null 2>&1
    fi
fi

DEFAULT_CONFIG=$(cat << 'EOF'
external-controller: $EXTERNAL_CONTROLLER_ADDRESS:$UI_PORT
external-ui: $EXTERNAL_UI_PATH
external-ui-url: $EXTERNAL_UI_URL
secret: $UI_SECRET
unified-delay: true
log-level: $LOG_LEVEL
ipv6: $IPV6

dns:
  enable: true
  use-system-hosts: true
  prefer-h3: true
  enhanced-mode: redir-host
  default-nameserver:
    - https://1.1.1.1/dns-query
  nameserver:
    - https://1.1.1.1/dns-query
  proxy-server-nameserver:
    - https://1.1.1.1/dns-query

proxy-providers:
$PROVIDERS_BLOCK
proxy-groups:
  - name: GLOBAL
    type: select
    use:
$PROVIDERS_LIST


listeners:
  - name: mixed-in
    type: mixed
    port: $MIXED_PORT
  - name: tun-in
    type: tun
    stack: $TUN_STACK
    auto-detect-interface: $TUN_AUTO_DETECT_INTERFACE
    auto-route: $TUN_AUTO_ROUTE
    auto-redirect: $TUN_AUTO_REDIRECT
    inet4-address:
    - $TUN_INET4_ADDRESS
rule-providers:
  ir:
    type: http
    format: yaml
    behavior: domain
    url: "https://raw.githubusercontent.com/Chocolate4U/Iran-clash-rules/release/ir.yaml"
    path: ./ruleset/ir.yaml
    interval: 86400
  ircidr:
    type: http
    format: yaml
    behavior: ipcidr
    url: "https://raw.githubusercontent.com/Chocolate4U/Iran-clash-rules/release/ircidr.yaml"
    path: ./ruleset/ircidr.yaml
    interval: 86400
  private:
    type: http
    format: yaml
    behavior: ipcidr
    url: "https://raw.githubusercontent.com/Chocolate4U/Iran-clash-rules/release/private.yaml"
    path: ./ruleset/private.yaml
    interval: 86400
  irasn:
    type: http
    format: yaml
    behavior: classical
    url: "https://raw.githubusercontent.com/Chocolate4U/Iran-clash-rules/release/irasn.yaml"
    path: ./ruleset/irasn.yaml
    interval: 86400

rules :
  - RULE-SET,private,DIRECT,no-resolve
  - RULE-SET,ir,DIRECT
  - RULE-SET,ircidr,DIRECT
  - RULE-SET,irasn,DIRECT
  - MATCH,GLOBAL
  
EOF
)

AWG_DIR="$WORKDIR/awg"
TEMPLATE_DIR="$WORKDIR/template"
mkdir -p $TEMPLATE_DIR
mkdir -p $AWG_DIR
TEMPLATE_FILE="$TEMPLATE_DIR/$CONFIG"
BACKUP_PATH="$TEMPLATE_DIR/default_config_old.yaml"

if [ "$CONFIG" = "default_config.yaml" ]; then
  has_env_vars=$(env | grep -qE '^(SRV|SUB)[0-9]' && echo 1 || echo 0)
  has_conf_files=$(find "$AWG_DIR" -type f -name '*.conf' 2>/dev/null | grep -q . && echo 1 || echo 0)
  if [ "$has_env_vars" -eq 0 ] && [ "$has_conf_files" -eq 0 ]; then
    echo "No server/subscription variables (SRV*/SUB*) and no *.conf files wireguard/amneziawg in $AWG_DIR. Exiting."
    exit 1
  fi
fi

if [ "$CONFIG" = "default_config.yaml" ]; then
  if [ -f "$TEMPLATE_FILE" ]; then
    if ! diff -q <(echo "$DEFAULT_CONFIG") "$TEMPLATE_FILE" >/dev/null; then
      mv "$TEMPLATE_FILE" "$BACKUP_PATH"
      echo "$DEFAULT_CONFIG" > "$TEMPLATE_FILE"
    fi
  else
    echo "$DEFAULT_CONFIG" > "$TEMPLATE_FILE"
  fi
else
  if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "$DEFAULT_CONFIG" > "$TEMPLATE_FILE"
  fi
fi

UI_URL_CHECK="$WORKDIR/.ui_url"
LAST_UI_URL=$(cat "$UI_URL_CHECK" 2>/dev/null)
if [[ "$EXTERNAL_UI_URL" != "$LAST_UI_URL" ]]; then
  rm -rf "$WORKDIR/$EXTERNAL_UI_PATH"
  echo "$EXTERNAL_UI_URL" > "$UI_URL_CHECK"
fi

parse_awg_config() {
  local config_file="$1"
  local awg_name
  awg_name=$(basename "$config_file" .conf)

  local private_key=$(grep -E "^PrivateKey" "$config_file" | sed 's/^PrivateKey[[:space:]]*=[[:space:]]*//')
  local address=$(grep -E "^Address" "$config_file" | sed 's/^Address[[:space:]]*=[[:space:]]*//')
  address=$(echo "$address" | tr ',' '\n' | grep -v ':' | head -n1)
  local dns=$(grep -E "^DNS" "$config_file" | sed 's/^DNS[[:space:]]*=[[:space:]]*//')
  dns=$(echo "$dns" | tr ',' '\n' | grep -v ':' | sed 's/^ *//;s/ *$//' | paste -sd, -)
  local mtu=$(grep -E "^MTU" "$config_file" | sed 's/^MTU[[:space:]]*=[[:space:]]*//')

  local jc=$(grep -E "^Jc" "$config_file" | sed 's/^Jc[[:space:]]*=[[:space:]]*//')
  local jmin=$(grep -E "^Jmin" "$config_file" | sed 's/^Jmin[[:space:]]*=[[:space:]]*//')
  local jmax=$(grep -E "^Jmax" "$config_file" | sed 's/^Jmax[[:space:]]*=[[:space:]]*//')
  local s1=$(grep -E "^S1" "$config_file" | sed 's/^S1[[:space:]]*=[[:space:]]*//')
  local s2=$(grep -E "^S2" "$config_file" | sed 's/^S2[[:space:]]*=[[:space:]]*//')
  local h1=$(grep -E "^H1" "$config_file" | sed 's/^H1[[:space:]]*=[[:space:]]*//')
  local h2=$(grep -E "^H2" "$config_file" | sed 's/^H2[[:space:]]*=[[:space:]]*//')
  local h3=$(grep -E "^H3" "$config_file" | sed 's/^H3[[:space:]]*=[[:space:]]*//')
  local h4=$(grep -E "^H4" "$config_file" | sed 's/^H4[[:space:]]*=[[:space:]]*//')

  local i1=$(grep -E "^I1" "$config_file" | sed 's/^I1[[:space:]]*=[[:space:]]*//')
  local i2=$(grep -E "^I2" "$config_file" | sed 's/^I2[[:space:]]*=[[:space:]]*//')
  local i3=$(grep -E "^I3" "$config_file" | sed 's/^I3[[:space:]]*=[[:space:]]*//')
  local i4=$(grep -E "^I4" "$config_file" | sed 's/^I4[[:space:]]*=[[:space:]]*//')
  local i5=$(grep -E "^I5" "$config_file" | sed 's/^I5[[:space:]]*=[[:space:]]*//')
  local j1=$(grep -E "^J1" "$config_file" | sed 's/^J1[[:space:]]*=[[:space:]]*//')
  local j2=$(grep -E "^J2" "$config_file" | sed 's/^J2[[:space:]]*=[[:space:]]*//')
  local j3=$(grep -E "^J3" "$config_file" | sed 's/^J3[[:space:]]*=[[:space:]]*//')
  local itime=$(grep -E "^itime" "$config_file" | sed 's/^itime[[:space:]]*=[[:space:]]*//')

  local public_key=$(grep -E "^PublicKey" "$config_file" | sed 's/^PublicKey[[:space:]]*=[[:space:]]*//')
  local psk=$(grep -E "^PresharedKey" "$config_file" | sed 's/^PresharedKey[[:space:]]*=[[:space:]]*//')
  local endpoint=$(grep -E "^Endpoint" "$config_file" | sed 's/^Endpoint[[:space:]]*=[[:space:]]*//')
  local server=$(echo "$endpoint" | cut -d':' -f1)
  local port=$(echo "$endpoint" | cut -d':' -f2)

  cat <<EOF | awk 'NF'
  - name: "$awg_name"
    type: wireguard
    private-key: $private_key
    server: $server
    port: $port
    ip: $address
    mtu: ${mtu:-1420}
    public-key: $public_key
    allowed-ips: ['0.0.0.0/0']
  $(if [ -n "$psk" ]; then echo "    pre-shared-key: $psk"; fi)
    udp: true
    dns: [ $dns ]
    remote-dns-resolve: true
    amnezia-wg-option:
      jc: ${jc:-120}
      jmin: ${jmin:-23}
      jmax: ${jmax:-911}
      s1: ${s1:-0}
      s2: ${s2:-0}
      h1: ${h1:-1}
      h2: ${h2:-2}
      h3: ${h3:-3}
      h4: ${h4:-4}
      i1: "${i1:-""}"
      i2: "${i2:-""}"
      i3: "${i3:-""}"
      i4: "${i4:-""}"
      i5: "${i5:-""}"
      j1: "${j1:-""}"
      j2: "${j2:-""}"
      j3: "${j3:-""}"
      itime: ${itime:-"0"}
EOF
}

add_provider_block() {
    local name="$1"
    local path="$2"

    PROVIDERS_BLOCK="${PROVIDERS_BLOCK}  ${name}:
    type: file
    path: ${path}
    health-check:
      enable: true
      url: $HEALTH_CHECK_URL
      interval: 300
      timeout: 5000
      lazy: true
      expected-status: 204
"
    PROVIDERS_LIST="${PROVIDERS_LIST}      - ${name}
"
}

PROVIDERS_BLOCK=""
PROVIDERS_LIST=""
####
srv_file="$WORKDIR/srv.yaml"
if env | grep -qE '^(SRV)[0-9]'; then
> "$srv_file"
env | while IFS='=' read -r name value; do
    case "$name" in
        SRV[0-9]*)
            echo "#== $name ==" >> "$srv_file"
            printf "%s\n" "$value" | while IFS= read -r line; do
                echo "$line" >> "$srv_file"
            done
            ;;
    esac
done

add_provider_block "SRV" "$srv_file"

fi
###
awg_file="$WORKDIR/awg.yaml"
if find "$AWG_DIR" -name "*.conf" | grep -q . 2>/dev/null; then
    echo "proxies:" > "$awg_file"
    find "$AWG_DIR" -name "*.conf" | while read -r conf; do
      parse_awg_config "$conf"
    done >> $awg_file

add_provider_block "AWG" "$awg_file"

fi
###

while IFS='=' read -r name value; do
  case "$name" in
    SUB[0-9]*)
      PROVIDERS_BLOCK="${PROVIDERS_BLOCK}  ${name}:
    url: \"${value}\"
    type: http
    interval: 3600
"
      if [ -n "$HWID" ] || [ -n "$DEVICE_OS" ] || [ -n "$VER_OS" ] || [ -n "$DEVICE_MODEL" ] || [ -n "$USER_AGENT" ]; then
        PROVIDERS_BLOCK="${PROVIDERS_BLOCK}    header:
"
        [ -n "$HWID" ] && PROVIDERS_BLOCK="${PROVIDERS_BLOCK}      X-HWID:
      - \"${HWID}\"
"
        [ -n "$DEVICE_OS" ] && PROVIDERS_BLOCK="${PROVIDERS_BLOCK}      X-Device-OS:
      - \"${DEVICE_OS}\"
"
        [ -n "$VER_OS" ] && PROVIDERS_BLOCK="${PROVIDERS_BLOCK}      X-Ver-OS:
      - \"${VER_OS}\"
"
        [ -n "$DEVICE_MODEL" ] && PROVIDERS_BLOCK="${PROVIDERS_BLOCK}      X-Device-Model:
      - \"${DEVICE_MODEL}\"
"
        [ -n "$USER_AGENT" ] && PROVIDERS_BLOCK="${PROVIDERS_BLOCK}      User-Agent:
      - \"${USER_AGENT}\"
"
      fi
      
      PROVIDERS_BLOCK="${PROVIDERS_BLOCK}    health-check:
      enable: true
      url: \"${HEALTH_CHECK_URL}\"
      interval: 300
      timeout: 5000
      lazy: true
      expected-status: 204
"
    PROVIDERS_LIST="${PROVIDERS_LIST}      - ${name}
"
      ;;
  esac
done <<EOF
$(env)
EOF

export PROVIDERS_BLOCK
export PROVIDERS_LIST

envsubst < "$TEMPLATE_DIR/$CONFIG" > "$WORKDIR/$CONFIG"

CMD_MIHOMO="${@:-"-d $WORKDIR -f $WORKDIR/$CONFIG"}"
mihomo -v
exec mihomo $CMD_MIHOMO || exit 1