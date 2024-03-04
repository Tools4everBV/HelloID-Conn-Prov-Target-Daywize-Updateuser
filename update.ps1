#################################################
# HelloID-Conn-Prov-Target-Daywize-Updateuser-Update
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
# Set debug logging


function Invoke-Daywize-UpdateuserRestMethod {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Method,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]
        $Uri,

        [object]
        $Body,

        [string]
        $ContentType = 'application/json',

        [Parameter(Mandatory = $false)]
        [System.Collections.IDictionary]
        $Headers = @{}
    )

    process {

        try {

            $authorization = "$($actionContext.Configuration.UserName):$($actionContext.Configuration.Password)"
            $base64Credentials = [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($authorization))
            $Headers.Add("Authorization","Basic $base64Credentials")

            $splatParams = @{
                Uri         = $Uri
                Headers     = $Headers
                Method      = $Method
                ContentType = $ContentType
            }

            if (-not  [string]::IsNullOrEmpty($actionContext.Configuration.ProxyAddress)) {
                $splatParams['Proxy'] = $actionContext.Configuration.ProxyAddress
            }

            if ($Body){
                Write-Verbose 'Adding body to request'
                $splatParams['Body'] = $Body
            }
            Invoke-RestMethod @splatParams -Verbose:$false
        } catch {
            $PSCmdlet.ThrowTerminatingError($_)
        }
    }
}

function Resolve-Daywize-UpdateuserError {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [object]
        $ErrorObject
    )
    process {
        $httpErrorObj = [PSCustomObject]@{
            ScriptLineNumber = $ErrorObject.InvocationInfo.ScriptLineNumber
            Line             = $ErrorObject.InvocationInfo.Line
            ErrorDetails     = $ErrorObject.Exception.Message
            FriendlyMessage  = $ErrorObject.Exception.Message
        }
        if (-not [string]::IsNullOrEmpty($ErrorObject.ErrorDetails.Message)) {
            $httpErrorObj.ErrorDetails = $ErrorObject.ErrorDetails.Message
        } elseif ($ErrorObject.Exception.GetType().FullName -eq 'System.Net.WebException') {
            if ($null -ne $ErrorObject.Exception.Response) {
                $streamReaderResponse = [System.IO.StreamReader]::new($ErrorObject.Exception.Response.GetResponseStream()).ReadToEnd()
                if (-not [string]::IsNullOrEmpty($streamReaderResponse)) {
                    $httpErrorObj.ErrorDetails = $streamReaderResponse
                }
            }
        }
        try {
            $errorDetailsObject = ($httpErrorObj.ErrorDetails | ConvertFrom-Json)
            # Make sure to inspect the error result object and add only the error message as a FriendlyMessage.
            # $httpErrorObj.FriendlyMessage = $errorDetailsObject.message
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails # Temporarily assignment
        } catch {
            $httpErrorObj.FriendlyMessage = $httpErrorObj.ErrorDetails
        }
        Write-Output $httpErrorObj
    }
}
#endregion

try {

    # Verify if [aRef] has a value
    if ([string]::IsNullOrEmpty($($actionContext.References.Account))) {
        throw 'The account reference could not be found'
    }

    $outputContext.AccountReference = $actionContext.References.Account

    # For this connector no compare is done with the existing account

    $correlatedAccount =  $null
    if ($actionContext.AccountCorrelated -eq $true) {
        $correlatedAccount =  @{
            DaywizeAccountName = $actionContext.References.Account
        }
    }
    else {
        if ($null -ne $actionContext.Data.SystemName){

            ($personContext.Person.Accounts | Select-Object *).PSObject.Properties.foreach{

                $account = $_.value
                if ($account.SystemName -eq $Actioncontext.Data.SystemName)  {
                    $correlatedAccount = $account
                }
            }
        }
    }

    $outputContext.PreviousData = $correlatedAccount
    $outputContext.Data = $outputContext.PreviousData

    if ($null -ne $correlatedAccount) {

        $propertiesChanged =  [System.Collections.Generic.List[System.String]]::new()

        ($actionContext.Data  | Select-Object *).PSObject.Properties.foreach{

            $referenceValue =  $($CorrelatedAccount.$($_.name))
            if ($_.Value -ne  $referenceValue){
                $propertiesChanged.add($_.Name)
            }
        }

        if ($propertiesChanged.Count -gt 0) {
            $action = 'UpdateAccount'
            $dryRunMessage = "Account property(s) required to update: $propertiesChanged"
        } else {
            $action = 'NoChanges'
            $dryRunMessage = 'No changes will be made to the account during enforcement'
        }

    } else {
        $action = 'NotFound'
        $dryRunMessage = " Previous account values for: [$($personContext.Person.DisplayName)] not found."
    }

    # Add a message and the result of each of the validations showing what will happen during enforcement
    if ($actionContext.DryRun -eq $true) {
        Write-Verbose "[DryRun] $dryRunMessage" -Verbose
    }

    # Process
    if (-not($actionContext.DryRun -eq $true)) {

        switch ($action) {
            'UpdateAccount' {

                Write-Verbose "Updating Daywize user account with accountReference: [$($actionContext.References.Account)]"

                # Make sure to test with special characters and if needed; add utf8 encoding.

                $body = @{
                    DaywizeAccountName = $actionContext.References.Account
                }

                if ("EmailAddress" -in $propertiesChanged){
                    $body.Add("EmailAdresWorkNew",$actioncontext.data.EmailAddress)
                }
                if ("SSOLoginName" -in $propertiesChanged){
                    $body.Add("SSOLoginNameNew",$actioncontext.data.SSOLoginName)
                }

                $BodyJson = $body | ConvertTo-Json

                Invoke-Daywize-UpdateuserRestMethod -Uri "$($actionContext.Configuration.Baseurl)/employeeContact_Update" -Method "POST" -Body $BodyJson

                $outputContext.Data = $ActionContext.Data
                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Update account was successful, Account property(s) updated: $propertiesChanged)]"
                    IsError = $false
                })
                break
            }

            'NoChanges' {
                Write-Verbose "No changes to Daywize user account with accountReference: [$($actionContext.References.Account)]"
                $outputContext.Success = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = 'No changes are required to be made to the account'
                    IsError = $false
                })
                break
            }

            'NotFound' {

                $body = @{
                    DaywizeAccountName = $actionContext.References.Account
                }
                if ($null -ne $actioncontext.data.EmailAddress){
                    $body.Add("EmailAdresWorkNew",$actioncontext.data.EmailAddress)
                }
                if ($null -ne $actioncontext.data.SSOLoginName){
                    $body.Add("SSOLoginNameNew",$actioncontext.data.SSOLoginName)
                }

                $BodyJson = $body | ConvertTo-Json

                Invoke-Daywize-UpdateuserRestMethod -Uri "$($actionContext.Configuration.Baseurl)/employeeContact_Update" -Method "POST" -Body $BodyJson

                $outputContext.Data = $ActionContext.Data
                $outputContext.Success  = $true
                $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Previous values of Daywize user account for: [$($personContext.Person.DisplayName)] could not be found, therfore updating all properties "
                    IsError = $false
                })
                break
            }
        }
    }

} catch {
    $outputContext.Success  = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-Daywize-UpdateuserError -ErrorObject $ex
        $auditMessage = "Could not update Daywize-Updateuser account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.ErrorDetails)"
    } else {
        $auditMessage = "Could not update Daywize-Updateuser account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}
