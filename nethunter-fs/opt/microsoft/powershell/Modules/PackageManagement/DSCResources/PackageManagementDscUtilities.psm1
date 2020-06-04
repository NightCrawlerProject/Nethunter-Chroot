#
# Copyright (c) Microsoft Corporation.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.
#
#Helper functions for PackageManagement DSC Resouces

Import-LocalizedData -BindingVariable LocalizedData -filename PackageManagementDscUtilities.strings.psd1


 Function ExtractArguments
{
    <#
    .SYNOPSIS

    This is a helper function that extract the parameters from a given table. 

    .PARAMETER FunctionBoundParameters
    Specifies the hashtable containing a set of parameters to be extracted

    .PARAMETER ArgumentNames
    Specifies A list of arguments you want to extract
    #>

    Param
    (
        [parameter(Mandatory = $true)]
        [System.Collections.Hashtable]
        $FunctionBoundParameters,

        #A list of arguments you want to extract
        [parameter(Mandatory = $true)]
        [System.String[]]$ArgumentNames
    )

    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))

    $returnValue=@{}

    foreach ($arg in $ArgumentNames)
    {
        if($FunctionBoundParameters.ContainsKey($arg))
        {
            #Found an argument we are looking for, so we add it to return collection
            $returnValue.Add($arg,$FunctionBoundParameters[$arg])
        }
    }

    return $returnValue
 }

function ThrowError
{
    <#
    .SYNOPSIS

    This is a helper function that throws an error. 

    .PARAMETER ExceptionName
    Specifies the type of errors, e.g. System.ArgumentException

    .PARAMETER ExceptionMessage
    Specifies the exception message

    .PARAMETER ErrorId
    Specifies an identifier of the error

    .PARAMETER ErrorCategory
    Specifies the error category, e.g., InvalidArgument defined in System.Management.Automation. 

    #>

    param
    (        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]        
        $ExceptionName,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ExceptionMessage,      
        
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]
        $ErrorId,

        [parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [System.Management.Automation.ErrorCategory]
        $ErrorCategory
    )
    
    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))
        
    $exception   = New-Object -TypeName $ExceptionName -ArgumentList $ExceptionMessage;
    $errorRecord = New-Object -TypeName System.Management.Automation.ErrorRecord -ArgumentList ($exception, $ErrorId, $ErrorCategory, $null)    
    throw $errorRecord
}

Function ValidateArgument
{
    <#
    .SYNOPSIS

    This is a helper function that validates the arguments. 

    .PARAMETER Argument
    Specifies the argument to be validated.

    .PARAMETER Type
    Specifies the type of argument.
    #>

    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Argument,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$Type,

        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [String]$ProviderName
    )

    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))

    switch ($Type)
    {

        "SourceUri"
        {
            # Checks whether given URI represents specific scheme
            # Most common schemes: file, http, https, ftp        
            $scheme =@('http', 'https', 'file', 'ftp')
 
            $newUri = $Argument -as [System.URI]  
            $returnValue = ($newUri -and $newUri.AbsoluteURI -and ($scheme -icontains $newuri.Scheme)) 

            if ($returnValue -eq $false)
            {                
                ThrowError  -ExceptionName "System.ArgumentException" `
                            -ExceptionMessage ($LocalizedData.InValidUri -f $Argument)`
                            -ErrorId "InValidUri" `
                            -ErrorCategory InvalidArgument
            }
            
            #Check whether it's a valid uri. Wait for the response within 2mins.
            <#$result = Invoke-WebRequest $newUri -TimeoutSec 120 -UseBasicParsing -ErrorAction SilentlyContinue

            if ($null -eq (([xml]$result.Content).service ))
            {
                ThrowError  -ExceptionName "System.ArgumentException" `
                            -ExceptionMessage ($LocalizedData.InValidUri -f $Argument)`
                            -ErrorId "InValidUri" `
                            -ErrorCategory InvalidArgument
            }#>
                                         
        }
        "DestinationPath"
        {
            $returnValue = Test-Path -Path $Argument
            if ($returnValue -eq $false)
            {
                ThrowError  -ExceptionName "System.ArgumentException" `
                            -ExceptionMessage ($LocalizedData.PathDoesNotExist -f $Argument)`
                            -ErrorId "PathDoesNotExist" `
                            -ErrorCategory InvalidArgument
            }
        }
        "PackageSource"
        {      
            #Argument can be either the package source Name or source Uri.  
            
            #Check if the source is a uri 
            $uri = $Argument -as [System.URI]  

            if($uri -and $uri.AbsoluteURI) 
            {
                # Check if it's a valid Uri
                ValidateArgument -Argument $Argument -Type "SourceUri" -ProviderName $ProviderName
            }
            else
            {
                #Check if it's a registered package source name                                                             
                $source = PackageManagement\Get-PackageSource -Name $Argument -ProviderName $ProviderName -verbose -ErrorVariable ev
                if ((-not $source) -or $ev) 
                {
                    #We do not need to throw error here as Get-PackageSource does already
                    Write-Verbose -Message ($LocalizedData.SourceNotFound -f $source)                
                }
            }
        }
        default
        {
            ThrowError  -ExceptionName "System.ArgumentException" `
                        -ExceptionMessage ($LocalizedData.UnexpectedArgument -f $Type)`
                        -ErrorId "UnexpectedArgument" `
                        -ErrorCategory InvalidArgument
        }
     }           
}

Function ValidateVersionArgument
{
    <#
    .SYNOPSIS

    This is a helper function that does the version validation. 

    .PARAMETER RequiredVersion
    Provides the required version.

    .PARAMETER MaximumVersion
    Provides the maximum version.

    .PARAMETER MinimumVersion
    Provides the minimum version.
    #>

    [CmdletBinding()]
    param
    (
        [string]$RequiredVersion,
        [string]$MinimumVersion,
        [string]$MaximumVersion

    )
         
    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))

    $isValid = $false
         
    #Case 1: No further check required if a user provides either none or one of these: minimumVersion, maximumVersion, and requiredVersion
    if ($PSBoundParameters.Count -le 1)
    {
        return $true
    }

    #Case 2: #If no RequiredVersion is provided 
    if (-not $PSBoundParameters.ContainsKey('RequiredVersion'))
    {
        #If no RequiredVersion, both MinimumVersion and MaximumVersion are provided. Otherwise fall into the Case #1
        $isValid = $PSBoundParameters['MinimumVersion'] -le $PSBoundParameters['MaximumVersion']
    }
    
    #Case 3: RequiredVersion is provided. 
    #        In this case  MinimumVersion and/or MaximumVersion also are provided. Otherwise fall in to Case #1.
    #        This is an invalid case. When RequiredVersion is provided, others are not allowed. so $isValid is false, which is already set in the init

    if ($isValid -eq $false)
    {        
        ThrowError  -ExceptionName "System.ArgumentException" `
                    -ExceptionMessage ($LocalizedData.VersionError)`
                    -ErrorId "VersionError" `
                    -ErrorCategory InvalidArgument
    }
}

Function Get-InstallationPolicy
{
    <#
    .SYNOPSIS

    This is a helper function that retrives the InstallationPolicy from the given repository. 

    .PARAMETER RepositoryName
    Provides the repository Name.

    #>

    Param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.String]$RepositoryName
    )

    Write-Verbose -Message ($LocalizedData.CallingFunction -f $($MyInvocation.mycommand))

    $repositoryobj = PackageManagement\Get-PackageSource -Name $RepositoryName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

    if ($repositoryobj)
    {      
        return $repositoryobj.IsTrusted
    }                  
}

# SIG # Begin signature block
# MIIjigYJKoZIhvcNAQcCoIIjezCCI3cCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCD+xe8u4YoS6UEO
# jtW70wceL89huvuluOvdcbeefpOXLqCCDYUwggYDMIID66ADAgECAhMzAAABUptA
# n1BWmXWIAAAAAAFSMA0GCSqGSIb3DQEBCwUAMH4xCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01pY3Jvc29mdCBDb2RlIFNpZ25p
# bmcgUENBIDIwMTEwHhcNMTkwNTAyMjEzNzQ2WhcNMjAwNTAyMjEzNzQ2WjB0MQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMR4wHAYDVQQDExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIB
# AQCxp4nT9qfu9O10iJyewYXHlN+WEh79Noor9nhM6enUNbCbhX9vS+8c/3eIVazS
# YnVBTqLzW7xWN1bCcItDbsEzKEE2BswSun7J9xCaLwcGHKFr+qWUlz7hh9RcmjYS
# kOGNybOfrgj3sm0DStoK8ljwEyUVeRfMHx9E/7Ca/OEq2cXBT3L0fVnlEkfal310
# EFCLDo2BrE35NGRjG+/nnZiqKqEh5lWNk33JV8/I0fIcUKrLEmUGrv0CgC7w2cjm
# bBhBIJ+0KzSnSWingXol/3iUdBBy4QQNH767kYGunJeY08RjHMIgjJCdAoEM+2mX
# v1phaV7j+M3dNzZ/cdsz3oDfAgMBAAGjggGCMIIBfjAfBgNVHSUEGDAWBgorBgEE
# AYI3TAgBBggrBgEFBQcDAzAdBgNVHQ4EFgQU3f8Aw1sW72WcJ2bo/QSYGzVrRYcw
# VAYDVR0RBE0wS6RJMEcxLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEWMBQGA1UEBRMNMjMwMDEyKzQ1NDEzNjAfBgNVHSMEGDAW
# gBRIbmTlUAXTgqoXNzcitW2oynUClTBUBgNVHR8ETTBLMEmgR6BFhkNodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9NaWNDb2RTaWdQQ0EyMDExXzIw
# MTEtMDctMDguY3JsMGEGCCsGAQUFBwEBBFUwUzBRBggrBgEFBQcwAoZFaHR0cDov
# L3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNDb2RTaWdQQ0EyMDEx
# XzIwMTEtMDctMDguY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcNAQELBQADggIB
# AJTwROaHvogXgixWjyjvLfiRgqI2QK8GoG23eqAgNjX7V/WdUWBbs0aIC3k49cd0
# zdq+JJImixcX6UOTpz2LZPFSh23l0/Mo35wG7JXUxgO0U+5drbQht5xoMl1n7/TQ
# 4iKcmAYSAPxTq5lFnoV2+fAeljVA7O43szjs7LR09D0wFHwzZco/iE8Hlakl23ZT
# 7FnB5AfU2hwfv87y3q3a5qFiugSykILpK0/vqnlEVB0KAdQVzYULQ/U4eFEjnis3
# Js9UrAvtIhIs26445Rj3UP6U4GgOjgQonlRA+mDlsh78wFSGbASIvK+fkONUhvj8
# B8ZHNn4TFfnct+a0ZueY4f6aRPxr8beNSUKn7QW/FQmn422bE7KfnqWncsH7vbNh
# G929prVHPsaa7J22i9wyHj7m0oATXJ+YjfyoEAtd5/NyIYaE4Uu0j1EhuYUo5VaJ
# JnMaTER0qX8+/YZRWrFN/heps41XNVjiAawpbAa0fUa3R9RNBjPiBnM0gvNPorM4
# dsV2VJ8GluIQOrJlOvuCrOYDGirGnadOmQ21wPBoGFCWpK56PxzliKsy5NNmAXcE
# x7Qb9vUjY1WlYtrdwOXTpxN4slzIht69BaZlLIjLVWwqIfuNrhHKNDM9K+v7vgrI
# bf7l5/665g0gjQCDCN6Q5sxuttTAEKtJeS/pkpI+DbZ/MIIHejCCBWKgAwIBAgIK
# YQ6Q0gAAAAAAAzANBgkqhkiG9w0BAQsFADCBiDELMAkGA1UEBhMCVVMxEzARBgNV
# BAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jv
# c29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFJvb3QgQ2VydGlm
# aWNhdGUgQXV0aG9yaXR5IDIwMTEwHhcNMTEwNzA4MjA1OTA5WhcNMjYwNzA4MjEw
# OTA5WjB+MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSgwJgYD
# VQQDEx9NaWNyb3NvZnQgQ29kZSBTaWduaW5nIFBDQSAyMDExMIICIjANBgkqhkiG
# 9w0BAQEFAAOCAg8AMIICCgKCAgEAq/D6chAcLq3YbqqCEE00uvK2WCGfQhsqa+la
# UKq4BjgaBEm6f8MMHt03a8YS2AvwOMKZBrDIOdUBFDFC04kNeWSHfpRgJGyvnkmc
# 6Whe0t+bU7IKLMOv2akrrnoJr9eWWcpgGgXpZnboMlImEi/nqwhQz7NEt13YxC4D
# dato88tt8zpcoRb0RrrgOGSsbmQ1eKagYw8t00CT+OPeBw3VXHmlSSnnDb6gE3e+
# lD3v++MrWhAfTVYoonpy4BI6t0le2O3tQ5GD2Xuye4Yb2T6xjF3oiU+EGvKhL1nk
# kDstrjNYxbc+/jLTswM9sbKvkjh+0p2ALPVOVpEhNSXDOW5kf1O6nA+tGSOEy/S6
# A4aN91/w0FK/jJSHvMAhdCVfGCi2zCcoOCWYOUo2z3yxkq4cI6epZuxhH2rhKEmd
# X4jiJV3TIUs+UsS1Vz8kA/DRelsv1SPjcF0PUUZ3s/gA4bysAoJf28AVs70b1FVL
# 5zmhD+kjSbwYuER8ReTBw3J64HLnJN+/RpnF78IcV9uDjexNSTCnq47f7Fufr/zd
# sGbiwZeBe+3W7UvnSSmnEyimp31ngOaKYnhfsi+E11ecXL93KCjx7W3DKI8sj0A3
# T8HhhUSJxAlMxdSlQy90lfdu+HggWCwTXWCVmj5PM4TasIgX3p5O9JawvEagbJjS
# 4NaIjAsCAwEAAaOCAe0wggHpMBAGCSsGAQQBgjcVAQQDAgEAMB0GA1UdDgQWBBRI
# bmTlUAXTgqoXNzcitW2oynUClTAZBgkrBgEEAYI3FAIEDB4KAFMAdQBiAEMAQTAL
# BgNVHQ8EBAMCAYYwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBRyLToCMZBD
# uRQFTuHqp8cx0SOJNDBaBgNVHR8EUzBRME+gTaBLhklodHRwOi8vY3JsLm1pY3Jv
# c29mdC5jb20vcGtpL2NybC9wcm9kdWN0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3JsMF4GCCsGAQUFBwEBBFIwUDBOBggrBgEFBQcwAoZCaHR0cDovL3d3
# dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXQyMDExXzIwMTFf
# MDNfMjIuY3J0MIGfBgNVHSAEgZcwgZQwgZEGCSsGAQQBgjcuAzCBgzA/BggrBgEF
# BQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9kb2NzL3ByaW1h
# cnljcHMuaHRtMEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAHAAbwBsAGkA
# YwB5AF8AcwB0AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQBn
# 8oalmOBUeRou09h0ZyKbC5YR4WOSmUKWfdJ5DJDBZV8uLD74w3LRbYP+vj/oCso7
# v0epo/Np22O/IjWll11lhJB9i0ZQVdgMknzSGksc8zxCi1LQsP1r4z4HLimb5j0b
# pdS1HXeUOeLpZMlEPXh6I/MTfaaQdION9MsmAkYqwooQu6SpBQyb7Wj6aC6VoCo/
# KmtYSWMfCWluWpiW5IP0wI/zRive/DvQvTXvbiWu5a8n7dDd8w6vmSiXmE0OPQvy
# CInWH8MyGOLwxS3OW560STkKxgrCxq2u5bLZ2xWIUUVYODJxJxp/sfQn+N4sOiBp
# mLJZiWhub6e3dMNABQamASooPoI/E01mC8CzTfXhj38cbxV9Rad25UAqZaPDXVJi
# hsMdYzaXht/a8/jyFqGaJ+HNpZfQ7l1jQeNbB5yHPgZ3BtEGsXUfFL5hYbXw3MYb
# BL7fQccOKO7eZS/sl/ahXJbYANahRr1Z85elCUtIEJmAH9AAKcWxm6U/RXceNcbS
# oqKfenoi+kiVH6v7RyOA9Z74v2u3S5fi63V4GuzqN5l5GEv/1rMjaHXmr/r8i+sL
# gOppO6/8MO0ETI7f33VtY5E90Z1WTk+/gFcioXgRMiF670EKsT/7qMykXcGhiJtX
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCFVswghVXAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAFSm0CfUFaZdYgAAAAA
# AVIwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIAmd
# iucWytu7com6rTFeQB6cjTe5Tct5wjRGfoLIQj7QMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAdPlU0th8ck1uTu1DGGZK2lAbAtcRPUHOKIh9
# 5IfdOlpgs+1xEqTsc3Bh3EuiGWLV71G3+E/fteoOT20TGieW8cHdYcBA+HrHIxpl
# hUlFTNsqnJDUde1Nkh/uSSc3pM3iHE7I31Ix49/o04LBLreKfL5XlH4qjRrYyV+Y
# U8WTIsQTrUZDlM8O7dVH7QqhdwHp+40V2Uqfqp7dhbS+xbS6s27l/FxRLPP+21+S
# UdyswCaIe9cg0F2Bo90VPQbe7WUu2RDUpW6VBGbI/Vq5ikZXMkrhcYuSg3xYPgb8
# UcEGZOeFhiz00ZzLbsC+HZwIXR14J41P6rHIothb/ECmqV1Q7KGCEuUwghLhBgor
# BgEEAYI3AwMBMYIS0TCCEs0GCSqGSIb3DQEHAqCCEr4wghK6AgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFRBgsqhkiG9w0BCRABBKCCAUAEggE8MIIBOAIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCBPTgd5R4BCeyqBL9bLgL6gersjLVhIZmeP
# YFphUpQ54gIGXfwxi6uKGBMyMDE5MTIyMzE5NDY0OC40NzVaMASAAgH0oIHQpIHN
# MIHKMQswCQYDVQQGEwJVUzELMAkGA1UECBMCV0ExEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEtMCsGA1UECxMkTWljcm9z
# b2Z0IElyZWxhbmQgT3BlcmF0aW9ucyBMaW1pdGVkMSYwJAYDVQQLEx1UaGFsZXMg
# VFNTIEVTTjpFMDQxLTRCRUUtRkE3RTElMCMGA1UEAxMcTWljcm9zb2Z0IFRpbWUt
# U3RhbXAgc2VydmljZaCCDjwwggTxMIID2aADAgECAhMzAAABB343aJiHWjfWAAAA
# AAEHMA0GCSqGSIb3DQEBCwUAMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNo
# aW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29y
# cG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEw
# MB4XDTE5MTAwODE3MzgzNVoXDTIxMDEwMzE3MzgzNVowgcoxCzAJBgNVBAYTAlVT
# MQswCQYDVQQIEwJXQTEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMS0wKwYDVQQLEyRNaWNyb3NvZnQgSXJlbGFuZCBPcGVy
# YXRpb25zIExpbWl0ZWQxJjAkBgNVBAsTHVRoYWxlcyBUU1MgRVNOOkUwNDEtNEJF
# RS1GQTdFMSUwIwYDVQQDExxNaWNyb3NvZnQgVGltZS1TdGFtcCBzZXJ2aWNlMIIB
# IjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1LqjlJW2nloq4MGwsIYTSDqk
# 7IaaPkHUmMQLfSZ5HrpUBXiq0OqzkhAl8cIDoy/0zTCF7ZIoNTGonxTjerIv0Yvg
# LFfBrq0KeH8pScywzBXSXBkqVdwhkXaQ29GrvJDUC5p2bsS8QC/dUe//95h9kA0C
# NtMNxtOrPl7/Po7PcEJLFwH3JV19UyaASMdT4tRRqgp2NypVvNfj5Yc9E+MkrZtT
# IJ6h+ESmMj3XHpqQmAvwSNOD4dhCS/rkEHwH2HW3/bxqqSmI7LpLZ1q+bqMA9x+Q
# Lfsd5WB+a8+CQpXio3i6Qf4++B+1WdCOXkxG5bPXtpRCmlM2/aNMI54w3PreAQID
# AQABo4IBGzCCARcwHQYDVR0OBBYEFDTh45cZSCVzHD/Z/9KIGHV/Keh3MB8GA1Ud
# IwQYMBaAFNVjOlyKMZDzQ3t8RhvFM2hahW1VMFYGA1UdHwRPME0wS6BJoEeGRWh0
# dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kvY3JsL3Byb2R1Y3RzL01pY1RpbVN0
# YVBDQV8yMDEwLTA3LTAxLmNybDBaBggrBgEFBQcBAQROMEwwSgYIKwYBBQUHMAKG
# Pmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9wa2kvY2VydHMvTWljVGltU3RhUENB
# XzIwMTAtMDctMDEuY3J0MAwGA1UdEwEB/wQCMAAwEwYDVR0lBAwwCgYIKwYBBQUH
# AwgwDQYJKoZIhvcNAQELBQADggEBABjd/+11ksxxio5OOOMPtqtQ95OwYf2WoVL1
# hxSehFClOby8xBrHbICUr1lx2Q0a6X+a3FBkMo55aNYQGNZg7XjShbrIUum3ncXM
# TxyY3pVWfTdv3ufv+8y7tfGI5ysOWxbu3VqmATCNydBTq+elyTidSk7TIiYacbom
# /hVsvqcoVVYBxk1B7lHWxNPXWPVsbkbG6W+A3VgFjazwwelQDjudEHxI/tLVvsxe
# od0YQUyNIpY9PgM4FxPug8ie/26+mlbwhLzUScxOmpCZzMp/5M5gt9i8b0WVihMF
# g0dBZ83l4+cp0krWeoon0wT+4Kog7InYLsYfgRV+x8YTdXh3+40wggZxMIIEWaAD
# AgECAgphCYEqAAAAAAACMA0GCSqGSIb3DQEBCwUAMIGIMQswCQYDVQQGEwJVUzET
# MBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMV
# TWljcm9zb2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUm9vdCBD
# ZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAxMDAeFw0xMDA3MDEyMTM2NTVaFw0yNTA3
# MDEyMTQ2NTVaMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAw
# DgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24x
# JjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAyMDEwMIIBIjANBgkq
# hkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqR0NvHcRijog7PwTl/X6f2mUa3RUENWl
# CgCChfvtfGhLLF/Fw+Vhwna3PmYrW/AVUycEMR9BGxqVHc4JE458YTBZsTBED/Fg
# iIRUQwzXTbg4CLNC3ZOs1nMwVyaCo0UN0Or1R4HNvyRgMlhgRvJYR4YyhB50YWeR
# X4FUsc+TTJLBxKZd0WETbijGGvmGgLvfYfxGwScdJGcSchohiq9LZIlQYrFd/Xcf
# PfBXday9ikJNQFHRD5wGPmd/9WbAA5ZEfu/QS/1u5ZrKsajyeioKMfDaTgaRtogI
# Neh4HLDpmc085y9Euqf03GS9pAHBIAmTeM38vMDJRF1eFpwBBU8iTQIDAQABo4IB
# 5jCCAeIwEAYJKwYBBAGCNxUBBAMCAQAwHQYDVR0OBBYEFNVjOlyKMZDzQ3t8RhvF
# M2hahW1VMBkGCSsGAQQBgjcUAgQMHgoAUwB1AGIAQwBBMAsGA1UdDwQEAwIBhjAP
# BgNVHRMBAf8EBTADAQH/MB8GA1UdIwQYMBaAFNX2VsuP6KJcYmjRPZSQW9fOmhjE
# MFYGA1UdHwRPME0wS6BJoEeGRWh0dHA6Ly9jcmwubWljcm9zb2Z0LmNvbS9wa2kv
# Y3JsL3Byb2R1Y3RzL01pY1Jvb0NlckF1dF8yMDEwLTA2LTIzLmNybDBaBggrBgEF
# BQcBAQROMEwwSgYIKwYBBQUHMAKGPmh0dHA6Ly93d3cubWljcm9zb2Z0LmNvbS9w
# a2kvY2VydHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMuY3J0MIGgBgNVHSABAf8E
# gZUwgZIwgY8GCSsGAQQBgjcuAzCBgTA9BggrBgEFBQcCARYxaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL1BLSS9kb2NzL0NQUy9kZWZhdWx0Lmh0bTBABggrBgEFBQcC
# AjA0HjIgHQBMAGUAZwBhAGwAXwBQAG8AbABpAGMAeQBfAFMAdABhAHQAZQBtAGUA
# bgB0AC4gHTANBgkqhkiG9w0BAQsFAAOCAgEAB+aIUQ3ixuCYP4FxAz2do6Ehb7Pr
# psz1Mb7PBeKp/vpXbRkws8LFZslq3/Xn8Hi9x6ieJeP5vO1rVFcIK1GCRBL7uVOM
# zPRgEop2zEBAQZvcXBf/XPleFzWYJFZLdO9CEMivv3/Gf/I3fVo/HPKZeUqRUgCv
# OA8X9S95gWXZqbVr5MfO9sp6AG9LMEQkIjzP7QOllo9ZKby2/QThcJ8ySif9Va8v
# /rbljjO7Yl+a21dA6fHOmWaQjP9qYn/dxUoLkSbiOewZSnFjnXshbcOco6I8+n99
# lmqQeKZt0uGc+R38ONiU9MalCpaGpL2eGq4EQoO4tYCbIjggtSXlZOz39L9+Y1kl
# D3ouOVd2onGqBooPiRa6YacRy5rYDkeagMXQzafQ732D8OE7cQnfXXSYIghh2rBQ
# Hm+98eEA3+cxB6STOvdlR3jo+KhIq/fecn5ha293qYHLpwmsObvsxsvYgrRyzR30
# uIUBHoD7G4kqVDmyW9rIDVWZeodzOwjmmC3qjeAzLhIp9cAvVCch98isTtoouLGp
# 25ayp0Kiyc8ZQU3ghvkqmqMRZjDTu3QyS99je/WZii8bxyGvWbWu3EQ8l1Bx16HS
# xVXjad5XwdHeMMD9zOZN+w2/XU/pnR4ZOC+8z1gFLu8NoFA12u8JJxzVs341Hgi6
# 2jbb01+P3nSISRKhggLOMIICNwIBATCB+KGB0KSBzTCByjELMAkGA1UEBhMCVVMx
# CzAJBgNVBAgTAldBMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xLTArBgNVBAsTJE1pY3Jvc29mdCBJcmVsYW5kIE9wZXJh
# dGlvbnMgTGltaXRlZDEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RTA0MS00QkVF
# LUZBN0UxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1wIHNlcnZpY2WiIwoB
# ATAHBgUrDgMCGgMVAMMLvrX4Bt6wu0Wa8bhTtgpmUnz4oIGDMIGApH4wfDELMAkG
# A1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQx
# HjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9z
# b2Z0IFRpbWUtU3RhbXAgUENBIDIwMTAwDQYJKoZIhvcNAQEFBQACBQDhq004MCIY
# DzIwMTkxMjIzMjIyNzA0WhgPMjAxOTEyMjQyMjI3MDRaMHcwPQYKKwYBBAGEWQoE
# ATEvMC0wCgIFAOGrTTgCAQAwCgIBAAICGvoCAf8wBwIBAAICEawwCgIFAOGsnrgC
# AQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAqAKMAgCAQACAwehIKEK
# MAgCAQACAwGGoDANBgkqhkiG9w0BAQUFAAOBgQBv6JzPN8E5uzfZbePMmpFSGUA9
# LFTWK0fOCpZHgrjY29RQZ9S2tpYumP/DIs1Kie8sp235jXU3f+er9+Aj0ZP6io+A
# LNcS5aKJqvXAZvG/RhQNGtkVp5+/f8vfPfF7v+AXYYpE9hm5aPLWdramok0IngdB
# KbLBt08wgoqx7TekrjGCAw0wggMJAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYD
# VQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNy
# b3NvZnQgQ29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFBDQSAyMDEwAhMzAAABB343aJiHWjfWAAAAAAEHMA0GCWCGSAFlAwQCAQUAoIIB
# SjAaBgkqhkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIGBv
# ZIsLbA3PfZRmVwt9vLwTbH7vxYIHOXgoiEmBuKn7MIH6BgsqhkiG9w0BCRACLzGB
# 6jCB5zCB5DCBvQQgQWLwo+KRZMIbpmoAE59IC4fX3QzcyJkJCjXjrUY/yx4wgZgw
# gYCkfjB8MQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYD
# VQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQQ0EgMjAxMAITMwAAAQd+N2iYh1o3
# 1gAAAAABBzAiBCBxyAJDSYQTy4meVmLiVis7J9QKwAwcB/PPhTFngWN3vDANBgkq
# hkiG9w0BAQsFAASCAQBFa9F5ku/avxBd/rKVi1dtVxZgffjfHanjGyVSTWG1hf8R
# Hp8jUZG32xTxLgvPUHeFKEH1lXJAqj3FAhO343Hqah52sKGW//dBhSugSlZAcOzR
# 8B/7r93GSpPntuGPcboExG3mfrEuy0mZX8xs/+QWSenGnrnXQHPJq7Tp2BtHYr3T
# lrq1kk3lvL+NBvoSGUG9y4yzGhCvFFzZTomJRmRMNLDWBT/I+xSOhsZc+9+/4O+j
# ATD4jyiFS7/T8tAhg5AEYvChCT9Captinez/ouhwmBpOAxEKZIivPNkavAZjMix4
# VG+6N0lkNz6SRi8V6I/s4krJXwGNkVY9brmCHrSe
# SIG # End signature block
