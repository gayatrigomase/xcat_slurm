#! /bin/bash

is_ubuntu=$(test -f /etc/debian_version && echo Y)
[[ -z ${is_ubuntu} ]] && logadm="root:" || logadm="syslog:adm"
chown -R ${logadm} /var/log/xcat/
. /etc/profile.d/xcat.sh
if [[ -d "/xcatdata.NEEDINIT"  ]]; then
    echo "initializing xCAT ..."
    rsync -a /xcatdata.NEEDINIT/ /xcatdata
    mv /xcatdata.NEEDINIT /xcatdata.orig
    xcatconfig -d

    #echo "initializing networks table..."
    xcatconfig -i
    XCATBYPASS=1 tabdump site|grep domain || XCATBYPASS=1 chtab key=domain site.value=example.com

    echo "create symbol link for /root/.xcat..."
    rsync -a /root/.xcat/* /xcatdata/.xcat
    rm -rf /root/.xcat/
    ln -sf -t /root /xcatdata/.xcat

    echo "initializing loop devices..."
    # workaround for no loop device could be used by copycds
    for i in {0..7}
    do
        test -b /dev/loop$i || mknod /dev/loop$i -m0660 b 7 $i
    done
    # workaround for missing `switch_macmap` (#13)
    ln -sf /opt/xcat/bin/xcatclient /opt/xcat/probe/subcmds/bin/switchprobe
fi

export SLURMUSER=900
groupadd -g $SLURMUSER slurm
useradd  -m -c "SLURM workload manager" -d /var/lib/slurm -u $SLURMUSER -g slurm  -s /bin/bash slurm


chown -R munge: /etc/munge
chown -R munge:munge /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge
chmod 0700 /etc/munge/ /var/log/munge/ /var/lib/munge/ /run/munge/
chmod 755 /run/munge


mkdir -p /var/share/slurm/ctld
chown slurm: /var/share/slurm/ctld
chmod 755 /var/share/slurm/ctld
touch /var/log/slurmctld.log
chown slurm: /var/log/slurmctld.log

mkdir -p /var/log/slurm/slurmctld.log
mkdir -p /var/log/slurm/slurmdbd.log
chown -R  slurm:slurm /var/log/slurm
chown -R slurm:slurm /etc/slurm
chown -R munge:munge /etc/munge


cat /etc/motd
HOSTIPS=$(ip -o -4 addr show up|grep -v "\<lo\>"|xargs -I{} expr {} : ".*inet \([0-9.]*\).*")
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"
echo "welcome to Dockerized xCAT, please login with"
[[ -n "$HOSTIPS"  ]] && for i in $HOSTIPS; do echo "   ssh root@$i -p 2200  "; done && echo "The initial password is \"cluster\""
echo "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@"


#read -p "press any key to continue..."
exec /sbin/init
