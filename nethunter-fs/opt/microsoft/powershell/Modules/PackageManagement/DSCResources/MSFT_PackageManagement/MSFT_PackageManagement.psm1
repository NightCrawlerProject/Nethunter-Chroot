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
# This PS DSC resource enables installing a package. The resource uses Install-Package cmdlet
# to install the package from various providers/sources.

Import-LocalizedData -BindingVariable LocalizedData -filename MSFT_PackageManagement.strings.psd1

Import-Module -Name "$PSScriptRoot\..\PackageManagementDscUtilities.psm1"

function Get-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Get-TargetResource returns the current state of the resource.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.

    .PARAMETER AdditionalParameters
    Provider specific parameters that are passed as an Hashtable. For example, for NuGet provider you can
    pass additional parameters like DestinationPath.
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $RequiredVersion,
        
        [Parameter()]
        [System.String]
        $MinimumVersion,

        [Parameter()]
        [System.String]
        $MaximumVersion,

        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [PSCredential] $SourceCredential,

        [Parameter()]
        [System.String]
        $ProviderName,
        
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$AdditionalParameters        
    )
    
    $ensure = "Absent"
    $null = $PSBoundParameters.Remove("Source")
    $null = $PSBoundParameters.Remove("SourceCredential")

    if ($AdditionalParameters)
    {
         foreach($instance in $AdditionalParameters)
         {
             Write-Verbose ('AdditionalParameter: {0}, AdditionalParameterValue: {1}' -f $instance.Key, $instance.Value)
             $null = $PSBoundParameters.Add($instance.Key, $instance.Value)
         }
    }
    $null = $PSBoundParameters.Remove("AdditionalParameters")
    
    $verboseMessage =$localizedData.StartGetPackage -f (GetMessageFromParameterDictionary $PSBoundParameters),$env:PSModulePath
    Write-Verbose -Message $verboseMessage
    $result = PackageManagement\Get-Package @PSBoundParameters -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        

    if ($result.count -eq 1)
    {
        Write-Verbose -Message ($localizedData.PackageFound -f $Name)
        $ensure = "Present"
    }
    elseif ($result.count -gt 1)
    {
        Write-Verbose -Message ($localizedData.MultiplePackagesFound -f $Name)
        $ensure = "Present"
    }
    else
    {
        Write-Verbose -Message ($localizedData.PackageNotFound -f $($Name))
    }

    Write-Debug -Message "Source $($Name) is $($ensure)"
                         
    
    if ($ensure -eq 'Absent')
    {
        return @{
            Ensure       = $ensure
            Name         = $Name
            ProviderName = $ProviderName
            RequiredVersion = $RequiredVersion
            MinimumVersion = $MinimumVersion
            MaximumVersion = $MaximumVersion
        }
    }
    else
    {
        if ($result.Count -gt 1)
        {
          $result = $result[0]
        }

        return  @{
                Ensure             = $ensure
                Name               = $result.Name
                ProviderName       = $result.ProviderName
                Source             = $result.source
                RequiredVersion    = $result.Version
            } 
    } 
}

function Test-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Test-TargetResource returns a boolean which determines whether the resource is in
    desired state or not.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.

    .PARAMETER AdditionalParameters
    Provider specific parameters that are passed as an Hashtable. For example, for NuGet provider you can
    pass additional parameters like DestinationPath.
    #>

    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $RequiredVersion,
        
        [Parameter()]
        [System.String]
        $MinimumVersion,

        [Parameter()]
        [System.String]
        $MaximumVersion,

        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [PSCredential] $SourceCredential,
                
        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present",

        [Parameter()]
        [System.String]
        $ProviderName,
        
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$AdditionalParameters         
    )

    
    Write-Verbose -Message ($localizedData.StartTestPackage -f (GetMessageFromParameterDictionary $PSBoundParameters))
    $null = $PSBoundParameters.Remove("Ensure")
    
    $temp = Get-TargetResource @PSBoundParameters

    if ($temp.Ensure -eq $ensure)
    {
        Write-Verbose -Message ($localizedData.InDesiredState -f $Name, $Ensure, $temp.Ensure)            
        return $True 
    }
    else
    {
        Write-Verbose -Message ($localizedData.NotInDesiredState -f $Name,$ensure,$temp.ensure)            
        return [bool] $False
    }    
}

function Set-TargetResource
{
    <#
    .SYNOPSIS

    This DSC resource provides a mechanism to download and install packages on a computer. 

    Set-TargetResource either intalls or uninstall a package as defined by the vaule of Ensure parameter.

    .PARAMETER Name
    Specifies the name of the Package to be installed or uninstalled.

    .PARAMETER Source
    Specifies the name of the package source where the package can be found.
    This can either be a URI or a source registered with Register-PackageSource cmdlet.
    The DSC resource MSFT_PackageManagementSource can also register a package source.
    
    .PARAMETER RequiredVersion
    Specifies the exact version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the newest available version of the package that also satisfies any
    maximum version specified by the MaximumVersion parameter.

    .PARAMETER MaximumVersion
    Specifies the maximum allowed version of the package that you want to install. If you do not specify this parameter, 
    this DSC resource installs the highest-numbered available version of the package.

    .PARAMETER MinimumVersion
    Specifies the minimum allowed version of the package that you want to install. If you do not add this parameter, 
    this DSC resource intalls the highest available version of the package that also satisfies any maximum 
    specified version specified by the MaximumVersion parameter.

    .PARAMETER SourceCredential
    Specifies a user account that has rights to install a package for a specified package provider or source.

    .PARAMETER ProviderName
    Specifies a package provider name to which to scope your package search. You can get package provider names 
    by running the Get-PackageProvider cmdlet.

    .PARAMETER AdditionalParameters
    Provider specific parameters that are passed as an Hashtable. For example, for NuGet provider you can
    pass additional parameters like DestinationPath.
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.String]
        $Name,

        [Parameter()]
        [System.String]
        $RequiredVersion,
        
        [Parameter()]
        [System.String]
        $MinimumVersion,

        [Parameter()]
        [System.String]
        $MaximumVersion,

        [Parameter()]
        [System.String]
        $Source,

        [Parameter()]
        [PSCredential] $SourceCredential,

        [ValidateSet("Present","Absent")]
        [System.String]
        $Ensure="Present",

        [Parameter()]
        [System.String]
        $ProviderName,
        
        [Parameter()]
        [Microsoft.Management.Infrastructure.CimInstance[]]$AdditionalParameters        
    )

    Write-Verbose -Message ($localizedData.StartSetPackage -f (GetMessageFromParameterDictionary $PSBoundParameters))
    
    $null = $PSBoundParameters.Remove("Ensure")

    if ($PSBoundParameters.ContainsKey("SourceCredential"))
    {
        $PSBoundParameters.Add("Credential", $SourceCredential)
        $null = $PSBoundParameters.Remove("SourceCredential")
    }
    
    if ($AdditionalParameters)
    {
         foreach($instance in $AdditionalParameters)
         {
             Write-Verbose ('AdditionalParameter: {0}, AdditionalParameterValue: {1}' -f $instance.Key, $instance.Value)
             $null = $PSBoundParameters.Add($instance.Key, $instance.Value)
         }
    }

    $PSBoundParameters.Remove("AdditionalParameters")

       
        # We do not want others to control the behavior of ErrorAction
        # while calling Install-Package/Uninstall-Package.
        $PSBoundParameters.Remove("ErrorAction")
        if ($Ensure -eq "Present")
        {
            PackageManagement\Install-Package @PSBoundParameters -ErrorAction Stop
        }   
        else
        {
            # we dont source location for uninstalling an already
            # installed package
            $PSBoundParameters.Remove("Source")
            # Ensure is Absent
            PackageManagement\Uninstall-Package @PSBoundParameters -ErrorAction Stop
        }
 }
 
 function GetMessageFromParameterDictionary
 {
    <#
        Returns a strng of form "ParameterName:ParameterValue"
        Used with Write-Verbose message. The input is mostly $PSBoundParameters
    #>
    param([System.Collections.IDictionary] $paramDictionary)

    $returnValue = ""
    $paramDictionary.Keys | ForEach-Object { $returnValue += "-{0} {1} " -f $_,$paramDictionary[$_] }
    return $returnValue
 }

Export-ModuleMember -function Get-TargetResource, Set-TargetResource, Test-TargetResource


# SIG # Begin signature block
# MIIkXAYJKoZIhvcNAQcCoIIkTTCCJEkCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCBNHExVsaD0kyJT
# faO9Fdru5c5dZNw/I2f/WOIZwqnZQKCCDYUwggYDMIID66ADAgECAhMzAAABUptA
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
# cVZOSEXAQsmbdlsKgEhr/Xmfwb1tbWrJUnMTDXpQzTGCFi0wghYpAgEBMIGVMH4x
# CzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRt
# b25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKDAmBgNVBAMTH01p
# Y3Jvc29mdCBDb2RlIFNpZ25pbmcgUENBIDIwMTECEzMAAAFSm0CfUFaZdYgAAAAA
# AVIwDQYJYIZIAWUDBAIBBQCgga4wGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQw
# HAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwLwYJKoZIhvcNAQkEMSIEIPEd
# T5n6MHHUWamAKxOugW8JXFcy18ebdrQ+YUj78gxKMEIGCisGAQQBgjcCAQwxNDAy
# oBSAEgBNAGkAYwByAG8AcwBvAGYAdKEagBhodHRwOi8vd3d3Lm1pY3Jvc29mdC5j
# b20wDQYJKoZIhvcNAQEBBQAEggEAARri2MCfpybz7Oxy1UY9Djy7x4M08/QgxRbF
# n1OtfUccWJ1//7wqbiL4kGEhqW5Bx1iMykp8td7f71dRE5+hF9vx2nddx+oNhwlI
# Y0gPmTna1wsxF4Cbr4NvKYiumpKTsCUmLhy50QHQLI/qsuvMnrr9Htf7CPfh7HvM
# uCbs+2fgFw74fkMFGvOVLAv67wohu5jLG3YeAwinRw4WfWdbcB3MyGq5T6rUwI/e
# TqggMn6CUQuEb7BpPO835xxFK4muhgzOH9HrHbqtYEKmMPRbKEksXJ6ZJKpK5R8M
# dj07RmfYpUAxMQf8kMqvnYP9DvWCIhqF6800szW2f7AaTeDrT6GCE7cwghOzBgor
# BgEEAYI3AwMBMYITozCCE58GCSqGSIb3DQEHAqCCE5AwghOMAgEDMQ8wDQYJYIZI
# AWUDBAIBBQAwggFYBgsqhkiG9w0BCRABBKCCAUcEggFDMIIBPwIBAQYKKwYBBAGE
# WQoDATAxMA0GCWCGSAFlAwQCAQUABCDnRyAV1KCrueTODPW/wp6Kjxx13RSIS7lX
# J0vwfE3xMAIGXfpEPrSDGBMyMDE5MTIyMzE5NDY0Ny42MjVaMAcCAQGAAgH0oIHU
# pIHRMIHOMQswCQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UE
# BxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSkwJwYD
# VQQLEyBNaWNyb3NvZnQgT3BlcmF0aW9ucyBQdWVydG8gUmljbzEmMCQGA1UECxMd
# VGhhbGVzIFRTUyBFU046NTg0Ny1GNzYxLTRGNzAxJTAjBgNVBAMTHE1pY3Jvc29m
# dCBUaW1lLVN0YW1wIFNlcnZpY2Wggg8fMIIE9TCCA92gAwIBAgITMwAAAQUHOepZ
# 81W/KgAAAAABBTANBgkqhkiG9w0BAQsFADB8MQswCQYDVQQGEwJVUzETMBEGA1UE
# CBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGltZS1TdGFtcCBQ
# Q0EgMjAxMDAeFw0xOTA5MDYyMDQxMThaFw0yMDEyMDQyMDQxMThaMIHOMQswCQYD
# VQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEe
# MBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSkwJwYDVQQLEyBNaWNyb3Nv
# ZnQgT3BlcmF0aW9ucyBQdWVydG8gUmljbzEmMCQGA1UECxMdVGhhbGVzIFRTUyBF
# U046NTg0Ny1GNzYxLTRGNzAxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0YW1w
# IFNlcnZpY2UwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQDMIpZjVUiL
# WQGqDFLLaeGfhc9bxCwi8HQx+gcaF5Zz2GodhM71oyjal6uqnRM8QHxj49uKFmY/
# SWEhlV+so3IrmEHVLmskeEQaio5PxVgUWRm+sBIJpS9GjwKrGPZ2ub4ST2J9fu5F
# xbfTmJyB2AL6W7WcSUON8tyuz2/NRAII6YuojdMa6mjVXamL2AS7PBo1GW4Pa4Xb
# NhEQoA4/siS4JGbcfAwVMGv87bhKapDqpXLbDq6LbFdLAv7Q7eUHiHS4eccXRNGA
# npkdhHOK7s1O9FqpRZYsbx/UpkaoyqiQe/JFTA+1keYZsZgaQqgPNpGYD50SDDyQ
# Z2vtNx7KVgXtAgMBAAGjggEbMIIBFzAdBgNVHQ4EFgQUPXQb/rp3KEzK6DYOy3Fn
# /QIzNyIwHwYDVR0jBBgwFoAU1WM6XIoxkPNDe3xGG8UzaFqFbVUwVgYDVR0fBE8w
# TTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3NvZnQuY29tL3BraS9jcmwvcHJvZHVj
# dHMvTWljVGltU3RhUENBXzIwMTAtMDctMDEuY3JsMFoGCCsGAQUFBwEBBE4wTDBK
# BggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraS9jZXJ0cy9N
# aWNUaW1TdGFQQ0FfMjAxMC0wNy0wMS5jcnQwDAYDVR0TAQH/BAIwADATBgNVHSUE
# DDAKBggrBgEFBQcDCDANBgkqhkiG9w0BAQsFAAOCAQEAp85hd3trAVfmVAPmcOAq
# nM47TbWB9S0ySGG/eNvIfhgYC0YjCLEZhiiQyOeRTws0lIOWGv7tM5tr70RGzNo1
# /C7SQadqQ2dT5sUj7Ga6LHO2excdzRvUIwdeOaVuaj4VpiXnhjPBRu2CVNGXPe1d
# 7Zzw7di8xh2D6ooZBjhHLh7yGf2ZFjBjLcDVjrfaLwd4YqefJgg42s8EMUoXzsTp
# PlS0IBKWeX+RbBycOUhXpK9qlvFbBQGp4N+uLEV6haG33oVOtWwrbhu5F0E4UDzs
# FUaZ8OALyKraR1dIo+ZU+zjpn3Na7KUkrT/1UFYdnWYwoUDm9e+DmBhqdhUlxIhR
# nzCCBnEwggRZoAMCAQICCmEJgSoAAAAAAAIwDQYJKoZIhvcNAQELBQAwgYgxCzAJ
# BgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25k
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jv
# c29mdCBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDEwMB4XDTEwMDcwMTIx
# MzY1NVoXDTI1MDcwMTIxNDY1NVowfDELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldh
# c2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBD
# b3Jwb3JhdGlvbjEmMCQGA1UEAxMdTWljcm9zb2Z0IFRpbWUtU3RhbXAgUENBIDIw
# MTAwggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCpHQ28dxGKOiDs/BOX
# 9fp/aZRrdFQQ1aUKAIKF++18aEssX8XD5WHCdrc+Zitb8BVTJwQxH0EbGpUdzgkT
# jnxhMFmxMEQP8WCIhFRDDNdNuDgIs0Ldk6zWczBXJoKjRQ3Q6vVHgc2/JGAyWGBG
# 8lhHhjKEHnRhZ5FfgVSxz5NMksHEpl3RYRNuKMYa+YaAu99h/EbBJx0kZxJyGiGK
# r0tkiVBisV39dx898Fd1rL2KQk1AUdEPnAY+Z3/1ZsADlkR+79BL/W7lmsqxqPJ6
# Kgox8NpOBpG2iAg16HgcsOmZzTznL0S6p/TcZL2kAcEgCZN4zfy8wMlEXV4WnAEF
# TyJNAgMBAAGjggHmMIIB4jAQBgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU1WM6
# XIoxkPNDe3xGG8UzaFqFbVUwGQYJKwYBBAGCNxQCBAweCgBTAHUAYgBDAEEwCwYD
# VR0PBAQDAgGGMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgwFoAU1fZWy4/oolxi
# aNE9lJBb186aGMQwVgYDVR0fBE8wTTBLoEmgR4ZFaHR0cDovL2NybC5taWNyb3Nv
# ZnQuY29tL3BraS9jcmwvcHJvZHVjdHMvTWljUm9vQ2VyQXV0XzIwMTAtMDYtMjMu
# Y3JsMFoGCCsGAQUFBwEBBE4wTDBKBggrBgEFBQcwAoY+aHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraS9jZXJ0cy9NaWNSb29DZXJBdXRfMjAxMC0wNi0yMy5jcnQw
# gaAGA1UdIAEB/wSBlTCBkjCBjwYJKwYBBAGCNy4DMIGBMD0GCCsGAQUFBwIBFjFo
# dHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vUEtJL2RvY3MvQ1BTL2RlZmF1bHQuaHRt
# MEAGCCsGAQUFBwICMDQeMiAdAEwAZQBnAGEAbABfAFAAbwBsAGkAYwB5AF8AUwB0
# AGEAdABlAG0AZQBuAHQALiAdMA0GCSqGSIb3DQEBCwUAA4ICAQAH5ohRDeLG4Jg/
# gXEDPZ2joSFvs+umzPUxvs8F4qn++ldtGTCzwsVmyWrf9efweL3HqJ4l4/m87WtU
# VwgrUYJEEvu5U4zM9GASinbMQEBBm9xcF/9c+V4XNZgkVkt070IQyK+/f8Z/8jd9
# Wj8c8pl5SpFSAK84Dxf1L3mBZdmptWvkx872ynoAb0swRCQiPM/tA6WWj1kpvLb9
# BOFwnzJKJ/1Vry/+tuWOM7tiX5rbV0Dp8c6ZZpCM/2pif93FSguRJuI57BlKcWOd
# eyFtw5yjojz6f32WapB4pm3S4Zz5Hfw42JT0xqUKloakvZ4argRCg7i1gJsiOCC1
# JeVk7Pf0v35jWSUPei45V3aicaoGig+JFrphpxHLmtgOR5qAxdDNp9DvfYPw4Ttx
# Cd9ddJgiCGHasFAeb73x4QDf5zEHpJM692VHeOj4qEir995yfmFrb3epgcunCaw5
# u+zGy9iCtHLNHfS4hQEegPsbiSpUObJb2sgNVZl6h3M7COaYLeqN4DMuEin1wC9U
# JyH3yKxO2ii4sanblrKnQqLJzxlBTeCG+SqaoxFmMNO7dDJL32N79ZmKLxvHIa9Z
# ta7cRDyXUHHXodLFVeNp3lfB0d4wwP3M5k37Db9dT+mdHhk4L7zPWAUu7w2gUDXa
# 7wknHNWzfjUeCLraNtvTX4/edIhJEqGCA60wggKVAgEBMIH+oYHUpIHRMIHOMQsw
# CQYDVQQGEwJVUzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9u
# ZDEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSkwJwYDVQQLEyBNaWNy
# b3NvZnQgT3BlcmF0aW9ucyBQdWVydG8gUmljbzEmMCQGA1UECxMdVGhhbGVzIFRT
# UyBFU046NTg0Ny1GNzYxLTRGNzAxJTAjBgNVBAMTHE1pY3Jvc29mdCBUaW1lLVN0
# YW1wIFNlcnZpY2WiJQoBATAJBgUrDgMCGgUAAxUA0nmc7MiH2Pr0x33n13Zg4RlV
# 9qqggd4wgdukgdgwgdUxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpXYXNoaW5ndG9u
# MRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRp
# b24xKTAnBgNVBAsTIE1pY3Jvc29mdCBPcGVyYXRpb25zIFB1ZXJ0byBSaWNvMScw
# JQYDVQQLEx5uQ2lwaGVyIE5UUyBFU046NERFOS0wQzVFLTNFMDkxKzApBgNVBAMT
# Ik1pY3Jvc29mdCBUaW1lIFNvdXJjZSBNYXN0ZXIgQ2xvY2swDQYJKoZIhvcNAQEF
# BQACBQDhq3BWMCIYDzIwMTkxMjI0MDA1NjU0WhgPMjAxOTEyMjUwMDU2NTRaMHQw
# OgYKKwYBBAGEWQoEATEsMCowCgIFAOGrcFYCAQAwBwIBAAICAqQwBwIBAAICF/ow
# CgIFAOGswdYCAQAwNgYKKwYBBAGEWQoEAjEoMCYwDAYKKwYBBAGEWQoDAaAKMAgC
# AQACAxbjYKEKMAgCAQACAwehIDANBgkqhkiG9w0BAQUFAAOCAQEAmOTH8dmGXTrL
# p57JCIqmTCuyI8IYhvVaIVxE7M1HoH8DNDHGg1+KT1WWUS9J0bi1A0XLcjtViS2/
# 96O7jyyDR1qMvNskv129qJGP6xIw6sIrY1LTmi83Vj5+A0XhmYV82+02FioeJD8B
# luOLDKPp/iJTkYL6jQOGqfIcsostODDsZ1kKcTpXXl+n34pu8ikqsDbDDjmOyO6Z
# Nh7Li+bnk/j87CHHdhUEDM2Q+iwwkT0uLz/CLA1ivqaWHGm7mw4GBnd9kwjxIB3Q
# N5gOWMB1eq7RIP00rl/skL3Zb5HcpQKjPesalWisAdJ49cvQh3MVRsGH62q8HGh+
# ZwDitYUNTzGCAvUwggLxAgEBMIGTMHwxCzAJBgNVBAYTAlVTMRMwEQYDVQQIEwpX
# YXNoaW5ndG9uMRAwDgYDVQQHEwdSZWRtb25kMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xJjAkBgNVBAMTHU1pY3Jvc29mdCBUaW1lLVN0YW1wIFBDQSAy
# MDEwAhMzAAABBQc56lnzVb8qAAAAAAEFMA0GCWCGSAFlAwQCAQUAoIIBMjAaBgkq
# hkiG9w0BCQMxDQYLKoZIhvcNAQkQAQQwLwYJKoZIhvcNAQkEMSIEIMrupEjohhBT
# rYTuZrYWIvcuJ8eVGcx/c8ogZx7pGORQMIHiBgsqhkiG9w0BCRACDDGB0jCBzzCB
# zDCBsQQU0nmc7MiH2Pr0x33n13Zg4RlV9qowgZgwgYCkfjB8MQswCQYDVQQGEwJV
# UzETMBEGA1UECBMKV2FzaGluZ3RvbjEQMA4GA1UEBxMHUmVkbW9uZDEeMBwGA1UE
# ChMVTWljcm9zb2Z0IENvcnBvcmF0aW9uMSYwJAYDVQQDEx1NaWNyb3NvZnQgVGlt
# ZS1TdGFtcCBQQ0EgMjAxMAITMwAAAQUHOepZ81W/KgAAAAABBTAWBBRKfl8v1+DW
# YOI4a8D47RB2NH3tpzANBgkqhkiG9w0BAQsFAASCAQAfc1P/is8N07+sYVWwVFRX
# 66a4bV8PVRRv8Fk00TEgOzwCvOvSqMNDlpdkUySotGORRH2xXc2x5zm5NEe9IOln
# CO60xRZlWCf339szF/nW47pttOfKHENuDEAJwYg0LMIU3F/lmokZPvmzX8tk7Qum
# x5MWi8sxRuGm8peRvpfea715Hzu70TfHaPt3oYMyv/H5E6zDnczN+DjnWGOyEXcG
# F30n6pFATlCtgGmUNHr53g3ryxUsrg6TBu6VEVpGLjBcbIlU5cBCt4pBjTyrhHX/
# leZmL+Dbqw5t46Myk/Wogm1XpfU7kBc0Mm6o20PteG69v0tZADV3nXayXhS6Sg0G
# SIG # End signature block
