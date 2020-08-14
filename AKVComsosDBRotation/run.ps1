param($eventGridEvent, $TriggerMetadata)

function RegenerateKey($keyId, $providerAddress){
    Write-Host "Regenerating key. Id: $keyId Resource Id: $providerAddress"
    
    $cosmosDbAccountName = ($providerAddress -split '/')[8]
    $resourceGroupName = ($providerAddress -split '/')[4]
    
    #Regenerate key
    $keyType = $keyId + "MasterKey"

    New-AzCosmosDBAccountKey -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName -KeyKind $keyId.ToLower()
    $dBKeys = Get-AzCosmosDBAccountKey -ResourceGroupName $resourceGroupName -Name $cosmosDbAccountName -Type "Keys"

    $newKeyValue = $dBKeys.Item($keyType)

    return $newKeyValue
}

function AddSecretToKeyVault($keyVAultName,$secretName,$newAccessKeyValue,$exprityDate,$tags){
    
    $secretvalue = ConvertTo-SecureString "$newAccessKeyValue" -AsPlainText -Force
    Set-AzKeyVaultSecret -VaultName $keyVAultName -Name $secretName -SecretValue $secretvalue -Tag $tags -Expires $expiryDate

}

function GetAlternateCredentialId($keyId){

    $validCredentialIds = "Primary", "Secondary"
    
    If($keyId -notin $validCredentialIds){
        throw "Invalid credential id: $keyId. Credential id must be one of following:$validCredentialIds"
    }
    If($keyId -eq "Primary"){
        return "Secondary"
    }
    Else{
        return "Primary"
    }
}

function RoatateSecret($keyVaultName,$secretName){
    #Retrieve Secret
    $secret = (Get-AzKeyVaultSecret -VaultName $keyVAultName -Name $secretName)
    Write-Host "Secret Retrieved"
    
    #Retrieve Secret Info
    $validityPeriodDays = $secret.Tags["ValidityPeriodDays"]
    $credentialId=  $secret.Tags["CredentialId"]
    $providerAddress = $secret.Tags["ProviderAddress"]
    
    Write-Host "Secret Info Retrieved"
    Write-Host "Validity Period: $validityPeriodDays"
    Write-Host "Credential Id: $credentialId"
    Write-Host "Provider Address: $providerAddress"

    #Get Credential Id to rotate - alternate credential
    $alternateCredentialId = GetAlternateCredentialId $credentialId
    Write-Host "Alternate credential id: $alternateCredentialId"

    #Regenerate alternate access key in provider
    $newAccessKeyValue = (RegenerateKey $alternateCredentialId $providerAddress)[-1]
    Write-Host "Access key regenerated. Access Key Id: $alternateCredentialId Resource Id: $providerAddress"

    #Add new access key to Key Vault
    $newSecretVersionTags = @{}
    $newSecretVersionTags.ValidityPeriodDays = $validityPeriodDays
    $newSecretVersionTags.CredentialId=$alternateCredentialId
    $newSecretVersionTags.ProviderAddress = $providerAddress

    $expiryDate = (Get-Date).AddDays([int]$validityPeriodDays).ToUniversalTime()
    AddSecretToKeyVault $keyVAultName $secretName $newAccessKeyValue $expiryDate $newSecretVersionTags

    Write-Host "New access key added to Key Vault. Secret Name: $secretName"
}

# Make sure to pass hashtables to Out-String so they're logged correctly
#$eventGridEvent | ConvertTo-Json | Write-Host

$secretName = $eventGridEvent.subject
$keyVaultName = $eventGridEvent.data.VaultName
Write-Host "Key Vault Name: $keyVAultName"
Write-Host "Secret Name: $secretName"

#Rotate secret
Write-Host "Rotation started."
RoatateSecret $keyVAultName $secretName
Write-Host "Secret Rotated Successfully"