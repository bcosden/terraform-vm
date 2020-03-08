
# Merge keyvault values into variable files

# Login to Azure
if ([string]::IsNullOrEmpty($(Get-AzContext).Account)) {Connect-AzAccount}

# File name to read, needs to be parameterized
if ([string]::IsNullOrEmpty($args[0])) {
    Write-Output "Format: process [filepath]"
    exit
}

$file = get-item $args[0]

$reader = New-Object -TypeName System.IO.StreamReader -ArgumentList $file

# Clear vars
$newstr = ""
$keyval = ""

# File Read Loop
while ( $read = $reader.ReadLine() ) {

    # Ignore comment line items in files (saves a call to KeyVault)
    If ($read -match "#") {

        $newstr += $read + "`r`n"

    } else {

        # Split line character is '=' needs to parameterized
        $readkey, $readval = $read -split "="

        if ($readval -match "<") {
            $val = $readval.Trim() -replace """<", ""
            $val = $val.Trim() -replace ">""", ""

            # Get key value from vault, value part of split should be keyname
            $keyval = (Get-AzKeyVaultSecret -vaultName "az-mgmt-keyvault" -name $val).SecretValueText
        } else {
            $keyval = ""
        }

        # If the key does not exist return the original line else replace with key
        if ([string]::IsNullOrEmpty($keyval)) {
            $newstr += $read + "`r`n"
        } else {
            $newstr += $readkey + "= " + """$keyval""" + "`r`n"
        } 
    }
}

Write-Output $newstr

$reader.close()