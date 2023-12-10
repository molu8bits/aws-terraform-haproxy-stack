#!/bin/bash
echo "10.230.1.10 haproxy-a.local haproxy-a" | tee -a /etc/hosts
echo "10.230.1.20 haproxy-b.local haproxy-b" | tee -a /etc/hosts
echo "10.230.2.110 web-a.local web-a" | tee -a /etc/hosts
echo "10.230.2.120 web-b.local web-b" | tee -a /etc/hosts
echo "10.230.2.130 web-c.local web-c" | tee -a /etc/hosts
apt-get update
apt-get upgrade -y
apt-get install -y apache2 php libapache2-mod-php
sed -i 's/^LogFormat "%%h/LogFormat "%%{X-Forwarded-For}i %%h/g' /etc/apache2/apache2.conf
a2enmod ssl
systemctl enable apache2
systemctl restart apache2
hostnamectl set-hostname ${vm_name}.local

mv /var/www/html/index.html /var/www/html/index.html.RENAMED

VM_NAME=${vm_name}

case $VM_NAME in
  web-a)
    export COLOR=red
    ;;
  web-b)
    export COLOR=blue
    ;;
  web-c)
    export COLOR=green
    ;;
  *)
    export COLOR=yellow
    ;;
esac

cat > /var/www/html/index.php <<EOF
<h2>
<center>
<br>
<font color=$COLOR>
<?php
echo gethostname();
?>

</font>
</center>
</h2>
EOF


reboot
