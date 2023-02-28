#using base image

FROM centos:7.9.2009

MAINTAINER The xCAT Project


#set arg 

ENV container docker

ARG xcat_version=latest
ARG xcat_reporoot=https://xcat.org/files/xcat/repos/yum
ARG xcat_baseos=rh7

RUN (cd /lib/systemd/system/sysinit.target.wants/; \
     for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
        rm -f /lib/systemd/system/multi-user.target.wants/* && \
        rm -f /etc/systemd/system/*.wants/* && \
        rm -f /lib/systemd/system/local-fs.target.wants/* && \
        rm -f /lib/systemd/system/sockets.target.wants/*udev* && \
        rm -f /lib/systemd/system/sockets.target.wants/*initctl* && \
        rm -f /lib/systemd/system/basic.target.wants:/* && \
        rm -f /lib/systemd/system/anaconda.target.wants/*

RUN mkdir -p /xcatdata/etc/{dhcp,goconserver,xcat} && ln -sf -t /etc /xcatdata/etc/{dhcp,goconserver,xcat} && \
    mkdir -p /xcatdata/{install,tftpboot} && ln -sf -t / /xcatdata/{install,tftpboot}

RUN yum install -y -q wget which &&\
    wget ${xcat_reporoot}/${xcat_version}/$([[ "devel" = "${xcat_version}" ]] && echo 'core-snap' || echo 'xcat-core')/xcat-core.repo -O /etc/yum.repos.d/xcat-core.repo  --no-check-certificate && \
    wget ${xcat_reporoot}/${xcat_version}/xcat-dep/${xcat_baseos}/$(uname -m)/xcat-dep.repo -O /etc/yum.repos.d/xcat-dep.repo --no-check-certificate && \
    yum install -y \
       xCAT \
       openssh-server \
       rsyslog \
       createrepo \
       chrony \
       man && \
    yum clean all


RUN sed -i -e 's|#PermitRootLogin yes|PermitRootLogin yes|g' \
           -e 's|#Port 22|Port 2200|g' \
           -e 's|#UseDNS yes|UseDNS no|g' /etc/ssh/sshd_config && \
    echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config && \
    echo "root:cluster" | chpasswd && \
    rm -rf /root/.ssh && \
    mv /xcatdata /xcatdata.NEEDINIT

RUN systemctl enable httpd && \
    systemctl enable sshd && \
    systemctl enable dhcpd && \
    systemctl enable rsyslog && \
    systemctl enable xcatd
# TO INSTALL SLURM 

RUN yum install -y epel-release
RUN yum install -y \
	mariadb-server \
        mariadb-devel \
        munge \ 
        munge-libs \ 
	munge-devel \
	python3 \
	readline-devel \
	pam-devel \	
	perl-ExtUtils-MakeMaker \
	gcc gcc-c++ \
        libtool libtool-ltdl \
        make cmake \
        git \
        pkgconfig \
        sudo \
        automake autoconf \
        yum-utils rpm-build

RUN wget https://download.schedmd.com/slurm/slurm-20.11.9.tar.bz2

#RUN useradd builder -u 1000 -m -G users,wheel && \
#    echo "builder ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers && \
#    echo "# macros"                      >  /home/builder/.rpmmacros && \
#    echo "%_topdir    /home/builder/rpm" >> /home/builder/.rpmmacros && \
#    echo "%_sourcedir %{_topdir}"        >> /home/builder/.rpmmacros && \
#    echo "%_builddir  %{_topdir}"        >> /home/builder/.rpmmacros && \
#    echo "%_specdir   %{_topdir}"        >> /home/builder/.rpmmacros && \
#    echo "%_rpmdir    %{_topdir}"        >> /home/builder/.rpmmacros && \
#    echo "%_srcrpmdir %{_topdir}"        >> /home/builder/.rpmmacros && \
#    mkdir /home/builder/rpm && \
#    chown -R builder /home/builder

#USER builder

#ENV FLAVOR=rpmbuild OS=centos DIST=el7
RUN rpmbuild -ta slurm-20.11.9.tar.bz2
RUN mkdir -p /root/rpmbuild/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
RUN yum localinstall -y /root/rpmbuild/RPMS/x86_64/slurm* 


#CREATE SLURM USER
RUN groupadd -g 900 slurm && useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u 900 -g slurm  -s /bin/bash slurm


ADD entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENV XCATROOT /opt/xcat
ENV PATH="$XCATROOT/bin:$XCATROOT/sbin:$XCATROOT/share/xcat/tools:$PATH" MANPATH="$XCATROOT/share/man:$MANPATH"
VOLUME [ "/xcatdata", "/var/log/xcat" ]
COPY file/slurm.conf /etc/slurm/slurm.conf
COPY file/munge.key  /etc/munge/munge.key

#START THE SERVICES

#CMD ["/run.sh"]

RUN systemctl enable mariadb && \
    systemctl enable munge && \
    systemctl enable slurmctld 

CMD [ "/entrypoint.sh" ]

RUN systemctl enable mariadb && \
    systemctl enable munge && \
    systemctl enable slurmctld

