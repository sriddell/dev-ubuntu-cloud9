#!/bin/bash
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"

apt-get update
apt-get install -y jq python3 python3-pip awscli network-manager-openconnect apt-transport-https ca-certificates curl software-properties-common build-essential python-minimal nodejs npm
mkdir -p /etc/vpnc
wget -O /etc/vpnc/vpnc-script http://git.infradead.org/users/dwmw2/vpnc-scripts.git/blob_plain/HEAD:/vpnc-script
chmod +x /etc/vpnc/vpnc-script

pip3 install virtualenv
virtualenv --python python3 vpn-slice

apt-get update
apt-get upgrade -y

#curl -L https://raw.githubusercontent.com/c9/install/master/install.sh | bash

cat << EOF > /root/connect
echo Run 'source ~/vpn-slice/bin/activate before running this or it will fail'
openconnect -b https://vpn.ellucian.com/okta -s 'vpn-slice git.ellucian.com artifactory.devops.ellucian.com'
EOF
chmod +x /root/connect

cat << EOF > /update-route53-A.json
{
    "Comment": "Update the A record set",
    "Changes": [
      {
        "Action": "UPSERT",
        "ResourceRecordSet": {
          "Name": "shanedev.ar.elluciancloud.com",
          "Type": "A",
          "TTL": 300,
          "ResourceRecords": [
            {
              "Value": "127.0.0.1"
            }
          ]
        }
      }
    ]
  }
EOF

cat << EOF > /set-route53.sh
#!/bin/sh

if [ -z "\$1" ]; then
    echo "IP not given...trying EC2 metadata...";
    IP=\$( curl http://169.254.169.254/latest/meta-data/public-ipv4 )
else
    IP="\$1"
fi
echo "IP to update: $IP"

HOSTED_ZONE_ID=\$( aws route53 list-hosted-zones-by-name | grep -B 1 -e "ar.elluciancloud.com" | sed 's/.*hostedzone\/\([A-Za-z0-9]*\)\".*/\1/' | head -n 1 )
echo "Hosted zone being modified: $HOSTED_ZONE_ID"

INPUT_JSON=\$( cat /update-route53-A.json | sed "s/127\.0\.0\.1/\$IP/" )

# http://docs.aws.amazon.com/cli/latest/reference/route53/change-resource-record-sets.html
# We want to use the string variable command so put the file contents (batch-changes file) in the following JSON
INPUT_JSON="{ \"ChangeBatch\": \$INPUT_JSON }"

aws route53 change-resource-record-sets --hosted-zone-id "\$HOSTED_ZONE_ID" --cli-input-json "\$INPUT_JSON"
EOF

chmod +x  /set-route53.sh

(crontab -l 2>/dev/null; echo "@reboot /set-route53.sh") | crontab -


DEVICE=$(lsblk -dJo NAME,SIZE,MOUNTPOINT | jq --arg storageSize "512G" -r '..|.?|select(.size==$storageSize).name')
#### this has to be fixed, only works if n1 is the device
printf "o\nn\np\n1\n\n\nw\n" | fdisk /dev/$DEVICE
mkfs -t ext4 "/dev/$DEVICE"p1
UUID=$(blkid -s UUID -o value "/dev/$DEVICE"p1)
mkdir /media/home
mount -t ext4 "/dev/$DEVICE"p1 /media/home
rsync -aXS --exclude='/*/.gvfs' /home/. /media/home/.
rm -rf /home
mkdir /home
echo "UUID=$UUID /home    ext4    defaults,discard        0 0" >> /etc/fstab
mount -a

apt-get install -y docker.io
usermod -aG docker ubuntu

reboot
