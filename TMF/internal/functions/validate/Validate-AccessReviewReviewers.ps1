function Validate-AccessReviewReviewers
{
	<#
		.SYNOPSIS
			Validates reviewers of access reviews

		.PARAMETER reference
			The id, displayName, userPrincipalName or mailNickname of the referenced resource.
	#>
	[CmdletBinding()]
	Param (
		[Parameter(ParameterSetName = "Default")]
		[string] $reference,
		[ValidateSet("singleUser", "groupMembers")]
		[string] $type = "singleUser",
		[System.Management.Automation.PSCmdlet]
		$Cmdlet = $PSCmdlet
	)
	
	begin {}
	process
	{
		if (Test-PSFFunctionInterrupt) { return }				

        $hashtable = @{
            "queryType" = "MicrosoftGraph"
            "queryRoot" = $null
        }

        switch ($type) {
            "singleUser" {
                $id = Resolve-User -InputReference $reference -Cmdlet $PSCmdlet
                $hashtable["query"] = "/v1.0/users/$($id)"
            }
            "groupMembers" {
                $id = Resolve-Group -InputReference $reference -Cmdlet $PSCmdlet
				$hashtable["query"] = "/v1.0/groups/$($id)/transitiveMembers/microsoft.graph.user"
            }
        }
        <#
		$userSetObject = [PSCustomObject]@{
			type = $type
			isBackup = $isBackup			
		}

		Add-Member -InputObject $userSetObject -MemberType NoteProperty -Name "@odata.type" -Value ("#microsoft.graph.{0}" -f $type)
		if ($type -in @("singleUser", "groupMembers", "connectedOrganizationMembers")) {
			Add-Member -InputObject $userSetObject -MemberType NoteProperty -Name reference -Value $reference
			Add-Member -InputObject $userSetObject -MemberType ScriptMethod -Name getId -Value {
				switch ($this.type) {
					"singleUser" {
						Resolve-User -InputReference $this.reference -Cmdlet $PSCmdlet
					}
					"groupMembers" {
						Resolve-Group -InputReference $this.reference -Cmdlet $PSCmdlet
					}
					"connectedOrganizationMembers" {
						Resolve-ConnectedOrganization -InputReference $this.reference -Cmdlet $PSCmdlet
					}
				}
			}
			
		}
		if ($type -eq "requestorManager") {
			Add-Member -InputObject $userSetObject -MemberType NoteProperty -Name managerLevel -Value $managerLevel
		}

		Add-Member -InputObject $userSetObject -MemberType ScriptMethod -Name prepareBody -Value {
			$hashtable = @{				
				isBackup = $this.isBackup
				"@odata.type" = $this."@odata.type"
			}
			if ($this.getId) {$hashtable["id"] = $this.getId()}
			if ($this.managerLevel) {$hashtable["managerLevel"] = $this.managerLevel}
			return $hashtable
		}#>
	}
	end
	{
		$hashtable
	}
}
