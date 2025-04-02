#################################################
# HelloID-Conn-Prov-Target-X-Trend-Update
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-X-TrendError {
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
            if ($errorDetailsObject.error_description) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.error_description
            } elseif ($errorDetailsObject.error.innererror.internalexception.message) {
                $httpErrorObj.FriendlyMessage = $errorDetailsObject.error.innererror.internalexception.message
            }
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

    $tokenBody = @{
        'grant_type'    = 'client_credentials'
        'client_id'     = $actionContext.Configuration.clientId
        'client_secret' = $actionContext.Configuration.clientSecret
        'resource'      = $actionContext.Configuration.BaseUrl
    }
    $splatGetToken = @{
        Uri    = "https://login.microsoftonline.com/$($actionContext.Configuration.TenantId)/oauth2/token"
        Method = 'POST'
        Body   = $tokenBody
    }
    $accessToken = (Invoke-RestMethod @splatGetToken).access_token

    Write-Information 'Verifying if a X-Trend account exists'
    $headers = @{
        Authorization  = "Bearer $($accessToken)"
        Accept         = 'application/json; charset=utf-8'
        'Content-Type' = 'application/json; charset=utf-8'
    }
    $splatGetAccount = @{
        Uri     = "$($actionContext.Configuration.BaseUrl)/data/SDWorkers(PersonnelNumber='$($actionContext.References.Account)')"
        Method  = 'GET'
        Headers = $headers
    }
    try {
        $correlatedAccount = Invoke-RestMethod @splatGetAccount
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            $correlatedAccount = $null
        } else {
            throw $_
        }
    }
    $outputContext.PreviousData = $correlatedAccount

    if ($correlatedAccount) {
        $action = 'UpdateAccount'
    } else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'UpdateAccount' {
            if (-not($actionContext.DryRun -eq $true)) {
                Write-Information "Updating X-Trend account with accountReference: [$($actionContext.References.Account)]"

                $splatUpdateAccount = @{
                    Uri     = "$($actionContext.Configuration.BaseUrl)/data/SDWorkers(PersonnelNumber='$($actionContext.References.Account)')"
                    Method  = 'PATCH'
                    Headers = $headers
                    Body    = ($actionContext.Data | ConvertTo-Json)
                }
                $null = Invoke-RestMethod @splatUpdateAccount
            } else {
                Write-Information "[DryRun] Update X-Trend account with accountReference: [$($actionContext.References.Account)], will be executed during enforcement"
            }

            $outputContext.Success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = 'Update account was successful, UPN and Email properties populated'
                    IsError = $false
                })
            break
        }

        'NotFound' {
            Write-Information "X-Trend account: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
            $outputContext.Success = $false
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "X-Trend account with accountReference: [$($actionContext.References.Account)] could not be found, possibly indicating that it could be deleted"
                    IsError = $true
                })
            break
        }
    }
} catch {
    $outputContext.Success  = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-X-TrendError -ErrorObject $ex
        $auditMessage = "Could not update X-Trend account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.FriendlyMessage)"
    } else {
        $auditMessage = "Could not update X-Trend account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}
