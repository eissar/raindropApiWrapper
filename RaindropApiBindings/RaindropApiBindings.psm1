<#
    .SYNOPSIS
    Utilities for interacting with the raindrop (raindrop.io) api.
#> 

$UriBuilderProPath = Join-Path (Resolve-Path '~\OneDrive\Application_Files\Modules\') 'UriBuilderPro.ps1'
Import-Module $UriBuilderProPath


$raindropConfig = @{
    urlExists = 'https://api.raindrop.io/rest/v1/import/url/exists'
    urlParse = 'https://api.raindrop.io/rest/v1/import/url/parse'
    createRaindrop = 'https://api.raindrop.io/rest/v1/raindrop'
    createRaindrops = 'https://api.raindrop.io/rest/v1/raindrops'
    accessToken = $env:raindropKey
}

function Invoke-RaindropApi { 
    param(
        [Parameter(Mandatory)]
        [String]$Endpoint,
        [String]$Method,
        $Body
    )
    $Headers = @{
        'Authorization' = "Bearer $($raindropConfig.accessToken)"
        'Content-Type' = 'application/json'
    }

    $params = @{
        Uri = $Endpoint
        Method = $Method
        Headers = $Headers
    }
    if ($Body) {
        if ($Body -is [String]){
            $params.Body = $Body
        }
        else {
            $params.Body = ( ConvertTo-Json -InputObject $Body -Depth 10 )
        }
    }

    try {
        $response = Invoke-RestMethod -SkipHttpErrorCheck @params
        return $response
        if (-Not $response.StatusCode -eq 200) {
            Write-Error "API Error: $($responseData.error)"
            Write-Host $reponse.Content 
        }
        else {
            return $response.Content
        }
    } catch {
        return $_
        Write-Error "Error making API call: $($_.Exception.Message)"
    }
}
Export-ModuleMember -Function 'Invoke-RaindropApi'


function Test-RaindropUrlExists {
    param(
        [Parameter(Mandatory)]
        [ValidateScript({
            [array]$_
        })]
        [array]$UriList
    )
    $params = @{
        Endpoint = $raindropConfig.urlExists
        Method = 'GET'

    }
    $params.Body = (ConvertTo-Json -InputObject @{ urls = $UriList })
    $response = (Invoke-RaindropApi @params).result
    # $response = (ConvertFrom-Json -InputObject (Invoke-RaindropApi @params) )
    return ( [System.Convert]::ToBoolean($response) )
}
Export-ModuleMember -Function 'Test-RaindropUrlExists'

function Get-RaindropMetadata {
    param(
        [Parameter(Mandatory)]
        [String]$Uri
    )
    # https://developer.raindrop.io/v1/import#parse-url
    $builder = [UriBuilderPro]::new($raindropConfig.urlParse)
    $builder.AddParameter('url',$Uri)
    $params = @{
        Endpoint = $builder.toString()
        Method = 'GET'
    }
    return Invoke-RaindropApi @params

}
Export-ModuleMember -Function 'Get-RaindropMetadata'

function Add-Raindrop {
    param(
        [Parameter(Mandatory)]
        [String]$Uri
    )
    # https://developer.raindrop.io/v1/import#parse-url
    if (Test-RaindropUrlExists -Uri $Uri) {
        Throw "Duplicate Url: $Uri "
    }
    #TODO Check if 

    $params = @{
        Endpoint = $raindropConfig.createRaindrop
        Method = 'POST'
        Body = @{
            link = $Uri
            pleaseParse = @{}
        }
    }
    return (Invoke-RaindropApi @params)

}
Export-ModuleMember -Function 'Add-Raindrop'


function Add-Raindrops {
    param(
        [Parameter(Mandatory)]
        $InputUrls
    )
    
    if(-Not ($InputUrls -is [Array]) ){
        Throw "Invalid Input: Not an array."
    }

    [Array]$urlItems = $InputUrls | ForEach-Object {
        @{
            link = $_
            pleaseParse = @{}
        }
    }
    $params = @{
        Endpoint = $raindropConfig.createRaindrops
        Method = 'POST'
        Body = @{
            items = $urlItems
        }
    }
    return ( Invoke-RaindropApi @params )
}
Export-ModuleMember -Function 'Add-Raindrops'

function Add-RaindropParsed {
    param(
        [Parameter(Mandatory)]
        $InputJson
    )
    $thisItem = ($InputJson | ConvertFrom-Json )

    $params = @{
        Endpoint = $raindropConfig.createRaindrop
        Method = 'POST'
        Body = $thisItem
    }
    return ( Invoke-RaindropApi @params )
}
Export-ModuleMember -Function 'Add-RaindropParsed'


function Add-RaindropsParsed {
    param(
        [Parameter(Mandatory)]
        $InputJson
    )
    $thisItem = ($InputJson | ConvertFrom-Json )

    $params = @{
        Endpoint = $raindropConfig.createRaindrops
        Method = 'POST'
        Body = $thisItem
    }
    return ( Invoke-RaindropApi @params )
}
Export-ModuleMember -Function 'Add-RaindropsParsed'
