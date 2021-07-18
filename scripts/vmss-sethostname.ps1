$data = Invoke-RestMethod "http://169.254.169.254/metadata/instance?api-version=2019-11-01" -Headers @{Metadata = $true}
if($data.compute.name -ne $null){
    $newname  = $data.compute.name.replace("_","")
    if($env:COMPUTERNAME -ne $newname){
        rename-computer -NewName $newname -Restart -Force
    }
}