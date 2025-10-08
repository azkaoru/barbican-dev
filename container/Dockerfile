from rockylinux/rockylinux:9.6-ubi

# Install EPEL repository first
RUN dnf install -y epel-release && \
    dnf install -y centos-release-openstack-epoxy && \
    dnf install -y openstack-keystone openstack-barbican-api python3-mod_wsgi python3-openstackclient python3-psycopg2 nmap-ncat softhsm procps-ng

# /var/lib/softhsmの権限がods:odsのため、barbican ユーザーを ods グループに追加
RUN usermod -aG ods barbican

