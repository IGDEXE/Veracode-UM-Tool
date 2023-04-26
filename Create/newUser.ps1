param (
    [parameter(position=0,Mandatory=$True,HelpMessage="JSON file path with data to create a new user")]
    $pathJSON
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

try {
    $responseAPI = Get-Content $pathJSON | http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/users"
    $responseAPI = $responseAPI | ConvertFrom-Json
    $validator = Debug-VeracodeAPI $responseAPI

    if ($validator -eq "OK") {
       $nameUser = $responseAPI.first_name
       $lastnameUser = $responseAPI.last_name
       $emailUser = $responseAPI.email_address
       Write-Host "User created successfully:"
       Write-Host "$nameUser $lastnameUser"
       Write-Host "$emailUser"
    } else {
        Write-Error "Something Unexpected Has Happened"
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Error in Powershell:"
    Write-Error "$ErrorMessage"
}
