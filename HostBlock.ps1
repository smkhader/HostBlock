<#
.SYNOPSIS
Blocks every hostname found in supplied or pasted text.

.DESCRIPTION
Recognizes hostnames in URLs, HTML, JavaScript, and plain text.

Examples:
    https://www.example.com/path
    //www.example.com/path
    www.example.com/path
    www.example.com\path
    s:\\www.example.com\path

When -Url is omitted, listener mode starts automatically.
Press Ctrl+C to stop.

.PARAMETER Url
Text containing one or more hostnames.

.PARAMETER AltHostFile
Hosts file to modify. Defaults to the Windows hosts file.

.PARAMETER BlockIp
IP address assigned to blocked hostnames. Defaults to 0.0.0.0.
#>

param(
    [string]$Url,

    [string]$AltHostFile =
        "$env:SystemRoot\System32\drivers\etc\hosts",

    [string]$BlockIp = "0.0.0.0"
)

# Embedded TLDs.
# Includes common generic TLDs and recognized country-code TLDs.
$TldText = @"
academy accountant accountants agency app art asia audio autos
biz blog business cafe camera capital careers center chat city
cloud club codes coffee company computer consulting contact cool
coop design dev digital directory download education email energy
engineering events exchange expert express finance financial fit
foundation fun games global google gov group guide guru health
help homes host info international io jobs life live ltd marketing
media mil mobi money museum name network news ninja online org
page photography photos pro properties property pub repair report
restaurant reviews school services shop shopping site social
software solutions space store studio support systems tech technology
today tools top tours trade training travel tv university website
wiki work world xyz zone com net edu aero arpa

ac ad ae af ag ai al am ao aq ar as at au aw ax az
ba bb bd be bf bg bh bi bj bm bn bo br bs bt bv bw by bz
ca cc cd cf cg ch ci ck cl cm cn co cr cu cv cw cx cy cz
de dj dk dm do dz
ec ee eg er es et eu
fi fj fk fm fo fr
ga gb gd ge gf gg gh gi gl gm gn gp gq gr gs gt gu gw gy
hk hm hn hr ht hu
id ie il im in iq ir is it
je jm jo jp
ke kg kh ki km kn kp kr kw ky kz
la lb lc li lk lr ls lt lu lv ly
ma mc md me mg mh mk ml mm mn mo mp mq mr ms mt mu mv
mw mx my mz
na nc ne nf ng ni nl no np nr nu nz
om
pa pe pf pg ph pk pl pm pn pr ps pt pw py
qa
re ro rs ru rw
sa sb sc sd se sg sh si sj sk sl sm sn so sr ss st sv
sx sy sz
tc td tf tg th tj tk tl tm tn to tr tt tw tz
ua ug uk us uy uz
va vc ve vg vi vn vu
wf ws
ye yt
za zm zw
"@

# Build a case-insensitive TLD lookup table.
$ValidTlds = @{}

foreach ($tld in ($TldText -split '\s+')) {
    if ($tld) {
        $ValidTlds[$tld.ToLowerInvariant()] = $true
    }
}

function Get-HostNames {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    # Find every dotted hostname in the pasted text.
    $pattern = '(?i)([a-z0-9][a-z0-9-]*\.)+[a-z]{2,63}'

    $result = Select-String `
        -InputObject $Text `
        -Pattern $pattern `
        -AllMatches `
        -ErrorAction Stop

    $hostNames = foreach ($match in $result.Matches) {
        $hostName = $match.Value.ToLowerInvariant().TrimEnd('.')
        $labels = $hostName -split '\.'
        $tld = $labels[-1]

        # Reject labels beginning or ending with a hyphen.
        $validLabels = $true

        foreach ($label in $labels) {
            if (
                -not $label -or
                $label.StartsWith('-') -or
                $label.EndsWith('-') -or
                $label.Length -gt 63
            ) {
                $validLabels = $false
                break
            }
        }

        if (
            $validLabels -and
            $ValidTlds.ContainsKey($tld)
        ) {
            $hostName
        }
    }

    return @($hostNames | Sort-Object -Unique)
}

function Get-ExistingHosts {
    $existingHosts = @()

    foreach ($line in Get-Content -LiteralPath $AltHostFile) {
        # Remove comments.
        $activeLine = ($line -split '#', 2)[0].Trim()

        if (-not $activeLine) {
            continue
        }

        $fields = $activeLine -split '\s+'

        if ($fields.Count -ge 2) {
            foreach ($existingHost in $fields[1..($fields.Count - 1)]) {
                $existingHosts += $existingHost.ToLowerInvariant()
            }
        }
    }

    return @($existingHosts | Sort-Object -Unique)
}

function Add-HostBlocks {
    param(
        [Parameter(Mandatory)]
        [string]$Text
    )

    $hostNames = @(Get-HostNames -Text $Text)

    if ($hostNames.Count -eq 0) {
        Write-Host "No valid hostnames found." -ForegroundColor Red
        return
    }

    $existingHosts = @(Get-ExistingHosts)

    foreach ($hostName in $hostNames) {
        if ($existingHosts -icontains $hostName) {
            Write-Host "Already exists: $hostName" `
                -ForegroundColor Yellow

            continue
        }

        try {
            Add-Content `
                -LiteralPath $AltHostFile `
                -Value "$BlockIp`t$hostName" `
                -ErrorAction Stop

            $existingHosts += $hostName

            Write-Host "Added: $hostName" `
                -ForegroundColor Green
        }
        catch {
            Write-Host "Unable to add $hostName" `
                -ForegroundColor Red

            Write-Host $_.Exception.Message `
                -ForegroundColor Red
        }
    }
}

# Create the destination file before reading it.
if (-not (Test-Path -LiteralPath $AltHostFile)) {
    try {
        New-Item `
            -Path $AltHostFile `
            -ItemType File `
            -Force `
            -ErrorAction Stop |
            Out-Null
    }
    catch {
        Write-Host "Unable to create: $AltHostFile" `
            -ForegroundColor Red

        Write-Host $_.Exception.Message `
            -ForegroundColor Red

        exit 1
    }
}

if (-not $Url) {
    # Listener mode.
    Write-Host ""
    Write-Host "Listener mode started." -ForegroundColor Cyan
    Write-Host "Hosts file: $AltHostFile"
    Write-Host "Paste text containing one or more hostnames."
    Write-Host "Press Ctrl+C to exit."
    Write-Host ""

    while ($true) {
        $inputText = Read-Host "Paste"

        if ($inputText) {
            Add-HostBlocks -Text $inputText
        }
    }
}
else {
    # Single-input mode.
    Add-HostBlocks -Text $Url
}
