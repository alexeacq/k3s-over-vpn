# installacion automatica de K3S sobre una red VPN definida 10.13.14.0/24
El siguiente script realiza la instalacion de manera automatica de K3S. 
En el caso de ejecutarlo en una raspberry pi recuerda habilitar cgroup_enable, cgroup_memory, cgroup_hierarchy en el archivo de configuracion:
/boot/firmware/cmdline.txt

El contenido del archivo deberia de quedar mas o menos asi:
console=tty1 root=PARTUUID=a4c375d3-02 rootfstype=ext4 fsck.repair=yes rootwait cgroup_enable=memory cgroup_memory=1 systemd.unified_cgroup_hierarchy=1 cfg80211.ieee80211_regdom=BO
