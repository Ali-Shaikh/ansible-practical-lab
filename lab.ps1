param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Rest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
Set-Location $PSScriptRoot

if ($null -eq $Rest) {
    $Rest = @()
}

# The lab estate is docker-compose.yml plus one drop-in file per added host
# under compose.hosts/. Every compose call must see the same file list.
$script:BaseComposeFiles = @("-f", "docker-compose.yml")
Get-ChildItem -Path (Join-Path $PSScriptRoot "compose.hosts") -Filter "*.yml" -File -ErrorAction SilentlyContinue |
    Sort-Object Name |
    ForEach-Object { $script:BaseComposeFiles += @("-f", "compose.hosts/$($_.Name)") }

$script:ComposeFiles = @($script:BaseComposeFiles)
$script:SystemdComposeFiles = @($script:BaseComposeFiles) + @("-f", "compose.systemd.yml")

# LAB_INIT=systemd boots the default hosts with systemd as PID 1 so that
# service and systemd modules work; see compose.systemd.yml for the cost.
$script:LabInit = if ($env:LAB_INIT) { $env:LAB_INIT } else { "sshd" }
switch ($script:LabInit) {
    "sshd" { }
    "systemd" { $script:ComposeFiles += @("-f", "compose.systemd.yml") }
    default { throw "LAB_INIT must be 'sshd' (default) or 'systemd', not '$($script:LabInit)'." }
}

$script:DefaultHosts = @("forge", "atlas", "beacon", "ledger", "vaultbox")
# Default hosts, lab groups and Ansible keywords: a host with one of these
# names would clash inside the merged inventory.
$script:ReservedNames = $script:DefaultHosts + @("linux", "web", "database", "secrets", "all", "ungrouped", "localhost")

function Invoke-Compose {
    & docker compose @script:ComposeFiles @args
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Docker Compose failed with exit code $exitCode."
    }
}

function Invoke-SystemdCompose {
    & docker compose @script:SystemdComposeFiles @args
    $exitCode = $LASTEXITCODE
    if ($exitCode -ne 0) {
        throw "Docker Compose failed with exit code $exitCode."
    }
}

function Invoke-Forge {
    Invoke-Compose run --rm forge @args
}

function Initialize-LabKey {
    $keyDir = Join-Path $PSScriptRoot ".lab\ssh"
    $keyFile = Join-Path $keyDir "id_ed25519"
    $publicKeyFile = "$keyFile.pub"
    $authorizedKeysFile = Join-Path $keyDir "authorized_keys"

    New-Item -ItemType Directory -Force -Path $keyDir | Out-Null

    if (-not (Test-Path $keyFile)) {
        if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
            throw "ssh-keygen was not found in PATH. Install the Windows OpenSSH client or use WSL."
        }
        & ssh-keygen -t ed25519 -N "" -C "ansible-practical-lab" -f $keyFile | Out-Null
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to create the lab SSH key."
        }
    }

    Copy-Item -Force $publicKeyFile $authorizedKeysFile
}

function Test-HostName {
    param([string]$Name)
    # -cnotmatch: -match is case-insensitive and would let 'Titan' through,
    # which the case-sensitive bash wrapper then refuses to manage.
    if ($Name -cnotmatch '^[a-z][a-z0-9-]*$') {
        throw "Host name must start with a letter and use only lowercase letters, digits and dashes: $Name"
    }
    if ($script:ReservedNames -ccontains $Name) {
        throw "Name '$Name' is reserved (default host, lab group, or Ansible keyword)."
    }
}

function Get-NextFreeSshPort {
    $usedPorts = @(2222, 2223, 2224, 2225)
    Get-ChildItem -Path (Join-Path $PSScriptRoot "compose.hosts") -Filter "*.yml" -File -ErrorAction SilentlyContinue | ForEach-Object {
        $match = Select-String -Path $_.FullName -Pattern '"(\d+):22"'
        foreach ($m in $match) {
            $usedPorts += [int]$m.Matches[0].Groups[1].Value
        }
    }
    $port = 2226
    while ($usedPorts -contains $port) {
        $port++
    }
    return $port
}

function Add-LabHost {
    param([string]$Name, [string]$Group)
    if (-not $Name) {
        throw "Usage: .\lab.ps1 add-host <name> [group]  (example: .\lab.ps1 add-host titan web)"
    }
    Test-HostName $Name
    $composeFile = Join-Path $PSScriptRoot "compose.hosts\$Name.yml"
    if (Test-Path $composeFile) {
        throw "Host '$Name' already exists (compose.hosts/$Name.yml)."
    }
    if ($Group) {
        if ($Group -cnotmatch '^[a-z][a-z0-9_]*$') {
            throw "Group name must start with a letter and use only lowercase letters, digits and underscores: $Group"
        }
        # A group that shares a name with any host would clash in the inventory.
        $groupClashes = @("all", "ungrouped", "localhost", $Name) + $script:DefaultHosts
        if ($groupClashes -ccontains $Group) {
            throw "Group name '$Group' clashes with a host name or Ansible keyword."
        }
        if (Test-Path (Join-Path $PSScriptRoot "compose.hosts\$Group.yml")) {
            throw "Group name '$Group' clashes with the added host of the same name."
        }
    }
    # Likewise, refuse a host name that matches a group created by an
    # earlier add-host (groups sit at four-space indent in the drop-ins).
    if (Select-String -Path (Join-Path $PSScriptRoot "inventory\lab\*.yml") -Pattern "^    ${Name}:" -CaseSensitive -Quiet -ErrorAction SilentlyContinue) {
        throw "Host name '$Name' clashes with an existing inventory group."
    }

    $sshPort = Get-NextFreeSshPort

    New-Item -ItemType Directory -Force -Path (Join-Path $PSScriptRoot "compose.hosts") | Out-Null

    $composeContent = @"
services:
  ${Name}:
    build:
      context: ./docker/managed-host
      args:
        UBUNTU_VERSION: `${UBUNTU_VERSION:-24.04}
        HOST_USER: `${LAB_USER:-learner}
        HOST_PASSWORD: `${LAB_PASSWORD:-learner}
    container_name: apl-$Name
    hostname: $Name
    ports:
      - "${sshPort}:22"
    volumes:
      - ./.lab/ssh:/lab-ssh:ro
    networks:
      lab:
        aliases:
          - $Name
"@

    $groupBlock = ""
    if ($Group) {
        $groupBlock = @"

    ${Group}:
      hosts:
        ${Name}:
"@
    }

    $labInventory = @"
---
all:
  children:
    linux:
      hosts:
        ${Name}:
          ansible_host: $Name$groupBlock
"@

    $localInventory = @"
---
all:
  children:
    linux:
      hosts:
        ${Name}:
          ansible_host: 127.0.0.1
          ansible_port: $sshPort$groupBlock
"@

    # Compose and inventory files are read inside Linux containers, so keep LF endings.
    [System.IO.File]::WriteAllText($composeFile, ($composeContent -replace "`r`n", "`n") + "`n")
    [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot "inventory\lab\$Name.yml"), ($labInventory -replace "`r`n", "`n") + "`n")
    [System.IO.File]::WriteAllText((Join-Path $PSScriptRoot "inventory\local\$Name.yml"), ($localInventory -replace "`r`n", "`n") + "`n")

    $groupNote = if ($Group) { ", group: $Group" } else { "" }
    Write-Host "Added host '$Name' (SSH on 127.0.0.1:$sshPort$groupNote)."
    Write-Host "Files created:"
    Write-Host "  compose.hosts/$Name.yml"
    Write-Host "  inventory/lab/$Name.yml"
    Write-Host "  inventory/local/$Name.yml"
    Write-Host "Start it with: .\lab.ps1 up"
}

function Remove-LabHost {
    param([string]$Name)
    if (-not $Name) {
        throw "Usage: .\lab.ps1 remove-host <name>"
    }
    Test-HostName $Name
    $composeFile = Join-Path $PSScriptRoot "compose.hosts\$Name.yml"
    if (-not (Test-Path $composeFile)) {
        throw "Host '$Name' was not added with add-host (compose.hosts/$Name.yml not found)."
    }
    Invoke-Compose rm --stop --force $Name *> $null
    Remove-Item -Force -ErrorAction SilentlyContinue $composeFile,
        (Join-Path $PSScriptRoot "inventory\lab\$Name.yml"),
        (Join-Path $PSScriptRoot "inventory\local\$Name.yml")
    Write-Host "Removed host '$Name'."
}

switch -Wildcard ($Command) {
    "doctor" {
        if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
            throw "Git was not found in PATH."
        }
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            throw "Docker was not found in PATH."
        }
        if (-not (Get-Command ssh-keygen -ErrorAction SilentlyContinue)) {
            throw "ssh-keygen was not found in PATH. Install the Windows OpenSSH client or use WSL."
        }
        & docker info *> $null
        if ($LASTEXITCODE -ne 0) {
            throw "Docker is installed, but the Docker daemon is not reachable. Start Docker Desktop or the Docker service, then run this command again."
        }
        & docker compose version

        if (Test-Path -LiteralPath "VERSION") {
            $labVersion = (Get-Content -LiteralPath "VERSION" -TotalCount 1).Trim()
            Write-Host "ansible-practical-lab version: $labVersion"
        }

        # Port clashes are the most common first-run failure. Read the published
        # ports from the resolved compose config so added hosts are covered too.
        # Skip the check when the lab is already running, since it holds these
        # ports itself.
        $labRunning = & docker ps --filter "name=apl-" --format "{{.Names}}"
        if (-not $labRunning) {
            $config = Invoke-Compose config --format json | ConvertFrom-Json
            $labPorts = @()
            foreach ($service in $config.services.PSObject.Properties) {
                $servicePorts = $service.Value.PSObject.Properties["ports"]
                if ($servicePorts) {
                    foreach ($portEntry in $servicePorts.Value) {
                        $labPorts += [int]$portEntry.published
                    }
                }
            }
            $busyPorts = @()
            foreach ($port in ($labPorts | Sort-Object -Unique)) {
                if (Get-NetTCPConnection -State Listen -LocalPort $port -ErrorAction SilentlyContinue) {
                    $busyPorts += $port
                }
            }
            if ($busyPorts.Count -gt 0) {
                throw "These lab ports are already in use by another process: $($busyPorts -join ', '). Free them or change the port mapping, then run doctor again."
            }
        }

        Write-Host "Doctor checks passed."
    }
    "up" {
        Initialize-LabKey
        Invoke-Compose build forge
        Invoke-Compose up -d --build
    }
    "systemd" {
        if ($Rest.Count -gt 0) {
            throw "Usage: .\lab.ps1 systemd"
        }
        Initialize-LabKey
        Invoke-SystemdCompose build forge
        Invoke-SystemdCompose up -d --build
        Write-Host ""
        Write-Host "Systemd mode is ready on the four default managed hosts."
        Write-Host "This mode uses privileged containers and a host cgroup mount."
        Write-Host "Run '.\lab.ps1 up' to return those hosts to the default SSH-only mode."
    }
    "down" {
        # --profile studio so the optional studio container is torn down too.
        Invoke-Compose --profile studio down --remove-orphans
    }
    "reset" {
        Invoke-Compose --profile studio down --volumes --remove-orphans
        Initialize-LabKey
        Invoke-Compose build forge
        Invoke-Compose up -d --build
    }
    "status" {
        Invoke-Compose --profile studio ps
    }
    "studio" {
        Initialize-LabKey
        Invoke-Compose up -d --build studio
        Write-Host ""
        Write-Host "Studio is starting at: http://127.0.0.1:8443"
        Write-Host "Open it in your browser; the integrated terminal is already on the"
        Write-Host "lab network, so commands like 'ansible all -m ping' work directly."
        Write-Host "Stop it with: .\lab.ps1 down"
    }
    "ping" {
        Invoke-Forge ansible all -i inventory/lab -m ansible.builtin.ping
    }
    "facts" {
        Invoke-Forge ansible-playbook -i inventory/lab playbooks/01_facts.yml
    }
    "version" {
        if (Test-Path -LiteralPath "VERSION") {
            (Get-Content -LiteralPath "VERSION" -TotalCount 1).Trim()
        }
        else {
            Write-Output "unknown (no VERSION file)"
        }
    }
    "play" {
        if ($Rest.Count -lt 1) {
            throw "Usage: .\lab.ps1 play <playbook> [extra ansible-playbook args]"
        }
        Invoke-Forge ansible-playbook -i inventory/lab @Rest
    }
    "lint" {
        Invoke-Forge ansible-lint @Rest
    }
    "inventory" {
        Invoke-Forge ansible-inventory -i inventory/lab --graph @Rest
    }
    "add-host" {
        $name = if ($Rest.Count -ge 1) { $Rest[0] } else { "" }
        $group = if ($Rest.Count -ge 2) { $Rest[1] } else { "" }
        Add-LabHost -Name $name -Group $group
    }
    "remove-host" {
        $name = if ($Rest.Count -ge 1) { $Rest[0] } else { "" }
        Remove-LabHost -Name $name
    }
    "exec" {
        if ($Rest.Count -lt 1) {
            throw "Usage: .\lab.ps1 exec <command> [args]"
        }
        Invoke-Forge @Rest
    }
    "shell" {
        Invoke-Forge bash
    }
    "logs" {
        Invoke-Compose logs @Rest
    }
    "ansible*" {
        # Pass any ansible CLI straight through to the control node, e.g.
        #   .\lab.ps1 ansible web -m ansible.builtin.command -a uptime
        #   .\lab.ps1 ansible-vault encrypt vars\secret.yml
        #   .\lab.ps1 ansible-doc ansible.builtin.copy
        Invoke-Forge $Command @Rest
    }
    { $_ -in @("help", "-h", "--help") } {
        @"
Usage: .\lab.ps1 <command>

Lab lifecycle:
  doctor        Check local prerequisites
  version       Print the lab version (for pro content compatibility)
  up            Build and start the lab
  systemd       Start with real systemd (uses privileged containers)
  down          Stop and remove lab containers
  reset         Rebuild the lab from scratch
  status        Show container status
  logs          Show Docker Compose logs
  studio        Start VS Code in the browser at http://127.0.0.1:8443

Ansible:
  ping          Run ansible.builtin.ping against all managed hosts
  facts         Gather a few useful facts from all managed hosts
  play          Run a playbook, e.g. .\lab.ps1 play playbooks/10_baseline.yml
  ansible...    Run any ansible CLI in the control node, e.g.
                .\lab.ps1 ansible web -m ansible.builtin.command -a uptime
                .\lab.ps1 ansible-vault encrypt vars\secret.yml
                .\lab.ps1 ansible-galaxy collection list
  lint          Run ansible-lint over the repo (or given paths)
  inventory     Show the inventory as a group graph

Hosts:
  add-host      Add a managed host, e.g. .\lab.ps1 add-host titan web
  remove-host   Remove a host created with add-host

Other:
  shell         Open a shell in the control-node container
  exec          Run any command in the control-node container

Compatibility:
  LAB_INIT=systemd   The older environment-variable workflow remains
                     supported. For normal use, prefer '.\lab.ps1 systemd'.
"@
    }
    default {
        throw "Unknown command: $Command. Run .\lab.ps1 help"
    }
}
