
#set-MailboxFolderPermission junger:\kalender -User Standard -AccessRights reviewer


#get-mailbox | where {$_.test = test}

#get-MailboxFolderPermission mbraun:\kalender

Start-Transcript "C:\scripts\log.txt"

$ausschluss = @(
'vss',
'administrator',
'info'
'sammepostfach')

#Kalender Brühwiler
$allusers = Get-User -RecipientTypeDetails UserMailbox -ResultSize Unlimited | where {$_.UseraccountControl -notlike "accountdisabled" -and $_.name -notin $ausschluss}
$users = $allusers | where{$_.identity -like "ad.br-ing.ch/Brühwiler AG*"}
foreach($mailbox in $users)
{
$exists = 0
$kalender = $mailbox.name.ToString()+":\kalender"
Set-MailboxFolderPermission $kalender  -User Standard -AccessRights LimitedDetails

$permissions = Get-MailboxFolderPermission $kalender
#Check if permission exists to avoid error
foreach($permission in $permissions)
{
if($permission.user.DisplayName -eq "G_Kalenderressourcen_Editor")
{$exists = 1}
}

if($exists -eq 1)
{set-MailboxFolderPermission $kalender  -User G_Kalenderressourcen_Editor -AccessRights Editor}
else
{add-MailboxFolderPermission $kalender  -User G_Kalenderressourcen_Editor -AccessRights Editor}

}
#Kalender Kolb
$users = $allusers | where{$_.identity -like "ad.br-ing.ch/Kolb AG*"}
foreach($mailbox in $users)
{
$exists = 0
$kalender = $mailbox.name.ToString()+":\kalender"
Set-MailboxFolderPermission $kalender  -User Standard -AccessRights LimitedDetails

$permissions = Get-MailboxFolderPermission $kalender

#Check if permission exists to avoid error
foreach($permission in $permissions)
{
if($permission.user.DisplayName -eq "Ivan Brühwiler")
{$exists = 1}
}

if($exists -eq 1)
{set-MailboxFolderPermission $kalender  -User ivan.bruehwiler -AccessRights Editor}
else
{add-MailboxFolderPermission $kalender  -User ivan.bruehwiler -AccessRights Editor}

}



Stop-Transcript

