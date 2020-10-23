# KeyVault-Rotation-CosmosDBAccountKey-PowerShell

## Key Vault CosmosDB Account Key Rotation Functions

Functions regenerate individual key (alternating primaryKey and secondaryKey) in CosmosDB Account and add regenerated key to Key Vault as new version of the same secret.

Functions require following information stored in secret as tags:
- $secret.Tags["ValidityPeriodDays"] - number of days, it defines expiration date for new secret
- $secret.Tags["CredentialId"] - key id (Primary|Secondary)
- $secret.Tags["ProviderAddress"] - CosmosDB Account Resource Id

You can create new secret with above tags and Storage access key as value or add those tags to existing secret. For automated rotation expiry date would also be required - it triggers event 30 days before expiry

<a href="https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fnidhunge%2FCosmosDBKeyAKVRotation%2Fmaster%2Fazuredeploy.json" target="_blank">
    <img src="https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/1-CONTRIBUTION-GUIDE/images/deploytoazure.png"/>
</a>

**Important: Please make sure that you have added the function app in the access policy for your main/general ARM Template. You main/general ARM template overwrites the access policy in this arm template as this is executed only once.**

Credit:

This project was based on the following article: https://docs.microsoft.com/en-us/azure/key-vault/secrets/tutorial-rotation-dual

The content of this project was copied and modifed for CosmosDb use case from here: https://github.com/jlichwa/KeyVault-Rotation-StorageAccountKey-PowerShell.git 

