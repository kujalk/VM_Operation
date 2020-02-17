<#This script is used to perform functionalities on the VMs that are running on top of standalone ESXI hosts
1. Stop VM
2. Reboot VM
3. Start VM
4. Backup VM (OVF tool must be installed)
5. Restart stuck services in ESXI (Does not affect running VMs)

Developer - K.Janarthanan
Date - 3/2/2020

#>

#Banner
Write-Host "
This script is used for following functionalities on the VMs that are running on top of standalone ESXI hosts
1. Stop VM
2. Reboot VM
3. Start VM
4. Backup VM (OVF tool must be installed)
5. Restart stuck services in ESXI (Does not affect running VMs)

Make sure
  1) You have admin privileges to access ESXI server
  2) Connectivity to ESXI server
  3) SSH is enabled on the ESXI server 
  4) If you are going to take backup (OVF), ensure OVFTool is installed in your base machine

" -ForegroundColor Yellow

$ErrorActionPreference='Stop'
$user_confirm=Read-Host "Press 'y' or 'Y' to proceed with the script "

#User has pressed y or Y
if (($user_confirm -eq "y" ) -or ($user_confirm -eq "Y" ))
{
    
        #Connect to the standalone ESXI hosts
        try{
        $esxi_server=Read-Host -Prompt "Input the IP Address / Name of the ESXI Host "
        Set-PowerCLIConfiguration -Scope User -ParticipateInCEIP $false -Confirm:$false
        Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false


        write-host "`n"
        $credent=Get-Credential
        Connect-VIServer -Server $esxi_server -Credential $credent
        }

        catch{
        Write-Host "Problem in connecting to the ESXI server via PowerCLI" -ForegroundColor Red
        exit
        }

            #List all VMs and proceed
            try
            {
                clear
                Get-VM | select Name, PowerState | Format-Table

                Write-Host "`nWhat are you plannig to do from the following,
                1. Stop VM -> Type 'stop'
                2. Start VM -> Type 'start'
                3. Reboot VM -> Type 'reboot'
                4. Backup VM (OVF) -> Type 'backup'
                5. Restart stuck services in ESXI -> Type 'restart-services'
                " -ForegroundColor Yellow

                $option=Read-Host -Prompt "Type your option "
            
                #Checking option and taking appropriate action
                #Only for stop-start-reboot
                $option_values="stop","start","reboot"
                if ($option_values -contains $option)
                {
                    #Remote Login (SSH)
                    try{
                        #Connect SSH
                        $session_info=New-SSHSession -Computername $esxi_server -Credential $Credent -AcceptKey:$true
                        $session_id=$session_info | select SessionID -ExpandProperty SessionID
                    }
                    
                    catch{
                        write-host "Unable to SSH into Server"
                        exit
                    }
                    
                    try{

                        $name=Read-Host("`nName of the VM ")

                        #Below piece of code is written because most VM names have "[ ]" in it. 
                        #In VMware these characters are excluded in the VM name. To filter use below code

                        $list=($name | Select-String "\[" -AllMatches).Matches.Index
                    
                        $count=0
                    
                        foreach ($i in $list)
                        {
                        $name=$name.Insert(($i+$count),"\")
                        $count+=1
                        }
                    
                        $query="vim-cmd vmsvc/getallvms | grep"
                        $final_query=$query+" '"+$name+"'"
                    
                        
                        $data=(Invoke-SSHCommand -Index $session_id -Command $final_query).Output
                        Write-host "`nOutput ->`n"+$data -ForegroundColor green
                    
                        #Getting ID
                        $final_query=$query+" '"+$name+"'"+" | cut -f 1 -d ' '"
                    
                        $vm_id=(Invoke-SSHCommand -Index $session_id -Command $final_query).Output
                    
                        write-host "`nVM ID of $name is : $vm_id" -ForegroundColor Green
                    }
                    
                    catch{
                        write-host "Something went wrong while getting the VM ID." -ForegroundColor Red 
                        exit
                    }

                    #Check for Stop | Start | Reboot
                    try{
                        if($option -eq "start"){

                            $operation_query="vim-cmd vmsvc/power.on "+$vm_id

                            $op_id=(Invoke-SSHCommand -Index $session_id -Command $operation_query).Output
                    
                            write-host "`nVM $name status : `n$op_id" -ForegroundColor Green
                        }

                        if($option -eq "stop"){

                            $operation_query="vim-cmd vmsvc/power.off "+$vm_id

                            $op_id=(Invoke-SSHCommand -Index $session_id -Command $operation_query).Output
                    
                            write-host "`nVM $name status : `n$op_id" -ForegroundColor Green
                        }

                        if($option -eq "reboot"){

                            $operation_query="vim-cmd vmsvc/power.reboot "+$vm_id

                            $op_id=(Invoke-SSHCommand -Index $session_id -Command $operation_query).Output
                    
                            write-host "`nVM $name status : `n$op_id" -ForegroundColor Green
                        }

                    }

                    catch{
                        write-host "Something went wrong during Power operation of VM" -ForegroundColor Red
                    }

                }

                #Reboot services
                elseif ($option -eq 'restart-services'){

                        try{
                            #Connect SSH
                            $session_info=New-SSHSession -Computername $esxi_server -Credential $Credent -AcceptKey:$true
                            $session_id=$session_info | select SessionID -ExpandProperty SessionID

                            $operation_query="/etc/init.d/hostd restart"

                            $op_status=(Invoke-SSHCommand -Index $session_id -Command $operation_query).Output
                        
                            write-host "`nESXI status : `n$op_status" -ForegroundColor Green
                        }

                        catch{
                            write-host "Something went wrong while restarting the ESXI services" -ForegroundColor Red
                        }                                    
                }

                #Only for backup
                elseif ($option -eq 'backup') {
                    write-host "`nMake sure VM is powered off. You can continue with the script to Power off the VM `n" -ForegroundColor Yellow

                    #Power Off VM
                    #Check OVFTool.exe is the path
                    #Ask for folder location to store OVF
                    #Taking backup

                    #Ask user to provide the location of OVF Tool
                    $ovf_location=Read-Host "Please proivde the location of ovftool.exe ['C:\Program Files\VMware\VMware OVF Tool'] "

                    #Checking whether ovftool is present in the provided location
                    cd $ovf_location

                    if (Test-Path '.\ovftool.exe' -PathType Leaf){

                        try{
                            #Tool is present therefore proceed with backup
                            $vm_name=Read-Host "Please provide the VM name to be backed up "
                            $final_dest=Read-Host "Provide the location to store the backup [E:\VM_Backup]"

                            $plain=[System.Management.Automation.PSCredential]::new('plain',$credent.Password).GetNetworkCredential().Password
                            $bk_query="vi://"+$credent.UserName+":"+$plain+"@"+$esxi_server+"/"+$vm_name

                            Write-Host "`n"
                            #Execute the command
                            .\ovftool.exe $bk_query $final_dest
                        }

                        catch{
                            write-host "
                            Something went wrong while doing backup
                            Please check for following,
                            1. Disconnect ISO device from VM (Change to Physical drive)
                            2. Check the VM name
                            " -ForegroundColor Red
                            exit
                        }
    
                    }

                    else{
                        write-host "ovftool.exe is not exist in the given location. Exiting from the script" -ForegroundColor Red
                    }
            }

                else {
                    write-host "
                    You have not typed it correctly
                    Remeber you are performing some critical operation on the Infrastructure
                    Exiting from the script.
                    " -ForegroundColor Red
                }

            }

            catch
            {
                write-host "Unable to display VM details and their Power states"

            }
}

#User did not press y or Y
else{
    write-host "Exiting from the script"
    exit
}
