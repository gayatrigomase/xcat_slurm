#!/bin/bash 

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
