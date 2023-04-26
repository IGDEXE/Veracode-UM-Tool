param (
        $name,
        $lastname,
        $email,
        $title,
        $team,
        $templatesFolder = ".\Templates"
    )

# Functions list
function Get-VeracodeTeamID {
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
                Write-Error "ID not found for team: $teamName"
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

try {
    $infoUser = Get-Content $templatesFolder\newUser.json | ConvertFrom-Json

    # Validate roles by title
    if ($title -eq "Developer") {
        $roles = (Get-Content .\Templates\exemploRoles.json | ConvertFrom-Json).rolesDev
    } if ($title -eq "Manager") {
        $roles = (Get-Content .\Templates\exemploRoles.json | ConvertFrom-Json).rolesManager
    }

    # Get the team ID
    $teamID = Get-VeracodeTeamID $team
    $teamTemplate = Get-Content .\Templates\exemploteams.json
    $team = $teamTemplate.replace("#teamID#", "$teamID")
    $team = ($team | ConvertFrom-Json).teams

    # Change the properties
    $infoUser.email_address = $email
    $infoUser.user_name = $email
    $infoUser.first_name = $name
    $infoUser.last_name = $lastname
    $infoUser.title = $title
    $infoUser.roles = $roles
    $infoUser.teams = $team

    # Save in a new JSON
    $novoJSON = "user" + (Get-Date -Format sshhmmddMM) + ".json"
    $infoUser | ConvertTo-Json -depth 100 | Out-File "$novoJSON"
    return $novoJSON
}
catch {
    $ErrorMessage = $_.Exception.Message
    Write-Host "Error in Powershell:"
    Write-Host "$ErrorMessage"
}