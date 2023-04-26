# Veracode-UM
  User management project using the new Veracode APIs
<br>
# Before use:
Install the components Veracode needs to use:<br>
pip install httpie<br>
pip install veracode-api-signing<br>
<br>
# List of implemented functions:
New-VeracodeUser - Create new users<br>
New-UserJson - Creates the JSON to use in New-VeracodeUser<br>
New-VeracodeTeam - Create a new team<br>
Get-VeracodeUserID - Get a user ID based on email<br>
Get-VeracodeTeamID - Gets the ID of a team based on its name<br>
Get-VeracodeRoles - Get list of roles based on job title<br>
Block-VeracodeUser - Block user based on email<br>
Debug-VeracodeAPI - Validate the API return<br>
Update-VeracodeUserRoles - Updates the list of roles for a user<br>
Remove-VeracodeUser - Deletes user based on email<br>
<br>
# How to use?
Import the VeracodeUM.psm1 module in Powershell<br>
Repurpose functions in your own scripts<br>
If you want to use it in a script format, use the ones from the corresponding folders<br>
<br>
# How to use in Linux?
I recommend that you consult the documentation to verify all the details:<br>
https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell-on-linux?view=powershell-7.3<br>
This project was tested on Ubuntu 22.04.1 LTS<br>
After installing Powershell on Linux, just use it without any changes<br>