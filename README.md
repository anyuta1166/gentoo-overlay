**Adding this repository to Gentoo**

* Using eselect-repository (recommended):

        # eselect repository add anyuta1166 git https://github.com/anyuta1166/gentoo-overlay.git

* Using layman (deprecated):

        # wget -O /etc/layman/overlays/anyuta1166.xml https://raw.github.com/anyuta1166/gentoo-overlay/master/repo.xml
        # layman -a anyuta1166
