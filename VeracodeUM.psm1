function New-VeracodeUser {
    <#
    .SYNOPSIS
        Function to create new Veracode users

    .DESCRIPTION
        Based on a JSON parameterization, this function simplifies the process of creating a new user on the Veracode platform

    .PARAMETER pathJSON
        Path of JSON file configured as per Veracode documentation. I recommend using the New-UserJson function to create it.

    .EXAMPLE
        New-VeracodeUser "D:/TEMP/user.json"

    .INPUTS
        Path of a file

    .OUTPUTS
        Confirmation or error message

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="JSON file path with data to create a new user")]
        $pathJSON
    )

    try {
        $responseAPI = Get-Content $pathJSON | http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/users"
        $responseAPI = $responseAPI | ConvertFrom-Json
        $validator = Debug-VeracodeAPI $responseAPI

        # Validates if the creation was made
        if ($validator -eq "OK") {
            # Get user information
            $nameUser = $responseAPI.first_name
            $lastnameUser = $responseAPI.last_name
            $emailUser = $responseAPI.email_address
            # Displays the confirmation message
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
}

function Get-VeracodeTeamID {
    <#
    .SYNOPSIS
        Function to get the ID of a Veracode team

    .DESCRIPTION
        Based on a name, search for a team ID on the Veracode platform

    .PARAMETER teamName
        Name of the team you want to find the ID

    .EXAMPLE
        Get-VeracodeTeamID "DEMOs"

    .INPUTS
        String

    .OUTPUTS
        Team ID

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Team name registered on the Veracode platform")]
        $teamName
    )

    try {
        $infoTeam = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/teams?all_for_org=true&size=1000" | ConvertFrom-Json
        $validator = Debug-VeracodeAPI $infoTeam
        if ($validator -eq "OK") {
            $infoTeam = $infoTeam._embedded.teams
            $teamID = ($infoTeam | Where-Object { $_.team_name -eq "$teamName" }).team_id
            if ($teamID) {
                return $teamID
            } else {
                Write-Error "No ID found for Team: $teamName"
            }
            
        } else {
            Write-Error "Something Unexpected Has Happened"
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Error "$ErrorMessage"
    }
}

function New-UserJson {
    <#
    .SYNOPSIS
        Function to generate a JSON for creating a new user

    .DESCRIPTION
        Generates a JSON with the necessary data to create a new user in Veracode

    .PARAMETER name
        Username

    .PARAMETER lastname
        User's last name

    .PARAMETER email
        User email

    .PARAMETER position
        Position (as established in the roles template) of the user

    .PARAMETER team
        Team name registered at Veracode

    .EXAMPLE
        New-UserJson $name $lastname $email $position $team

    .INPUTS
        String

    .OUTPUTS
        JSON

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="User name")]
        $name,
        [parameter(position=1,Mandatory=$True,HelpMessage="User lastname")]
        $lastname,
        [parameter(position=2,Mandatory=$True,HelpMessage="User Email")]
        $email,
        [parameter(position=3,Mandatory=$True,HelpMessage="User position")]
        $position,
        [parameter(position=4,Mandatory=$True,HelpMessage="User Team")]
        $team,
        [parameter(position=5,HelpMessage="Path to templates")]
        $templatesFolder = ".\Templates"
    )

    try {
        # Get template information
        $infoUser = Get-Content $templatesFolder\newUser.json | ConvertFrom-Json
    
        # Validates roles by position
        $roles = Get-VeracodeRoles $position
    
        # Get Team ID
        $teamID = Get-VeracodeTeamID $team
        $teamTemplate = Get-Content $templatesFolder\exemploteams.json
        $team = $teamTemplate.replace("#teamID#", "$teamID")
        $team = ($team | ConvertFrom-Json).teams
    
        # Change the properties
        $infoUser.email_address = $email
        $infoUser.user_name = $email
        $infoUser.first_name = $name
        $infoUser.last_name = $lastname
        $infoUser.title = $position
        $infoUser.roles = $roles
        $infoUser.teams = $team
    
        # Save in a new JSON
        $newJSON = "user" + (Get-Date -Format sshhmmddMM) + ".json"
        $pathJSON = "./TEMP/$newJSON"
        $infoUser | ConvertTo-Json -depth 100 | Out-File "$pathJSON"
        return $pathJSON
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Error "$ErrorMessage"
    }
}

function Block-VeracodeUser {
    <#
    .SYNOPSIS
        Function to block Veracode users

    .DESCRIPTION
        Based on the email, it blocks the user on the Veracode platform

    .PARAMETER emailUser
        Email of the user you want to block

    .PARAMETER pathJSON
        Template JSON file path (by default it comes with the value of the project's original folder structure).

    .EXAMPLE
        Block-VeracodeUser $emailUser

    .INPUTS
        User email and template path

    .OUTPUTS
        Confirmation or error message

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="User email")]
        $emailUser,
        [parameter(position=1,HelpMessage="Path to JSON template")]
        $pathJSON = ".\Templates\block.json"
    )

    try {
        # Get ID based on name
        $idUser = Get-VeracodeUserID $emailUser
    
        # Makes the Block
        $urlAPI = "https://api.veracode.com/api/authn/v2/users/" + $idUser + "?partial=true"
        $responseAPI = Get-Content $pathJSON | http --auth-type=veracode_hmac PUT "$urlAPI" | ConvertFrom-Json

        $validator = Debug-VeracodeAPI $responseAPI
        if ($validator -eq "OK") {
            $user = $responseAPI.user_name
            if ($user) {
                Write-Host "$user was blocked"
            } else {
                Write-Error "No ID found for: $emailUser"
            }
            
        } else {
            Write-Error "Unexpected behavior"
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Error "$ErrorMessage"
    }
}

function Debug-VeracodeAPI {
    <#
    .SYNOPSIS
        Function to validate the return of the APIs

    .DESCRIPTION
        Analyzes the API return to validate if it had a valid response

    .PARAMETER responseAPI
        API call return

    .EXAMPLE
        $responseAPI = http --auth-type=veracode_hmac GET "https://api.veracode.com/api/authn/v2/users?size=1000" | ConvertFrom-Json
        Debug-VeracodeAPI $responseAPI

    .INPUTS
        API call return

    .OUTPUTS
        Error or confirmation message

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
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
    <#
    .SYNOPSIS
        Function to get the ID of a Veracode user

    .DESCRIPTION
        Based on an email, returns the user ID

    .PARAMETER emailUser
        Target user email

    .EXAMPLE
        Get-VeracodeUserID "user@corp.com"

    .INPUTS
        User email

    .OUTPUTS
        User ID

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
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
                Write-Error "No ID found for user: $emailUser"
            }
            
        } else {
            Write-Error "Something Unexpected Has Happened"
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Host "$ErrorMessage"
    }
}

function New-VeracodeTeam {
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Team name")]
        $teamName,
        [parameter(position=1,HelpMessage="Template folder path")]
        $templatesFolder = ".\Templates"
    )

    try {
        # Get template information
        $teamTemplate = Get-Content $templatesFolder\newTeam.json | ConvertFrom-Json
    
        # Change the properties
        $teamTemplate.team_name = $teamName
    
        # Save in a new JSON
        $newJSON = "team" + (Get-Date -Format sshhmmddMM) + ".json"
        $pathJSON = "./TEMP/$newJSON"
        $teamTemplate | ConvertTo-Json -depth 100 | Out-File "$pathJSON"
        
        # Create Team 
        $responseAPI = Get-Content $pathJSON | http --auth-type=veracode_hmac POST "https://api.veracode.com/api/authn/v2/teams"
        $responseAPI = $responseAPI | ConvertFrom-Json
        $validator = Debug-VeracodeAPI $responseAPI

        # Validates if the creation was made
        if ($validator -eq "OK") {
            $nameteam = $responseAPI.team_name
            $idteam = $responseAPI.team_id
            Write-Host "Team successfully created:"
            Write-Host "$nameteam"
            Write-Host "$idteam"
        } else {
            Write-Error "Something Unexpected Has Happened"
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Error "$ErrorMessage"
    }
}

function Get-VeracodeRoles {
    <#
    .SYNOPSIS
        Function to get roles

    .DESCRIPTION
        Based on a position/role type, it returns a list of roles compatible with the activity

    .PARAMETER typeEmployee
        Type Employee (Ex: Developer)

    .PARAMETER pathJSON
        Template JSON file path (by default it comes with the value of the project's original folder structure).

    .EXAMPLE
        Get-VeracodeRoles "Developer"

    .INPUTS
        User position and path of a template

    .OUTPUTS
        Roles

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Name of the position as established in the template")]
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

function Update-VeracodeUserRoles {
    <#
    .SYNOPSIS
        Function to update a user's roles

    .DESCRIPTION
        Updates a user's roles based on a position/role

    .PARAMETER emailUser
        User email

    .PARAMETER typeEmployee
        Type of Employee

    .PARAMETER pathJSON
        Template JSON file path (by default it comes with the value of the project's original folder structure).

    .EXAMPLE
        Update-VeracodeUserRoles "user@corp.com" "Developer"

    .INPUTS
        Email and user position, path of a template

    .OUTPUTS
        Confirmation or error message

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Account email as registered in Veracode (If it is an API account, inform its UserName)")]
        $emailUser,
        [parameter(position=1,Mandatory=$True,HelpMessage="Type of roles desired (e.g. QA, SOC, Developer)")]
        $typeEmployee,
        [parameter(position=2,HelpMessage="Template folder path")]
        $templatesFolder = ".\Templates"
    )

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

        # Updade Roles
        $urlAPI = "https://api.veracode.com/api/authn/v2/users/" + $idUser + "?partial=true"
        $responseAPI = Get-Content $pathJSON | http --auth-type=veracode_hmac PUT "$urlAPI" | ConvertFrom-Json
        $validator = Debug-VeracodeAPI $responseAPI
        if ($validator -eq "OK") {
            $user = $responseAPI.user_name
            if ($user) {
                Write-Host "User $user updated"
            } else {
                Write-Error "No ID found for: $emailUser"
            }
            
        } else {
            Write-Error "Unexpected behavior"
        }
    }
    catch {
        $ErrorMessage = $_.Exception.Message
        Write-Host "Error in Powershell:"
        Write-Error "$ErrorMessage"
    }
}

function Remove-VeracodeUser {
    <#
    .SYNOPSIS
        Function to delete Veracode users

    .DESCRIPTION
        Based on the email, removes the user on the Veracode platform

    .PARAMETER emailUser
        User email you want to delete

    .EXAMPLE
        Remove-VeracodeUser $emailUser

    .INPUTS
        User's email

    .OUTPUTS
        Confirmation or error message

    .NOTES
        Author:  Ivo Dias
        GitHub: https://github.com/IGDEXE
        Social Media: @igd753
    #>
    param (
        [parameter(position=0,Mandatory=$True,HelpMessage="Account email as registered in Veracode (If it is an API account, inform its UserName)")]
        $emailUser
    )
    
    try {
        # Get ID based on name
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
}

# Valores de teste
# $name = "John"
# $lastname = "117"
# $email = "mail+testUM" + (Get-Date -Format sshhmmddMM) + "@corp.com"
# $position = "Developer"
# $team = "DEMOs"

# Example of how to import the module
# $folderModules = Get-Location
# Import-Module -Name "$folderModules\VeracodeUM.psm1" -Verbose

# Function test
# $pathJSON = New-UserJson $name $lastname $email $position $team
# New-VeracodeUser $pathJSON
# Update-VeracodeUserRoles $emailUser $typeEmployee
# Block-VeracodeUser $emailUser
# Remove-VeracodeUser $emailUser
# $newTeam = "UM-Test-" + (Get-Date -Format sshhmmddMM)
# New-VeracodeTeam "$newTeam"
# Get-VeracodeTeamID $newTeam