# Gentoo builder for the Samsung Galaxy Chromebook Go (SASUKE, Celeron N4500 "Tremont").
# Builds every package as a binary (gpkg) optimized for the Celeron; the Chromebook
# downloads them from the "binhost" service (see compose.yaml).
#
# Heavy data (repositories, sources, packages, kernel) lives in volumes, not in the image:
# the image stays small and can move to another PC by taking just the volumes along.
FROM docker.io/gentoo/stage3:systemd

# Project Portage configuration (same as gentoo/portage in the repo)
COPY gentoo/portage/ /etc/portage/
COPY gentoo/world /var/lib/portage/world
COPY kernel/config-sasuke-6.18.60 /etc/sasuke/kernel.config
COPY kernel/KERNEL_VERSION /etc/sasuke/KERNEL_VERSION
COPY builder/builder.sh /usr/local/bin/builder
COPY builder/repos.conf /etc/portage/repos.conf/sasuke.conf

RUN rm -f /etc/portage/repos.conf/gentoo.conf.default 2>/dev/null; \
    ln -sfn ../../var/db/repos/gentoo/profiles/default/linux/amd64/23.0/desktop/systemd /etc/portage/make.profile; \
    chmod +x /usr/local/bin/builder; \
    printf 'COMMON_FLAGS="-O2 -pipe -march=x86-64-v2 -mtune=tremont"\nMAKEOPTS="-j2"\n' > /etc/portage/cpu.conf && touch /etc/portage/signing.conf

VOLUME ["/var/db/repos", "/var/cache/distfiles", "/var/cache/binpkgs", "/usr/src/build"]
ENTRYPOINT ["/usr/local/bin/builder"]
CMD ["help"]
