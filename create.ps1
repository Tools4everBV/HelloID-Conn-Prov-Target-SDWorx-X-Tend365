#################################################
# HelloID-Conn-Prov-Target-SDWorx-X-Tend365-Create
# PowerShell V2
#################################################

# Enable TLS1.2
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12

#region functions
function Resolve-X-TendError {
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
    # Initial Assignments
    $outputContext.AccountReference = 'Currently not available'

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

    # Validate correlation configuration
    if ($actionContext.CorrelationConfiguration.Enabled) {
        $correlationField = $actionContext.CorrelationConfiguration.AccountField
        $correlationValue = $actionContext.CorrelationConfiguration.PersonFieldValue

        if ([string]::IsNullOrEmpty($($correlationField))) {
            throw 'Correlation is enabled but not configured correctly'
        }
        if ([string]::IsNullOrEmpty($($correlationValue))) {
            throw 'Correlation is enabled but [accountFieldValue] is empty. Please make sure it is correctly mapped'
        }

        $headers = @{
            Authorization = "Bearer $($accessToken)"
            Accept        = 'application/json; charset=utf-8'
        }
        $splatGetAccount = @{
            Uri     = "$($actionContext.Configuration.BaseUrl)/data/SDWorkers($($correlationField)='$($correlationValue)')"
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

    } else {
        throw 'Correlation should be enabled in the correlation configuration.'
    }

    if ($null -ne $correlatedAccount) {
        $action = 'CorrelateAccount'
    } else {
        $action = 'NotFound'
    }

    # Process
    switch ($action) {
        'CorrelateAccount' {
            Write-Information 'Correlating X-Tend account'

            $outputContext.Data = $correlatedAccount
            $outputContext.AccountReference = $correlatedAccount.PersonnelNumber
            $outputContext.AccountCorrelated = $true

            $outputContext.success = $true
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Correlated account: [$($outputContext.AccountReference)] on field: [$($correlationField)] with value: [$($correlationValue)]"
                    IsError = $false
                })
            break
        }

        'NotFound' {
            $outputContext.success = $false
            $outputContext.AuditLogs.Add([PSCustomObject]@{
                    Message = "Can't Correlate account [$($outputContext.AccountReference)] on field: [$($correlationField)] with value: [$($correlationValue)]"
                    IsError = $true
                })
            break
        }
    }
} catch {
    $outputContext.success = $false
    $ex = $PSItem
    if ($($ex.Exception.GetType().FullName -eq 'Microsoft.PowerShell.Commands.HttpResponseException') -or
        $($ex.Exception.GetType().FullName -eq 'System.Net.WebException')) {
        $errorObj = Resolve-X-TendError -ErrorObject $ex
        $auditMessage = "Could not create or correlate X-Tend account. Error: $($errorObj.FriendlyMessage)"
        Write-Warning "Error at Line '$($errorObj.ScriptLineNumber)': $($errorObj.Line). Error: $($errorObj.FriendlyMessage)"
    } else {
        $auditMessage = "Could not create or correlate X-Tend account. Error: $($ex.Exception.Message)"
        Write-Warning "Error at Line '$($ex.InvocationInfo.ScriptLineNumber)': $($ex.InvocationInfo.Line). Error: $($ex.Exception.Message)"
    }
    $outputContext.AuditLogs.Add([PSCustomObject]@{
            Message = $auditMessage
            IsError = $true
        })
}