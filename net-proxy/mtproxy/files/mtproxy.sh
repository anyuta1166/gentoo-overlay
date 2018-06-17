#!/bin/bash
mkdir /var/lib/mtproxy &>/dev/null

if [[ -f /etc/mtproxy.conf ]]; then
	. /etc/mtproxy.conf
fi

: "${LOCAL_PORT:=2398}"
: "${HTTP_PORTS:=443}"
: "${PARAMS:=-M 1}"

SECRET_CMD=""
if [[ -n "$SECRET" ]]; then
	echo "[+] Using the explicitly passed secret: '$SECRET'."
elif [[ -f /var/lib/mtproxy/secret ]]; then
	SECRET="$(cat /var/lib/mtproxy/secret)"
	echo "[+] Using the secret in /var/lib/mtproxy/secret: '$SECRET'."
else
	if [[ -n "$SECRET_COUNT" ]]; then
		if [[ ! ( "$SECRET_COUNT" -ge 1 &&  "$SECRET_COUNT" -le 16 ) ]]; then
			echo "[F] Can generate between 1 and 16 secrets."
			exit 1
		fi
	else
		SECRET_COUNT="1"
	fi

	echo "[+] No secret passed. Will generate $SECRET_COUNT random ones."
	SECRET="$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 | tr -d ' ')"
	for pass in $(seq 2 $SECRET_COUNT); do
		SECRET="$SECRET,$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 | tr -d ' ')"
	done
fi

if echo "$SECRET" | grep -qE '^[0-9a-fA-F]{32}(,[0-9a-fA-F]{32}){,15}$'; then
	SECRET="$(echo "$SECRET" | tr '[:upper:]' '[:lower:]')"
	SECRET_CMD="-S $(echo "$SECRET" | sed 's/,/ -S /g')"
	echo "$SECRET" > /var/lib/mtproxy/secret
else
	echo '[F] Bad secret format: should be 32 hex chars (for 16 bytes) for every secret; secrets should be comma-separated.'
	exit 1
fi

TAG_CMD=""
if [[ -n "$TAG" ]]; then
	echo "[+] Using the explicitly passed tag: '$TAG'."
	if echo "$TAG" | grep -qE '^[0-9a-fA-F]{32}$'; then
		TAG="$(echo "$TAG" | tr '[:upper:]' '[:lower:]')"
		TAG_CMD="-P $TAG"
	else
		echo '[!] Bad tag format: should be 32 hex chars (for 16 bytes).'
		echo '[!] Continuing.'
	fi
fi

curl -m 15 -fs https://core.telegram.org/getProxySecret -o /var/lib/mtproxy/proxy-secret || {
	echo '[F] Cannot download proxy secret from Telegram servers.'
	exit 2
}

curl -m 15 -fs https://core.telegram.org/getProxyConfig -o /var/lib/mtproxy/proxy-multi.conf || {
	echo '[F] Cannot download proxy configuration from Telegram servers.'
	exit 2
}

: "${EXTERNAL_IP:=$(curl -m 15 -fs -4 "https://digitalresistance.dog/myIp")}"
if [[ -z "$EXTERNAL_IP" ]]; then
	echo "[!] Cannot determine external IP address."
fi
: "${INTERNAL_IP:=$(ip -4 route get 8.8.8.8 2>/dev/null | grep '^8\.8\.8\.8\s' | grep -Po 'src\s+\d+\.\d+\.\d+\.\d+' | awk '{print $2}')}"
if [[ -z "$INTERNAL_IP" ]]; then
	echo "[!] Cannot determine internal IP address."
fi

NAT_CMD=""
if [[ -n "$INTERNAL_IP" && -n "$EXTERNAL_IP" && "$INTERNAL_IP" != "$EXTERNAL_IP" ]]; then
	NAT_CMD="--nat-info $INTERNAL_IP:$EXTERNAL_IP"
fi

echo "[*] Final configuration:"
I=1
echo "$SECRET" | tr ',' '\n' | while read S; do
	echo "[*]   Secret $I: $S"
	echo "$HTTP_PORTS" | tr ',' '\n' | while read P; do
		echo "[*]   tg:// link for secret $I auto configuration: tg://proxy?server=${EXTERNAL_IP}&port=${P}&secret=${S}"
		echo "[*]   t.me link for secret $I: https://t.me/proxy?server=${EXTERNAL_IP}&port=${P}&secret=${S}"
	done
	I=$(($I+1))
done

if [[ -n "$TAG_CMD" ]]; then
	echo "[*]   Tag: $TAG"
else
	echo "[*]   Tag: no tag"
fi
if [[ -n "$EXTERNAL_IP" ]]; then
	echo "[*]   External IP: $EXTERNAL_IP"
fi
echo '[+] Starting proxy...'
sleep 1
exec /usr/sbin/mtproto-proxy -u nobody -p $LOCAL_PORT -H $HTTP_PORTS $SECRET_CMD --aes-pwd /var/lib/mtproxy/proxy-secret /var/lib/mtproxy/proxy-multi.conf $NAT_CMD $TAG_CMD $PARAMS
