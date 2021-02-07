**Adding this repository to Gentoo**

* Using eselect-repository (recommended):

        # eselect repository add anyuta1166 git https://github.com/anyuta1166/gentoo-overlay.git

**The repository contents**

*app-misc/mosquitto*

* add systemd USE flag to compile with systemd support if present
* use systemd unit file provided by the upstream

*dev-erlang/\**

* maintain ejabberd dependencies

*dev-lang/erlang*

* version bump

*dev-lang/php*

* add the patch by Manuel Mausz to fix the many years old bug [#53611](https://bugs.php.net/bug.php?id=53611) (fastcgi_param PHP_VALUE pollutes other sites)
* add the patch by Manuel Mausz that changes the mode of PHP_VALUE from ZEND_INI_USER to ZEND_INI_PERDIR and disables PHP_ADMIN_VALUE

*net-firewall/iptables*

* use custom systemd unit file\
  Gentoo bug: [#555920](https://bugs.gentoo.org/555920)

*net-dns/pdns*

* fix /etc/powerdns permissions\
  Gentoo bug: [#604920](https://bugs.gentoo.org/604920)

*net-im/ejabberd*

* maintain ejabberd

*net-misc/netctl*

* maintain the package that was removed from Gentoo tree

*net-proxy/shadowsocks-libev*

* use original sample config file
