**Adding this repository to Gentoo**

* Using eselect-repository (recommended):

        # eselect repository add anyuta1166 git https://github.com/anyuta1166/gentoo-overlay.git

**The repository contents**

*app-misc/mosquitto*

* add systemd USE flag to compile with systemd support if present
* use systemd unit file provided by the upstream

*net-firewall/iptables*

* use custom systemd unit file\
  Gentoo bug: [#555920](https://bugs.gentoo.org/555920) (no answer)

*net-dns/pdns*

* fix configuration directory & file permissions\
  Gentoo bug: [#604920](https://bugs.gentoo.org/604920)
* fix PID file path in OpenRC script\
  Gentoo bug: [#742962](https://bugs.gentoo.org/742962)

*net-misc/netctl*

* continue to maintain package removed from Gentoo tree
