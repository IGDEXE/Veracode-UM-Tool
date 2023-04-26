param (
    [parameter(position = 0, Mandatory = $True, HelpMessage = "Account email as registered in Veracode (If it is an API account, inform its UserName)")]
    $emailUser,
    [parameter(position = 1, Mandatory = $True, HelpMessage = "Type of roles desired (e.g. QA, SOC, Developer)")]
    $typeEmployee,
    [parameter(position = 2, HelpMessage = "Template folder path")]
    $templatesFolder = ".\Templates"
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
function Get-VeracodeRoles {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Position name as established in the template")]
        $typeEmployee,
        [parameter(position=1,HelpMessage="Template folder path")]
        $templatesFolder = ".\Templates"
    )

    try {
        switch ($typeEmployee) {
            Developer { $roles = (Get-Content $templatesFolder\exemploRoles.json | ConvertFrom-Json).rolesDev; Break }
            QA { $roles = (Get-Content $templatesFolder\exemploRoles.json | ConvertFrom-Json).rolesQa; Break }
            SOC { $roles = (Get-Content $templatesFolder\exemploRoles.json | ConvertFrom-Json).rolesSoc; Break }
            DEVOPS { $roles = (Get-Content $templatesFolder\exemploRoles.json | ConvertFrom-Json).rolesSRE; Break }
            BLUETEAM { $roles = (Get-Content $templatesFolder\exemploRoles.json | ConvertFrom-Json).rolesBlueTeam; Break }
            Default { Write-Error "No profile found for $typeEmployee"}
        }

        return $roles
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Error "$ErrorMessage"
    }   
}

try {
    # Get the user ID and roles
    $idUser = Get-VeracodeUserID $emailUser
    $roles = Get-VeracodeRoles $typeEmployee

    # Updates roles based on template
    $infoUser = Get-Content "$templatesFolder\extruturaRoles.json" | ConvertFrom-Json
    $infoUser.roles = $roles

    # Save in a new JSON
    $newJSON = "roles" + (Get-Date -Format sshhmmddMM) + ".json"
    $pathJSON = "./TEMP/$newJSON"
    $infoUser | ConvertTo-Json -depth 100 | Out-File "$pathJSON"

    # Update roles
    $urlAPI = "https://api.veracode.com/api/authn/v2/users/" + $idUser + "?partial=true"
    $responseAPI = Get-Content $pathJSON | http --auth-type=veracode_hmac PUT "$urlAPI" | ConvertFrom-Json
    $validator = Debug-VeracodeAPI $responseAPI
    if ($validator -eq "OK") {
        $User = $responseAPI.user_name
        if ($User) {
            Write-Host "User $User updated"
        }
        else {
            Write-Error "No ID found for: $emailUser"
        }
            
    }
    else {
        Write-Error "Unexpected behavior"
    }
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Error in Powershell:"
    Write-Error "$ErrorMessage"
}