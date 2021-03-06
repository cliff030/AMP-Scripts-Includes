function CreateRDPFile($Username,$EncryptedPassword,$TemplateFile) {
    $Username = "AMP\" + $UserName

    $ScreenResolution = Get-WmiObject -Class Win32_DesktopMonitor | Select-Object ScreenWidth,ScreenHeight

    $RDPFileText = "screen mode id:i:2"
    $RDPFileText += "`r`nuse multimon:i:0"
    $RDPFileText += "`r`ndesktopwidth:i:" + $ScreenResolution.ScreenWidth
    $RDPFileText += "`r`ndesktopheight:i:" + $ScreenResolution.ScreenHeight
    $RDPFileText += "`r`nusername:s:" + $Username
    $RDPFileText += "`r`npassword 51:b:" + $EncryptedPassword

    $RDPFileName = $env:TEMP + "\temp_connection.RDP"

    If( (Test-Path $RDPFileName) -eq $true ) {
        Remove-Item $RDPFileName
    }

    $RDPFileText | Out-File $RDPFileName
    Get-Content "\\amp\support\scripts\includes\RDP Templates\Create Remote User.txt" >> $RDPFileName
    
    return $RDPFileName
}