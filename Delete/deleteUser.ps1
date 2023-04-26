param (
    [parameter(position=0,Mandatory=$True,HelpMessage="Account email as registered in Veracode (If it is an API account, inform its UserName)")]
    $emailUser
)

function Debug-VeracodeAPI {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Return from the API you want to check")]
        $responseAPI
    )

    try {
        $status = $responseAPI.http_status
        $message = $responseAPI.message
        $errorCode = $responseAPI.http_code

        if ($status) {
            Write-Host "An error has occurred:"
            Write-Host $message
            Write-Error $errorCode
        } elseif (!$responseAPI) {
            Write-Host "An error has occurred:"
            Write-Error "The API did not return any data"
        } else {
            $validator = "OK"
            return $validator
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Host "$ErrorMessage"
    }
}

function Get-VeracodeUserID {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Account email as registered in Veracode (If it is an API account, inform its UserName)")]
        $emailUser
    )
    try {
        $infoUsers = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?size=1000" | ConvertFrom-Json
        $validator = Debug-VeracodeAPI $infoUsers
        if ($validator -eq "OK") {
            $infoUsers = $infoUsers._embedded.users
            $userID = ($infoUsers | Where-Object { $_.user_name -eq "$emailUser" }).user_id
            if ($userID) {
                return $userID
            } else {
                # Displays the error message
                Write-Error "No ID found for user: $emailUser"
            }
            
        } else {
            # Displays the error message
            Write-Error "Something Unexpected Has Happened"
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Host "$ErrorMessage"
    }
}

try {
    $idUser = Get-VeracodeUserID $emailUser

    if ($idUser) {
        $responseAPI = http --auth-type=veracode_hmac DELETE "https://api.veracode.com/api/authn/v2/users/$idUser" | ConvertFrom-Json
        if ($responseAPI) {
            Debug-VeracodeAPI $responseAPI
        } else {
            Write-Host "User $emailUser has been deleted"
        }
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Error in Powershell:"
    Write-Error "$ErrorMessage"
}