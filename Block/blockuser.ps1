param (
    [parameter(position=0,Mandatory=$True,HelpMessage="User Email")]
    $emailUser,
    [parameter(position=1,HelpMessage="Path to JSON template")]
    $pathJSON = ".\block.json"
)

function Debug-VeracodeAPI {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Return from the API you want to check")]
        $returnAPI
    )

    try {
        $status = $returnAPI.http_status
        $message = $returnAPI.message
        $errorCode = $returnAPI.http_code

        if ($status) {
            Write-Host "An error has occurred:"
            Write-Host $message
            Write-Error $errorCode
        } elseif (!$returnAPI) {
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
    # Get ID based on name
    $idUser = Get-VeracodeUserID $emailUser
    
    # Makes the block
    $urlAPI = "https://api.veracode.com/api/authn/v2/users/" + $idUser + "?partial=true"
    $returnAPI = Get-Content $pathJSON | http --auth-type=veracode_hmac PUT "$urlAPI" | ConvertFrom-Json

    $validator = Debug-VeracodeAPI $returnAPI
    if ($validator -eq "OK") {
        $Usuario = $returnAPI.user_name
        if ($Usuario) {
            Write-Host "User $Usuario has been blocked"
        } else {
            Write-Error "No ID found for: $emailUser"
        }
        
    } else {
        Write-Error "Unexpected behavior"
    }
} catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Error in Powershell:"
    Write-Host "$ErrorMessage"
}