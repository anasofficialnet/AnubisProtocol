$ErrorActionPreference = "Continue"
$VBox = "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe"
$vmName = "AnubisProtocol-CTF"
$projDir = "c:\Users\Thinkpad\Desktop\tressure"
$buildDir = "$projDir\ova-build"
$iso = "$buildDir\alpine-virt-3.19.4-x86_64.iso"
$vdi = "$buildDir\ctf-disk.vdi"
$ova = "$projDir\AnubisProtocol.ova"
$script:sshPort = 2222

# ═══════════════════════════════════════
# SSH HELPER
# ═══════════════════════════════════════
Add-Type -TypeDefinition @"
using System;using System.Diagnostics;using System.IO;
public class SB{
public static string Run(string cmd, string pw, int port, int timeout){
string af = Path.GetTempFileName() + ".cmd"; File.WriteAllText(af, "@echo " + pw);
var si = new ProcessStartInfo("ssh");
si.Arguments = "-o StrictHostKeyChecking=no -o ConnectTimeout=120 -o ServerAliveInterval=30 -o ServerAliveCountMax=10 -p " + port + " root@127.0.0.1 " + cmd;
si.UseShellExecute = false; si.RedirectStandardInput = true; si.RedirectStandardOutput = true; si.RedirectStandardError = true; si.CreateNoWindow = true;
si.Environment["SSH_ASKPASS_REQUIRE"] = "force"; si.Environment["SSH_ASKPASS"] = af; si.Environment["DISPLAY"] = ":0";
var p = Process.Start(si); p.StandardInput.Close(); bool ok = p.WaitForExit(timeout);
string r = ok ? "EXIT:" + p.ExitCode + "|" + p.StandardOutput.ReadToEnd() + p.StandardError.ReadToEnd() : "TIMEOUT";
try { File.Delete(af); } catch {} return r; }
public static void Send(string remoteCmd, string localFile, string pw, int port, int timeout){
string af = Path.GetTempFileName() + ".cmd"; File.WriteAllText(af, "@echo " + pw);
var si = new ProcessStartInfo("ssh");
si.Arguments = "-o StrictHostKeyChecking=no -o ConnectTimeout=120 -o ServerAliveInterval=30 -o ServerAliveCountMax=10 -p " + port + " root@127.0.0.1 " + remoteCmd;
si.UseShellExecute = false; si.RedirectStandardInput = true; si.RedirectStandardOutput = true; si.RedirectStandardError = true; si.CreateNoWindow = true;
si.Environment["SSH_ASKPASS_REQUIRE"] = "force"; si.Environment["SSH_ASKPASS"] = af; si.Environment["DISPLAY"] = ":0";
var p = Process.Start(si); byte[] data = File.ReadAllBytes(localFile);
p.StandardInput.BaseStream.Write(data, 0, data.Length); p.StandardInput.Close(); p.WaitForExit(timeout);
try { File.Delete(af); } catch {} } }
"@ -Language CSharp -ErrorAction Stop

function S([string]$cmd, [int]$t=60000) {
    $r = [SB]::Run("""$cmd""", "toor", $script:sshPort, $t)
    if ($r -match "^EXIT:0") { Write-Host "  OK" -F Green -NoNewline; Write-Host " $cmd" }
    else { Write-Host "  FAIL" -F Red -NoNewline; Write-Host " $cmd" }
    return $r
}

# ═══════════════════════════════════════
# KEYBOARD HELPER
# ═══════════════════════════════════════
function TT($t){
    $m=@{'a'=0x1e;'b'=0x30;'c'=0x2e;'d'=0x20;'e'=0x12;'f'=0x21;'g'=0x22;'h'=0x23;'i'=0x17;'j'=0x24;'k'=0x25;'l'=0x26;'m'=0x32;'n'=0x31;'o'=0x18;'p'=0x19;'q'=0x10;'r'=0x13;'s'=0x1f;'t'=0x14;'u'=0x16;'v'=0x2f;'w'=0x11;'x'=0x2d;'y'=0x15;'z'=0x2c;'1'=0x02;'2'=0x03;'3'=0x04;'4'=0x05;'5'=0x06;'6'=0x07;'7'=0x08;'8'=0x09;'9'=0x0a;'0'=0x0b;'-'=0x0c;'='=0x0d;' '=0x39;'.'=0x34;'/'=0x35;','=0x33}
    $s=@{'!'=0x02;'@'=0x03;'#'=0x04;'$'=0x05;'%'=0x06;'^'=0x07;'&'=0x08;'*'=0x09;'('=0x0a;')'=0x0b;'_'=0x0c;'+'=0x0d;'|'=0x2b;':'=0x27;'"'=0x28;'>'=0x34;'<'=0x33;'?'=0x35}
    foreach($c in $t.ToCharArray()){
        $k=$c.ToString().ToLower(); $u=($c -cmatch '[A-Z]'); $al=@()
        if($u -and $m.ContainsKey($k)){$al+=@(0x2a,$m[$k])}
        elseif($s.ContainsKey([string]$c)){$al+=@(0x2a,$s[[string]$c])}
        elseif($m.ContainsKey([string]$c)){$al+=@($m[[string]$c])}
        if($al.Count -gt 0){$sc=@();foreach($x in $al){$sc+=("{0:x2}" -f $x)};foreach($x in $al){$sc+=("{0:x2}" -f ($x+0x80))};& $VBox controlvm $vmName keyboardputscancode $sc 2>$null}
        Start-Sleep -Milliseconds 100
    }
}
function PR{& $VBox controlvm $vmName keyboardputscancode 1c 9c 2>$null;Start-Sleep -Milliseconds 800}
function T($text,$wait=5){TT $text;PR;Start-Sleep -Seconds $wait}

# ═══════════════════════════════════════
# PHASE 1: CLEANUP + CREATE VM
# ═══════════════════════════════════════
Write-Host "`n[1/8] CREATE VM" -F Cyan
& $VBox controlvm $vmName poweroff 2>$null; Start-Sleep 2
& $VBox unregistervm $vmName --delete 2>$null; Start-Sleep 2
Remove-Item "C:\Users\Thinkpad\VirtualBox VMs\$vmName" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item $vdi -Force -ErrorAction SilentlyContinue
Remove-Item $ova -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

if (!(Test-Path $iso)) {
    Write-Host "  Downloading Alpine ISO..."
    curl.exe -L -s -o $iso "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.4-x86_64.iso"
}
if ((Get-Item $iso).Length -lt 50000000) { Write-Host "  ISO too small, re-downloading..."; curl.exe -L -o $iso "https://dl-cdn.alpinelinux.org/alpine/v3.19/releases/x86_64/alpine-virt-3.19.4-x86_64.iso" }
Write-Host "  ISO: $([math]::Round((Get-Item $iso).Length/1MB))MB"

& $VBox createmedium disk --filename $vdi --size 8192 --format VDI 2>&1 | Out-Null
& $VBox createvm --name $vmName --ostype Linux_64 --register 2>&1 | Out-Null
& $VBox modifyvm $vmName --memory 2048 --cpus 1 --audio-driver none --nic1 nat 2>&1 | Out-Null
& $VBox modifyvm $vmName --natpf1 "ssh,tcp,,2222,,22" 2>&1 | Out-Null
& $VBox storagectl $vmName --name "IDE" --add ide 2>&1 | Out-Null
& $VBox storageattach $vmName --storagectl "IDE" --port 0 --device 0 --type hdd --medium $vdi 2>&1 | Out-Null
& $VBox storageattach $vmName --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium $iso 2>&1 | Out-Null
& $VBox modifyvm $vmName --boot1 dvd --boot2 disk 2>&1 | Out-Null
& $VBox startvm $vmName --type headless 2>&1 | Out-Null
Write-Host "  VM created, booting 120s..."
Start-Sleep 120

# ═══════════════════════════════════════
# PHASE 2: LIVE CD SSH SETUP
# ═══════════════════════════════════════
Write-Host "`n[2/8] LIVE CD SSH" -F Cyan
T "root" 5
T "echo root:toor | chpasswd" 3
T "ifconfig eth0 up" 3
T "udhcpc -i eth0" 8
T "apk add openssh-server" 20
T "ssh-keygen -A" 5
T "echo PermitRootLogin yes > /etc/ssh/sshd_config" 3
T "echo PasswordAuthentication yes >> /etc/ssh/sshd_config" 3
T "echo UseDNS no >> /etc/ssh/sshd_config" 3
T "/usr/sbin/sshd" 5
ssh-keygen -R "[127.0.0.1]:2222" 2>$null
$r = [SB]::Run('"hostname"', "toor", 2222, 60000)
if ($r -notmatch "^EXIT:0") { Write-Host "  SSH FAILED: $r" -F Red; exit 1 }
Write-Host "  SSH OK!" -F Green

# ═══════════════════════════════════════
# PHASE 3: INSTALL TO DISK
# ═══════════════════════════════════════
Write-Host "`n[3/8] INSTALL TO DISK" -F Cyan
S "echo http://dl-cdn.alpinelinux.org/alpine/v3.19/main > /etc/apk/repositories"
S "echo http://dl-cdn.alpinelinux.org/alpine/v3.19/community >> /etc/apk/repositories"
S "apk update 2>&1 | tail -1" 30000
Write-Host "  setup-disk (takes ~2min)..."
S "echo y | setup-disk -m sys /dev/sda 2>&1 | tail -3" 900000

# ═══════════════════════════════════════
# PHASE 4: CONFIGURE
# ═══════════════════════════════════════
Write-Host "`n[4/8] CONFIGURE" -F Cyan
S "mount /dev/sda3 /mnt 2>/dev/null; mount /dev/sda1 /mnt/boot 2>/dev/null; mount -o bind /dev /mnt/dev; mount -o bind /proc /mnt/proc; mount -o bind /sys /mnt/sys; echo ok"
S "printf 'auto lo\niface lo inet loopback\n\nauto eth0\niface eth0 inet dhcp\n\nauto eth1\niface eth1 inet dhcp\n' > /mnt/etc/network/interfaces"
S "echo anubis > /mnt/etc/hostname && echo '127.0.0.1 anubis localhost' > /mnt/etc/hosts && echo nameserver 8.8.8.8 > /mnt/etc/resolv.conf"
S "echo http://dl-cdn.alpinelinux.org/alpine/v3.19/main > /mnt/etc/apk/repositories && echo http://dl-cdn.alpinelinux.org/alpine/v3.19/community >> /mnt/etc/apk/repositories"
S "printf 'Port 22\nPermitRootLogin yes\nPasswordAuthentication yes\nUseDNS no\nAddressFamily inet\nHostKey /etc/ssh/ssh_host_rsa_key\nHostKey /etc/ssh/ssh_host_ed25519_key\nSubsystem sftp /usr/lib/ssh/sftp-server\n' > /mnt/etc/ssh/sshd_config"
S "chroot /mnt sh -c 'echo root:toor | chpasswd'" 15000
S "chroot /mnt ssh-keygen -A 2>&1 | tail -1" 15000
S "chroot /mnt rc-update add networking boot 2>&1" 10000
S "chroot /mnt rc-update add sshd default 2>&1" 10000
S "printf '/dev/sda3\t/\text4\tdefaults\t0 1\n/dev/sda1\t/boot\text4\tdefaults\t0 2\n/dev/sda2\tswap\tswap\tdefaults\t0 0\n' > /mnt/etc/fstab"
$ipScript = "#!/bin/sh`nsleep 5`nIP=`$(ip -4 addr show 2>/dev/null | grep inet | grep -v 127.0.0.1 | awk '{print `$2}' | cut -d/ -f1 | head -1)`nprintf `"\n ====================================\n   THE ANUBIS PROTOCOL - CTF\n ====================================\n   IP: `${IP:-no network}\n   Ports: 22(SSH) 80(HTTP) 21(FTP)\n ====================================\n\n`" > /etc/issue"
$ipB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($ipScript))
S "mkdir -p /mnt/etc/local.d && echo $ipB64 | base64 -d > /mnt/etc/local.d/show-ip.start && chmod +x /mnt/etc/local.d/show-ip.start"
S "chroot /mnt rc-update add local default 2>&1" 10000
S "umount /mnt/sys /mnt/proc /mnt/dev /mnt/boot /mnt 2>&1"
Write-Host "  Config done!" -F Green

# ═══════════════════════════════════════
# PHASE 5: BOOT FROM DISK
# ═══════════════════════════════════════
Write-Host "`n[5/8] DISK BOOT" -F Cyan
S "poweroff" 5000; Start-Sleep 10
& $VBox controlvm $vmName poweroff 2>$null; Start-Sleep 5
& $VBox storageattach $vmName --storagectl "IDE" --port 1 --device 0 --type dvddrive --medium emptydrive 2>&1 | Out-Null
& $VBox modifyvm $vmName --boot1 disk --boot2 none 2>&1 | Out-Null
& $VBox startvm $vmName --type headless 2>&1 | Out-Null
Write-Host "  Booting 60s..."
Start-Sleep 60
ssh-keygen -R "[127.0.0.1]:$($script:sshPort)" 2>$null
$r = S "hostname" 120000
if ($r -notmatch "^EXIT:0") { Write-Host "  BOOT FAILED!" -F Red; exit 1 }
Write-Host "  Disk boot OK!" -F Green

# ═══════════════════════════════════════
# PHASE 6: DOCKER + CONTAINERS
# ═══════════════════════════════════════
Write-Host "`n[6/8] DOCKER" -F Cyan
S "apk update 2>&1 | tail -1" 30000
S "apk add docker docker-compose iptables 2>&1 | tail -3" 300000
S "rc-update add docker default 2>&1" 10000
S "service docker start 2>&1 | tail -1" 30000
Start-Sleep 5
S "mkdir -p /opt/ctf"

$compose = "version: '3.8'`nnetworks:`n  external_net:`n    driver: bridge`n  internal_sanctum:`n    driver: bridge`n    internal: true`n    ipam:`n      config:`n        - subnet: 172.19.0.0/24`nservices:`n  gateway:`n    image: tressure-gateway:latest`n    container_name: anubis_gateway`n    hostname: anubis-gateway`n    ports:`n      - `"21:21`"`n      - `"22:22`"`n      - `"80:80`"`n      - `"20:20`"`n      - `"40000-40100:40000-40100`"`n    networks:`n      external_net:`n      internal_sanctum:`n        ipv4_address: 172.19.0.2`n    restart: unless-stopped`n    depends_on:`n      - sanctum`n  sanctum:`n    image: tressure-sanctum:latest`n    container_name: anubis_sanctum`n    hostname: anubis-sanctum`n    networks:`n      internal_sanctum:`n        ipv4_address: 172.19.0.13`n    restart: unless-stopped"
$composeB64 = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($compose))
S "echo $composeB64 | base64 -d > /opt/ctf/docker-compose.yml"

Write-Host "  Uploading 283MB images..."
[SB]::Send('"cat > /opt/ctf/anubis-images.tar"', "$projDir\anubis-images.tar", "toor", $script:sshPort, 900000)
S "ls -lh /opt/ctf/anubis-images.tar"

Write-Host "  Loading Docker images..."
S "docker load -i /opt/ctf/anubis-images.tar 2>&1 | tail -3" 900000
S "rm -f /opt/ctf/anubis-images.tar"

# Move host SSH to 2200
S "sed -i 's/^Port 22$/Port 2200/' /etc/ssh/sshd_config"
S "service sshd restart 2>&1" 10000
& $VBox controlvm $vmName natpf1 "admin,tcp,,2200,,2200" 2>&1 | Out-Null
Start-Sleep 3
$script:sshPort = 2200
ssh-keygen -R "[127.0.0.1]:2200" 2>$null
$r = S "hostname" 30000
if ($r -notmatch "^EXIT:0") { Write-Host "  SSH 2200 FAILED!" -F Red; exit 1 }

Write-Host "  Starting containers..."
S "cd /opt/ctf && docker-compose up -d 2>&1" 180000
Start-Sleep 15
S "docker ps --format 'table {{.Names}}\t{{.Status}}'" 10000
Write-Host "  Docker done!" -F Green

# ═══════════════════════════════════════
# PHASE 7: FIREWALL
# ═══════════════════════════════════════
Write-Host "`n[7/8] FIREWALL" -F Cyan
S "iptables -F && iptables -A INPUT -i lo -j ACCEPT && iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT && iptables -A INPUT -p tcp --dport 22 -j ACCEPT && iptables -A INPUT -p tcp --dport 80 -j ACCEPT && iptables -A INPUT -p tcp --dport 21 -j ACCEPT && iptables -A INPUT -p icmp -j ACCEPT && iptables -P INPUT DROP && iptables -P FORWARD ACCEPT && /etc/init.d/iptables save 2>&1 && rc-update add iptables default 2>&1" 15000
Write-Host "  Firewall done!" -F Green

# ═══════════════════════════════════════
# PHASE 8: EXPORT OVA
# ═══════════════════════════════════════
Write-Host "`n[8/8] EXPORT OVA" -F Cyan
& $VBox controlvm $vmName poweroff 2>$null
Start-Sleep 15
& $VBox modifyvm $vmName --nic1 nat 2>&1 | Out-Null
& $VBox modifyvm $vmName --natpf1 delete "ssh" 2>$null
& $VBox modifyvm $vmName --natpf1 delete "admin" 2>$null
Remove-Item $ova -Force -ErrorAction SilentlyContinue
Write-Host "  Exporting (takes ~1min)..."
& $VBox export $vmName --output $ova 2>&1

if (Test-Path $ova) {
    $sz = [math]::Round((Get-Item $ova).Length/1MB,1)
    Write-Host ""
    Write-Host "  BUILD COMPLETE! OVA = $sz MB" -F Green
} else {
    Write-Host "  EXPORT FAILED!" -F Red
    exit 1
}

# Cleanup
& $VBox unregistervm $vmName --delete 2>$null
Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
