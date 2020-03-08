
# Merge keyvault values into variable files

# Login to Azure
if ([string]::IsNullOrEmpty($(Get-AzContext).Account)) {Connect-AzAccount}

# File name to read and keyvault to access
if ([string]::IsNullOrEmpty($args[0]) -and [string]::IsNullOrEmpty($args[1])) {
    Write-Output "Format: process [filepath] [keyvault]"
    exit
}

# resolve relative paths
$file = get-item $args[0]

$reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $file

# Clear vars
$newstr = ""
$keyval = ""

# File Read Loop
while ( $read = $reader.ReadLine() ) {

    # if we find the keyvault token then call keyvault, else skip call
    if ($read -match "<") {
 
        # Split line character is '=' needs to parameterized
        $readkey, $readval = $read -split "="

        # Get the interpolated keyvault name value <value>
        $val = $readval.Trim() -replace """<", ""
        $val = $val.Trim() -replace ">""", ""

        # Get key value from vault, value part of split should be keyname    
        $keyval = (Get-AzKeyVaultSecret -vaultName $args[1] -name $val).SecretValueText

        # If the key does not exist return the original line else replace with key
        if ([string]::IsNullOrEmpty($keyval)) { $newstr += $read + "`r`n" } 

        else { $newstr += $readkey + "= " + """$keyval""" + "`r`n" } 
    
    } else { $newstr += $read + "`r`n" }
}

Write-Output $newstr

$reader.close()