Function Query-SD($Object)
    {
    $Instance = "IDMDBPRD01\MIMStage"
    $DataBase = "StagingDirectory"
    $Query = @"
        SELECT accountName
                ,firstname
                ,lastName
                ,initials
                ,employeeID
                ,employeeNumber
                ,employeeType
                ,employeeStatus
        FROM identities
        WHERE $object
"@


    $Result=Invoke-Sqlcmd `
        -ServerInstance $Instance `
        -Database $DataBase `
        -query $Query
    Return $Result
    }

function Update-Group($Group,$Users)
    {
    $members=Get-ADGroup $Group -pr members -Server MCDC3 | select -ExpandProperty members
    
    foreach ($User in $Users)
        {
        $AccountName=$User.accountName
        $ADObject=Get-ADUser -Filter {sAMAccountName -eq $accountName} -Server MCDC3
        
        If ($members -notcontains $ADObject.DistinguishedName)
            {
            Write-Host "Add $($User.accountName) to $Group"
            Add-ADGroupMember $Group -Members $ADObject -Server MCDC3 #-Verbose
            }
        }

    foreach ($Member in $members)
        {
        $ADObject=Get-ADUser -Filter {distinguishedName -eq $Member} -Server MCDC3
        
        if ($Users.AccountName -match $ADObject.SamAccountName)
            {

            }
        Else
            {
            Write-Host "Remove $($User.accountName) from $Group"
            Remove-ADGroupMember $Group -Members $ADObject.DistinguishedName -Confirm:$false -Server MCDC3
            }
        }
    $GroupCount=$(Get-ADGroup $Group -pr members -Server MCDC3 | select -ExpandProperty members).count -eq $users.count
    
    $Group + "  " + $GroupCount
    }


[xml]$XML=gc .\Groups.xml 

foreach ($Group in $XML.Groups.group)
    {
    $Users=Query-SD $Group.Criteria
    Update-Group $Group.Name $Users
    }
