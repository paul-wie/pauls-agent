# confluence-archive.ps1 - archives sprint / PI reports on the Confluence page "19 KPI's" (ASNAST).
# Usage: .\confluence-archive.ps1 -Sprint 26/20 [-DryRun]   or   .\confluence-archive.ps1 -Pi 2026.25 [-DryRun]
# Needs: env CONFLUENCE_PERSONAL_TOKEN (exported from .env by the user) and out\sprint-<yy-nn>.html / out\pi-<id>.html
# (run kpi-calc.ps1 first). Page body = TWO two-column tables, nothing else: (Sprint | File) first, (PI | File) below.
# Same sprint/PI already archived -> its row and attachment are replaced (never a second row).
param([string]$Sprint,[string]$Pi,[switch]$DryRun)
if(($Sprint -and $Pi) -or (-not $Sprint -and -not $Pi)){ throw 'Specify exactly one of -Sprint or -Pi.' }
$ErrorActionPreference='Stop'
$PX='http://http-proxy.porsche.org:3133'; $API='https://api.skyway.porsche.com/confluence/rest/api'; $PAGEID='2714063024'
if(-not $env:CONFLUENCE_PERSONAL_TOKEN){ throw 'CONFLUENCE_PERSONAL_TOKEN is not exported in this shell.' }
$H=@{Authorization="Bearer $env:CONFLUENCE_PERSONAL_TOKEN"}
if($Sprint){ $kind='Sprint'; $id=$Sprint; $slug=$Sprint.Replace('/','-'); $src=Join-Path (Join-Path $PSScriptRoot 'out') "sprint-$slug.html"; $lvl='sprint' }
else{ $kind='PI'; $id=$Pi; $slug=$Pi; $src=Join-Path (Join-Path $PSScriptRoot 'out') "pi-$slug.html"; $lvl='pi' }
if(-not(Test-Path $src)){ throw "Missing $src - run kpi-calc.ps1 -Level $lvl -Id $id first." }
$name="$kind KPI Report $slug - erstellt $((Get-Date).ToString('yyyy-MM-dd')).html"
$prefix="$kind KPI Report $slug - erstellt "

$page=Invoke-RestMethod -Proxy $PX -Headers $H "$API/content/$PAGEID`?expand=body.storage,version"
$atts=@((Invoke-RestMethod -Proxy $PX -Headers $H "$API/content/$PAGEID/child/attachment?limit=200").results)
$old=@($atts|?{$_.title.StartsWith($prefix)})

$link='<ac:link><ri:attachment ri:filename="'+$name+'" /><ac:plain-text-link-body><![CDATA['+$name+']]></ac:plain-text-link-body></ac:link>'
$row='<tr><td>'+$id+'</td><td>'+$link+'</td></tr>'
$body=$page.body.storage.value
$tbl=[regex]::Matches($body,'(?s)<table.*?</table>')|?{ $_.Value -match ('(?s)<th[^>]*>\s*(<p[^>]*>)?\s*'+$kind+'\s*(</p>)?\s*</th>') }|Select -First 1
$newTbl='<table><tbody><tr><th>'+$kind+'</th><th>File</th></tr>'+$row+'</tbody></table>'
if(-not $tbl){ $mode='create table'; $body=$body+$newTbl }
else{
 $tv=$tbl.Value
 $rx='(?s)<tr[^>]*>\s*<td[^>]*>\s*(<p[^>]*>)?\s*'+[regex]::Escape($id)+'\s*(</p>)?\s*</td>.*?</tr>'
 if($tv -match $rx){ $mode='replace row'; $tv=[regex]::Replace($tv,$rx,[Text.RegularExpressions.MatchEvaluator]{param($m) $row},1) }
 else{ $mode='append row'; $i=$tv.LastIndexOf('</tbody>'); $tv=$tv.Substring(0,$i)+$row+$tv.Substring($i) }
 $body=$body.Substring(0,$tbl.Index)+$tv+$body.Substring($tbl.Index+$tbl.Length)
}
"$kind $id -> attachment '$name' ($([IO.File]::ReadAllBytes($src).Length) bytes); page row: $mode; replacing old attachments: $(@($old|%{$_.title}) -join ', ')"
if($DryRun){ 'DRY RUN - nothing written.'; return }

foreach($o in $old){ Invoke-RestMethod -Proxy $PX -Headers $H -Method Delete "$API/content/$($o.id)" | Out-Null }
$TMP=[IO.Path]::GetTempPath(); $CURL=$(if($IsWindows -or $env:OS -eq 'Windows_NT'){'curl.exe'}else{'curl'})
$tmp=Join-Path $TMP $name; Copy-Item $src $tmp -Force
$upl=Join-Path $TMP 'conf-up.json'
$code=& $CURL -s -S -x $PX -o $upl -w '%{http_code}' -X POST -H "Authorization: Bearer $env:CONFLUENCE_PERSONAL_TOKEN" -H 'X-Atlassian-Token: no-check' -F "file=@$tmp;type=text/html" -F "comment=$kind KPI Report $id, created $((Get-Date).ToString('yyyy-MM-dd')). This content was generated with the support of AI. Source: Jira ASNAST." -F 'minorEdit=false' "$API/content/$PAGEID/child/attachment"
Remove-Item $tmp,$upl -ErrorAction SilentlyContinue
if($code -ne '200'){ throw "Attachment upload failed (HTTP $code); page table NOT changed." }
$put=@{id=$PAGEID;type='page';title=$page.title;version=@{number=$page.version.number+1;message="Archive $kind report $id ($mode)"};body=@{storage=@{value=$body;representation='storage'}}}|ConvertTo-Json -Depth 6
Invoke-RestMethod -Proxy $PX -Headers $H -Method Put -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($put)) "$API/content/$PAGEID" | Out-Null
"Done: $name archived; row $mode."
