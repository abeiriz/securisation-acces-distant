<#
.SYNOPSIS
    Crée le fichier d'identifiants SMTP chiffré utilisé par AlerteChaineFroid.ps1.

.DESCRIPTION
    À exécuter une seule fois, sur le serveur applicatif, sous le compte qui
    exécutera la tâche planifiée.

    Export-Clixml chiffre le mot de passe avec DPAPI. Le fichier produit n'est
    déchiffrable que par ce compte, sur cette machine. Copié ailleurs, il est
    inutilisable.

    Conséquence pratique : si la tâche planifiée s'exécute sous le compte
    SYSTEM, ce script doit être lancé sous SYSTEM, par exemple avec PsExec
    (psexec -s -i powershell.exe). Un fichier créé sous un compte
    d'administration ne sera pas lisible par SYSTEM.

.NOTES
    Le fichier produit ne doit jamais être versionné ni copié hors du serveur.
#>

[CmdletBinding()]
param(
    [string]$FichierIdent = 'C:\Scripts\smtp.cred.xml'
)

$dossier = Split-Path -Path $FichierIdent -Parent
if (-not (Test-Path $dossier)) {
    New-Item -Path $dossier -ItemType Directory -Force | Out-Null
}

Write-Host "Compte courant : $([Security.Principal.WindowsIdentity]::GetCurrent().Name)"
Write-Host "Le fichier ne sera lisible que par ce compte, sur cette machine."
Write-Host ""

$identifiants = Get-Credential -Message "Identifiants du compte SMTP d'envoi des alertes"
$identifiants | Export-Clixml -Path $FichierIdent

# Restreint l'accès au seul compte propriétaire et aux administrateurs.
$acl = Get-Acl -Path $FichierIdent
$acl.SetAccessRuleProtection($true, $false)
foreach ($compte in @($env:USERNAME, 'BUILTIN\Administrateurs')) {
    try {
        $regle = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $compte, 'FullControl', 'Allow')
        $acl.AddAccessRule($regle)
    } catch {
        Write-Warning "Compte '$compte' non resolu, regle ignoree."
    }
}
Set-Acl -Path $FichierIdent -AclObject $acl

Write-Host "Fichier cree : $FichierIdent"
