Blog - https://scripting4ever.wordpress.com/2020/02/17/script-to-perform-vm-backup-and-power-operations-on-vms-that-are-running-on-top-of-free-licensed-standalone-esxi-hosts/

This script is used to perform functionalities on the VMs that are running on top of standalone ESXI hosts
1. Stop VM
2. Reboot VM
3. Start VM
4. Backup VM (OVF tool must be installed)
5. Restart stuck services in ESXI (Does not affect running VMs)

Dependencies -
1. OVF Tool 4.3
   
   link - https://code.vmware.com/web/tool/4.3.0/ovf

2. POSH
   
   command - Install-Module -Name Posh-SSH (Run as Administrator)
   
   link - https://github.com/darkoperator/Posh-SSH 
   
3. PowerCLI 
   
   command - Install-Module -Name VMware.PowerCLI (Run as Administrator)
   
   link - https://www.powershellgallery.com/packages/VMware.PowerCLI/11.5.0.14912921
   
   
