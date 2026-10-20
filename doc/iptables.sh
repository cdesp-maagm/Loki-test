#
# Configurer la translation d'adresses sur un interrogateur.
#
# Conditions typiques d'utilisation :
# * l'interrogateur est relié à un routeur qui n'a pas d'adresse IP publique.
# * l'interrogateur est accessible à distance à travers un VPN.
#
# Les commandes ci-dessous permettent à l'interrogateur de donner accès à
# l'interface web du routeur. Les requêtes provenant du VPN sont redirigées vers
# l'adresse IP du routeur sur le réseau local (typiquement 192.168.1.1) :
# * le port 8080 de l'interrogateur est redirigé vers le port 80 du routeur (HTTP)
# * le port 443 de l'interrogateur est redirigé vers le port 443 du routeur (HTTPS)
#
# Le port 80 de l'interrogateur reste disponible pour sa propre interface web.
#

echo "1" > /proc/sys/net/ipv4/ip_forward

# A priori, pas nécessaire
# /etc/init.d/networking restart

# Translation d'adresse pour HTTP sur le port 8080
iptables -t nat -A PREROUTING -p tcp --dport 8080 -j DNAT --to 192.168.1.1:80

# Translation d'adresse pour HTTPS sur le port 443
iptables -t nat -A PREROUTING -p tcp --dport 443 -j DNAT --to 192.168.1.1:443
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
