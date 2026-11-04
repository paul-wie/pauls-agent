# kpi-calc.ps1 - deterministic KPI calculation (same input => same numbers)
# Usage: .\kpi-calc.ps1 -Level pi -Id 2026.25   |   .\kpi-calc.ps1 -Level sprint -Id 26/19
# Needs env JIRA_PERSONAL_TOKEN (exported from .env by the user). Read-only.
param([ValidateSet('pi','sprint')][string]$Level='pi',[Parameter(Mandatory)][string]$Id)
$ErrorActionPreference='Stop'
$PX='http://http-proxy.porsche.org:3133'; $B='https://api.skyway.porsche.com/jira'; $BOARD=114224
$H=@{Authorization="Bearer $env:JIRA_PERSONAL_TOKEN"}
$IC=[Globalization.CultureInfo]::InvariantCulture
$OUT=Join-Path $PSScriptRoot 'out'; if(-not(Test-Path $OUT)){New-Item -ItemType Directory $OUT|Out-Null}
$CAP=@{}; $cf=Join-Path $PSScriptRoot 'capacity.json'; if(Test-Path $cf){ (Get-Content $cf -Raw|ConvertFrom-Json).PSObject.Properties|%{$CAP[$_.Name]=[double]$_.Value} }

function Api($p){ Invoke-RestMethod "$B$p" -Proxy $PX -Headers $H -TimeoutSec 120 }
function T($s){ [datetimeoffset]::Parse(($s -replace '([+-]\d\d)(\d\d)$','$1:$2'),$IC) }
function Num($s){ if([string]::IsNullOrWhiteSpace("$s")){return 0.0}; [double]::Parse(("$s" -replace ',','.'),$IC) }
function Ids($s){ if(-not $s){return @()}; @("$s" -split ',\s*'|?{$_}) }
function Search($jql,$fields){
 $all=@();$start=0
 do{ $body=@{jql=$jql;fields=$fields;expand=@('changelog');startAt=$start;maxResults=100}|ConvertTo-Json
  $r=Invoke-RestMethod "$B/rest/api/2/search" -Method Post -Proxy $PX -Headers $H -ContentType 'application/json' -Body $body -TimeoutSec 300
  $all+=@($r.issues); $start+=@($r.issues).Count }while($start -lt $r.total -and @($r.issues).Count -gt 0)
 $all|Sort-Object key }
function Prep($is){
 $f=$is.fields; $ev=@()
 foreach($h in @($is.changelog.histories)){ $t=T $h.created; foreach($it in @($h.items)){ $ev+=[pscustomobject]@{t=$t;fld=$it.field;fr=$it.from;to=$it.to;frs=$it.fromString;tos=$it.toString} } }
 $cur=@(); foreach($s in @($f.customfield_10004)){ $m=[regex]::Match("$s",'\bid=(\d+)'); if($m.Success){$cur+=$m.Groups[1].Value} }
 [pscustomobject]@{key=$is.key;title="$($f.summary)";type=$f.issuetype.name;status=$f.status.name;cat=$f.status.statusCategory.key;created=(T $f.created);osp=(Num $f.customfield_10500);sp=(Num $f.customfield_10006);ev=@($ev|Sort-Object t);cur=$cur}
}
function Elig($i){ $i.type -ne 'Sub-task' -and $i.status -notlike 'Wont*' }
function SprintsAt($i,$t){
 if($t -lt $i.created){return @()}
 $se=@($i.ev|?{$_.fld -eq 'Sprint'}); if($se.Count -eq 0){return $i.cur}
 $set=Ids $se[0].fr
 foreach($e in $se){ if($e.t -le $t){$set=Ids $e.to}else{break} }
 $set }
function FirstAssign($i,$ids){
 $se=@($i.ev|?{$_.fld -eq 'Sprint'})
 if($se.Count -eq 0){ if(@($i.cur|?{$ids -contains $_}).Count){return $i.created}else{return $null} }
 if(@(Ids $se[0].fr|?{$ids -contains $_}).Count){return $i.created}
 foreach($e in $se){ if(@(Ids $e.to|?{$ids -contains $_}).Count -gt 0 -and @(Ids $e.fr|?{$ids -contains $_}).Count -eq 0){return $e.t} }
 $null }
function FirstStatus($i,$name,$after){ foreach($e in $i.ev){ if($e.fld -eq 'status' -and $e.tos -eq $name -and ((-not $after) -or $e.t -ge $after)){return $e.t} }; $null }
function WD($a,$b){ if($b -le $a){return 0.0}; $t=0.0;$d=$a
 while($d -lt $b){ $n=[datetimeoffset]::new($d.Date.AddDays(1),$d.Offset); if($n -gt $b){$n=$b}
  if($d.DayOfWeek -ne 'Saturday' -and $d.DayOfWeek -ne 'Sunday'){$t+=($n-$d).TotalDays}; $d=$n }
 $t }
function TT($rows,$prop){ @($rows|group type|Sort-Object Name|%{ $g=@($_.Group); "$($_.Name) $(@($g|?{$_.$prop}).Count)/$($g.Count)" }) -join ', ' }
function Avg($a){ $a=@($a); if($a.Count -eq 0){return $null}; ($a|Measure-Object -Average).Average }
function Sum($a){ $a=@($a); if($a.Count -eq 0){return 0}; ($a|Measure-Object -Sum).Sum }
function F($x,$d=1){ if($null -eq $x){return 'n/a'}; ([math]::Round([double]$x,$d,[MidpointRounding]::AwayFromZero)).ToString("F$d",$IC).Replace('.',',') }
function JD($t){ $t.ToString('yyyy/MM/dd HH:mm',$IC) }

# ---- sprints / PI map ----
$all=@();$st=0; do{ $r=Api "/rest/agile/1.0/board/$BOARD/sprint?startAt=$st&maxResults=50"; $all+=@($r.values); $st+=@($r.values).Count }while(-not $r.isLast)
$SP=@(); foreach($s in $all){ if($s.startDate){ $m=[regex]::Match($s.name,'(\d{4}\.\d+)'); $lk=[regex]::Match($s.name,'^(\d\d/\d+)\b'); $SP+=[pscustomobject]@{id="$($s.id)";name=$s.name;key=$(if($lk.Success){$lk.Groups[1].Value}else{$s.name});pi=$(if($m.Success){$m.Groups[1].Value}else{$null});start=(T $s.startDate);state=$s.state;sid=$s.id} } }
$SP=@($SP|Sort-Object start)
function NextStart($s){ $ix=[array]::IndexOf($SP,$s); if($ix+1 -lt $SP.Count){$SP[$ix+1].start}else{$null} }
function ActDate($s){ $a=(Api "/rest/agile/1.0/sprint/$($s.id)").activatedDate; if($a){T $a}else{$s.start} }
$FIELDS=@('summary','issuetype','status','created','customfield_10004','customfield_10500')

function SprintKpi($s){
 $start=$s.start; $end=NextStart $s; $act=ActDate $s; $running=($s.state -ne 'closed')
 if(-not $end){ $end=[datetimeoffset]::Now }
 $jql="project = ASNAST AND issuetype != Sub-task AND (sprint = $($s.id) OR status changed to `"Technical Review`" during (`"$(JD $start.AddDays(-1))`",`"$(JD $end.AddDays(1))`"))"
 $iss=@(Search $jql $FIELDS|%{Prep $_}|?{(Elig $_) -and $_.osp -gt 0})
 $rows=@(); foreach($i in $iss){
  $tr=FirstStatus $i 'Technical Review' $null; $inWin=($tr -and $tr -ge $start -and $tr -lt $end)
  $rows+=[pscustomobject]@{key=$i.key;title=$i.title;type=$i.type;osp=$i.osp;sp=$i.osp;spAct=$i.osp;maxsp=$i.osp;planned=(@(SprintsAt $i $act)-contains $s.id);added=$false;deliv=[bool]$inWin;left=$false;fa=(FirstAssign $i @($s.id));atEnd=(@(SprintsAt $i $end)-contains $s.id);trAny=$tr} }
 $rows=@($rows|?{-not ($_.trAny -and $_.trAny -lt $start)})
 foreach($r in $rows){ $r.added=((-not $r.planned) -and $r.fa -and $r.fa -gt $act); $r.left=((-not $running) -and $r.atEnd -and -not ($r.trAny -and $r.trAny -le $end)) }
 $d=@($rows|?{$_.deliv}); $p=@($rows|?{$_.planned}); $a=@($rows|?{$_.added}); $l=@($rows|?{$_.left})
 $cap=$CAP[$s.key]; $dsp=Sum ($d|%{$_.sp}); $com=Sum ($p|%{$_.spAct})
 [pscustomobject]@{sprint=$s.key;name=$s.name;state=$s.state;start=$start;activated=$act;end=$end
  deliveredTickets=$d.Count;deliveredSP=$dsp;deliveredByType=@($d|group type|Sort-Object Name|%{"$($_.Name) $($_.Count)"})
  committedSP=$com;plannedTickets=$p.Count;plannedTR=@($p|?{$_.deliv}).Count;plannedTypes=(TT $p 'deliv');addedTRTypes=(TT $a 'deliv');addedTRSP=(Sum ($a|?{$_.deliv}|%{$_.sp}));plannedTRSP=(Sum ($p|?{$_.deliv}|%{$_.sp}));otherTickets=@($rows|?{$_.deliv -and -not $_.planned -and -not $_.added}).Count;otherSP=(Sum ($rows|?{$_.deliv -and -not $_.planned -and -not $_.added}|%{$_.sp}))
  addedTickets=$a.Count;addedSP=(Sum ($a|%{$_.maxsp}));addedTR=@($a|?{$_.deliv}).Count;addedTypes=@($a|group type|Sort-Object Name|%{"$($_.Name) $($_.Count)"})
  leftTickets=$(if($running){$null}else{$l.Count});leftSP=$(if($running){$null}else{Sum ($l|%{$_.maxsp})});leftTypes=@($l|group type|Sort-Object Name|%{"$($_.Name) $($_.Count)"})
  addedList=@($a|Sort-Object key|%{[ordered]@{key=$_.key;title=$_.title;sp=$_.maxsp}});leftList=$(if($running){$null}else{@($l|Sort-Object key|%{[ordered]@{key=$_.key;title=$_.title;sp=$_.maxsp}})})
  capacity=$cap;planList=@($p|%{"$($_.key)/$($_.type)/$($_.spAct)/o$($_.osp)/b$($_.sp)"});velocity=$(if($cap){$dsp/$cap}else{$null});ratio=$(if($com -gt 0){$dsp/$com}else{$null})} }

# ---- HTML helpers ----
$logoFile=Join-Path (Join-Path $PSScriptRoot 'assets') 'logo.jpg'
$logoUri=$(if(Test-Path $logoFile){"data:image/jpeg;base64,$([Convert]::ToBase64String([IO.File]::ReadAllBytes($logoFile)))"}else{''})

if($Level -eq 'sprint'){
 $s=@($SP|?{$_.key -eq $Id})[0]; if(-not $s){throw "Sprint $Id not found"}
 $k=SprintKpi $s
 $k|ConvertTo-Json -Depth 5|Set-Content (Join-Path $OUT "sprint-$($Id -replace '/','-').json") -Encoding UTF8
 $na={ param($v,$d=0) if($null -eq $v -or "$v" -eq ''){'n/a'}else{F $v $d} }
 $pct={ param($a,$b) if($b){[int][math]::Round(100*$a/$b)}else{0} }
 $ty={ param($v) $x=(@($v)|?{$_}) -join ', '; if($x){$x}else{'–'} }
 $ratioBadge=''; $ratioBar=0; $ratioTxt='n/a'
 if($null -ne $k.ratio){ $delta=[int][math]::Round(($k.ratio-1)*100); $ok=($k.ratio -ge 1)
  $ratioBadge="<span class=`"badge $(if($ok){'good'}else{'warn'})`">$(if($delta -ge 0){'+'})$delta %</span>"
  $ratioBar=[math]::Min(100,[int][math]::Round($k.ratio*100)); $ratioTxt=$(if($ok){'Commitment met'}else{'Commitment not met'}) }
 $tl={ param($items,$none) $items=@($items); if($items.Count -eq 0){ return "<ul class=`"tlist`"><li>$none</li></ul>" }
  '<ul class="tlist">'+((@($items|%{ $t="$($_.title)"; if($t.Length -gt 60){$t=$t.Substring(0,57).TrimEnd()+'...'}
   '<li><a href="https://skyway.porsche.com/jira/browse/'+$_.key+'" target="_blank" rel="noopener">'+$_.key+'</a> '+[Net.WebUtility]::HtmlEncode($t)+' <span class="sp">'+(F $_.sp 0)+' SP</span></li>' }) -join ''))+'</ul>' }
 $leftList=$(if($null -eq $k.leftList){'<ul class="tlist"><li>Available after sprint end.</li></ul>'}else{& $tl $k.leftList 'None.'})
 $addList=& $tl $k.addedList 'None.'
 $leftBadge=$(if($null -eq $k.leftTickets){'<span class="badge warn">sprint running</span>'}else{'<span class="badge warn">open</span>'})
 $logoUri=$(if(Test-Path $logoFile){"data:image/jpeg;base64,$([Convert]::ToBase64String([IO.File]::ReadAllBytes($logoFile)))"}else{''})
 $piTag=$(if($k.name -match '\((\d{4}\.\d+)\)'){"PI $($Matches[1])"}else{'PI n/a'})
 $spName=($k.name -replace '^\d\d/\d+\s*(\(\d{4}\.\d+\))?\s*','')
 $stateTxt=$(if($k.state -eq 'closed'){'Closed'}elseif($k.state -eq 'active'){'Running'}else{"$($k.state)"})
 $map=[ordered]@{
  SPRINT=$Id;PI=$piTag;SPNAME=$spName;RANGE="$($k.start.ToString('dd.MM.yyyy')) – $($k.end.ToString('dd.MM.yyyy'))";STATE=$stateTxt;LOGO=$logoUri;DATE=(Get-Date).ToString('yyyy-MM-dd')
  DEL_SP=$k.deliveredSP;DEL_T=$k.deliveredTickets;DEL_TYPES=(& $ty $k.deliveredByType)
  VELOCITY=(& $na $k.velocity 2);CAPACITY=(& $na $k.capacity 1)
  RATIO=(& $na $k.ratio 2);RATIO_BADGE=$ratioBadge;RATIO_BAR=$ratioBar;RATIO_TEXT=$ratioTxt;COMMITTED=$k.committedSP
  LEFT_LIST=$leftList;ADD_LIST=$addList;LEFT_T=(& $na $k.leftTickets 0);LEFT_BADGE=$leftBadge;LEFT_SP=(& $na $k.leftSP 0);LEFT_TYPES=(& $ty $k.leftTypes)
  ADD_T=$k.addedTickets;ADD_SP=(F $k.addedSP 0);ADD_TYPES=(& $ty $k.addedTypes)
  PLAN_TR=$k.plannedTR;PLAN_N=$k.plannedTickets;PLAN_TYPES=$k.plannedTypes;PLAN_SP=(F $k.plannedTRSP 0);PLAN_PCT=(& $pct $k.plannedTR $k.plannedTickets)
  ADD_TR=$k.addedTR;ADD_N=$k.addedTickets;ADD_TYPES2=$k.addedTRTypes;ADD_TRSP=(F $k.addedTRSP 0);ADD_PCT=(& $pct $k.addedTR $k.addedTickets);OTH_N=$k.otherTickets;OTH_SP=(F $k.otherSP 0) }
 $hs=@{}; Get-Content (Join-Path (Join-Path $PSScriptRoot 'design-final') 'hashes.txt')|%{ $p=$_ -split '=',2; $hs[$p[0]]=$p[1] }
 if((Get-FileHash (Join-Path $PSScriptRoot 'sprint-template.html') -Algorithm SHA256).Hash -ne $hs['template'] -or (Get-FileHash $logoFile -Algorithm SHA256).Hash -ne $hs['logo']){ throw "Sprint design changed: sprint-template.html / assets\logo.jpg differ from the approved design in design-final\. Restore from design-final\*.FINAL.* or, if the change is intended, update design-final\hashes.txt." }
 $html=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'sprint-template.html'),[Text.Encoding]::UTF8)
 foreach($key in $map.Keys){ $html=$html.Replace("{{$key}}","$($map[$key])") }
 if($html -match '\{\{\w+\}\}'){ throw "Unreplaced placeholder in template: $($Matches[0])" }
 [IO.File]::WriteAllText((Join-Path $OUT "sprint-$($Id -replace '/','-').html"),$html,(New-Object Text.UTF8Encoding $true))
 $k|Format-List|Out-String; return }

# ---- PI level ----
$PIN="PI $Id"; $ps=@($SP|?{$_.pi -eq $Id}); if(-not $ps.Count){throw "PI $Id not found"}
$ids=@($ps|%{$_.id}); $piStart=$ps[0].start; $piEnd=NextStart $ps[-1]; $cut=$piStart.AddDays(3)
$later=@{}; foreach($s in $SP){ if($s.pi -and [version]$s.pi -gt [version]$Id){$later[$s.id]=$true} }
$res=[ordered]@{pi=$Id;start=$piStart;end=$piEnd;cutoff=$cut;sprints=@($ps|%{$_.key})}

# KPI 1 features (Program Increment field)
$fa=@(Search 'project = ASDM AND issuetype = Feature' @('summary','status','created','customfield_17300'))
$pimap=@{}; foreach($x in $fa){ foreach($h2 in @($x.changelog.histories)){ foreach($it in @($h2.items)){ if($it.field -eq 'Program Increment' -and "$($it.to)" -match '^\[(\d+)\]$'){ $pimap[$it.toString]=$Matches[1] } } } }
$piId=$pimap[$PIN]; if(-not $piId){throw "Program Increment id for $PIN not found"}
$feat=@($fa|%{ $p=Prep $_; [pscustomobject]@{p=$p;pis=@($_.fields.customfield_17300|%{"$_"});sum=$_.fields.summary} }|?{$_.pis -contains $piId})
$fk=@();$fo=@()
foreach($f in $feat){ $im=FirstStatus $f.p 'Implementation' $null; $dn=$null; if($im){$dn=FirstStatus $f.p 'Done' $im}
 if($im -and $dn){ $unc=@(); if($im.ToString('yyyy-MM-dd HH') -eq '2026-03-03 14'){$unc+='Implementation start = bulk migration'}
  $fk+=[pscustomobject]@{key=$f.p.key;days=($dn-$im).TotalDays;pis=($f.pis -join ', ');unc=($unc -join '; ')} }
 else{ $fo+=[pscustomobject]@{key=$f.p.key;status=$f.p.status;pis=($f.pis -join ', ')} } }
$res.kpi1=[ordered]@{avgDays=(Avg ($fk|%{$_.days}));n=$fk.Count;features=$feat.Count;computed=@($fk|Sort-Object key);notComputable=@($fo|Sort-Object key);outliers=@($fk|Sort-Object days -Descending|select -First 3)}

# PI ticket universe
$all=@(Search ('project = ASNAST AND sprint in (' + ($ids -join ',') + ')') $FIELDS|%{Prep $_}|?{Elig $_})
$stories=@($all|?{$_.type -eq 'Story'})
# KPI 2
$bu=@($stories|?{$_.cat -eq 'done'}|%{$_.osp}|?{$_ -gt 0})
$res.kpi2=[ordered]@{avgSP=(Avg $bu);n=$bu.Count}
# KPI 3
$res.kpi3=[ordered]@{total=$all.Count;byType=@($all|group type|Sort-Object Name|%{[ordered]@{type=$_.Name;n=$_.Count;pct=($_.Count/$all.Count*100)}})}
# KPI 4
$ct=@(); foreach($i in $stories){ $rf=FirstStatus $i 'Ready for Dev' $null; if(-not $rf){continue}; $tr=FirstStatus $i 'Technical Review' $rf; if(-not $tr){continue}
 $ip=FirstStatus $i 'In Progress' $rf; $tot=WD $rf $tr; $w=$null;$k2=$null; if($ip -and $ip -le $tr){$w=WD $rf $ip;$k2=$tot-$w}
 $ct+=[pscustomobject]@{key=$i.key;tot=$tot;wait=$w;work=$k2} }
$res.kpi4=[ordered]@{n=$ct.Count;avgTotal=(Avg ($ct|%{$_.tot}));avgWait=(Avg ($ct|?{$null -ne $_.wait}|%{$_.wait}));avgWork=(Avg ($ct|?{$null -ne $_.work}|%{$_.work}));outliers=@($ct|Sort-Object tot -Descending|select -First 5)}
# KPI 5
$add=@();$pull=@()
foreach($i in @($all|?{$_.type -in 'Story','Bug'})){ $fa=FirstAssign $i $ids; if(-not $fa -or $fa -le $cut){continue}
 $isPull=$false; $se=@($i.ev|?{$_.fld -eq 'Sprint' -and $_.t -eq $fa}); if($se.Count){ $isPull=(@(Ids $se[0].fr|?{$later[$_]}).Count -gt 0) }
 $o=[pscustomobject]@{key=$i.key;type=$i.type;sp=$i.osp}; if($isPull){$pull+=$o}else{$add+=$o} }
$res.kpi5=[ordered]@{addedStories=@($add|?{$_.type -eq 'Story'}).Count;addedStorySP=(Sum ($add|?{$_.type -eq 'Story'}|%{$_.sp}));addedBugs=@($add|?{$_.type -eq 'Bug'}).Count;pulledStories=@($pull|?{$_.type -eq 'Story'}).Count;pulledStorySP=(Sum ($pull|?{$_.type -eq 'Story'}|%{$_.sp}));pulledBugs=@($pull|?{$_.type -eq 'Bug'}).Count}
# KPI 6
$sp0=@($all|?{$_.osp -gt 0}); $r6=@()
foreach($i in $sp0){ $fa=FirstAssign $i $ids; if(-not $fa){continue}; $tr=FirstStatus $i 'Technical Review' $null; if($tr -and $tr -lt $piStart){continue}
 $r6+=[pscustomobject]@{type=$i.type;sp=$i.osp;burned=$i.osp;maxsp=$i.osp;planned=($fa -le $cut);tr=[bool]($tr -and $tr -ge $piStart -and $tr -lt $piEnd);left=((@(SprintsAt $i $piEnd|?{$ids -contains $_}).Count -gt 0) -and -not ($tr -and $tr -le $piEnd))} }
 $pl=@($r6|?{$_.planned}); $ad=@($r6|?{-not $_.planned}); $dl=@($r6|?{$_.tr}); $lf=@($r6|?{$_.left})
 $res.overview=[ordered]@{deliveredTickets=$dl.Count;deliveredSP=(Sum ($dl|%{$_.burned}));deliveredTypes=@($dl|group type|Sort-Object Name|%{"$($_.Name) $($_.Count)"}) -join ', ';leftTickets=$lf.Count;leftSP=(Sum ($lf|%{$_.maxsp}));leftTypes=@($lf|group type|Sort-Object Name|%{"$($_.Name) $($_.Count)"}) -join ', ';addedTickets=$ad.Count;addedSP=(Sum ($ad|%{$_.maxsp}));addedTypes=@($ad|group type|Sort-Object Name|%{"$($_.Name) $($_.Count)"}) -join ', '}
$res.kpi6=[ordered]@{planned=$pl.Count;plannedTypes=(TT $pl 'tr');addedTypes=(TT $ad 'tr');plannedSP=(Sum ($pl|%{$_.sp}));plannedTR=@($pl|?{$_.tr}).Count;plannedTRSP=(Sum ($pl|?{$_.tr}|%{$_.sp}));added=$ad.Count;addedSP=(Sum ($ad|%{$_.sp}));addedTR=@($ad|?{$_.tr}).Count;addedTRSP=(Sum ($ad|?{$_.tr}|%{$_.sp}))}
# KPI 7 per sprint
$sk=@($ps|%{SprintKpi $_})
$res.kpi7=@($sk|%{[ordered]@{sprint=$_.sprint;technicalReview=$_.deliveredTickets;leftOver=$_.leftTickets;deliveredSP=$_.deliveredSP;committedSP=$_.committedSP}})
([pscustomobject]$res)|ConvertTo-Json -Depth 6|Set-Content (Join-Path $OUT "pi-$Id.json") -Encoding UTF8

# ---- PI HTML (template-based) ----
$k1=$res.kpi1;$k2=$res.kpi2;$k3=$res.kpi3;$k4=$res.kpi4;$k5=$res.kpi5;$k6=$res.kpi6;$ov=$res.overview
$jb='https://skyway.porsche.com/jira/browse/'
function TopRows($items,$keyProp,$valProp,$unit){ $mxv=[math]::Max(0.0001,(@($items|%{[double]$_.$valProp})|Measure-Object -Maximum).Maximum); $i=0
 (@($items|%{ $i++; $w=[math]::Round(100*[double]$_.$valProp/$mxv,1).ToString([Globalization.CultureInfo]::InvariantCulture); "<li><span class=`"rank`">$i</span><a href=`"$jb$($_.$keyProp)`" target=`"_blank`" rel=`"noopener`">$($_.$keyProp)</a><span class=`"track`"><i style=`"width:$w%`"></i></span><span class=`"num`">$(F $_.$valProp 1)$(if($unit){" <small>$unit</small>"})</span></li>" }) -join '') }
$inv=[Globalization.CultureInfo]::InvariantCulture
$n=$res.kpi7.Count; $mxc=[math]::Max(1,(@($res.kpi7|%{$_.technicalReview;$_.leftOver})|?{$null -ne $_}|Measure-Object -Maximum).Maximum); $sc=238/$mxc
function CX($ix){ if($n -le 1){500}else{ 100+$ix*(800/($n-1)) } }
$chart=''; foreach($yy in 42,112,182,252){ $chart+="<line class=`"grid-line`" x1=`"40`" x2=`"960`" y1=`"$yy`" y2=`"$yy`"/>" }
$chart+='<line class="axis" x1="40" x2="960" y1="280" y2="280"/>'
$pb='';$pr='';$db='';$dr='';$tb='';$trr='';$xl=''
for($x=0;$x -lt $n;$x++){ $q=$res.kpi7[$x]; $cx=[math]::Round((CX $x),1).ToString($inv); $yb=[math]::Round(280-$sc*$q.technicalReview,1)
 $pb+="$cx,$($yb.ToString($inv)) "; $db+="<circle class=`"dot black`" cx=`"$cx`" cy=`"$($yb.ToString($inv))`" r=`"6`"/>"; $tb+="<text class=`"v black`" x=`"$cx`" y=`"$(($yb-18).ToString($inv))`">$($q.technicalReview)</text>"
 if($null -ne $q.leftOver){ $yr=[math]::Round(280-$sc*$q.leftOver,1); $pr+="$cx,$($yr.ToString($inv)) "; $dr+="<circle class=`"dot red`" cx=`"$cx`" cy=`"$($yr.ToString($inv))`" r=`"6`"/>"; $trr+="<text class=`"v red`" x=`"$cx`" y=`"$(($yr-16).ToString($inv))`">$($q.leftOver)</text>" }
 $xl+="<text class=`"x`" x=`"$cx`" y=`"318`">$(($q.sprint -replace '^PI [\d.]+ - ',''))</text>" }
$chart+="<polyline class=`"line black`" points=`"$($pb.Trim())`"/><polyline class=`"line red`" points=`"$($pr.Trim())`"/>$db$dr$tb$trr$xl"
$sprNames=@($res.sprints|%{ $_ -replace '^PI [\d.]+ - ','' }); $sprTxt=$(if($sprNames.Count -gt 2){ ($sprNames[0..($sprNames.Count-2)] -join ', ')+' – '+$sprNames[-1] }else{ $sprNames -join ', ' })
$tot=[double]$k4.avgTotal; $wp=$(if($tot){[math]::Round(100*$k4.avgWait/$tot,1)}else{0}); $wkp=[math]::Round(100-$wp,1)
$pmap=[ordered]@{
 PI=$Id;SPRINTS=$sprTxt;RANGE="$($piStart.ToString('dd.MM.yyyy')) – $($piEnd.ToString('dd.MM.yyyy'))";LOGO=$logoUri;DATE=(Get-Date).ToString('yyyy-MM-dd')
 OV_DEL_T=$ov.deliveredTickets;OV_DEL_SP=(F $ov.deliveredSP 0);OV_DEL_TYPES=$ov.deliveredTypes
 OV_LEFT_T=$ov.leftTickets;OV_LEFT_SP=(F $ov.leftSP 0);OV_LEFT_TYPES=$ov.leftTypes
 OV_ADD_T=$ov.addedTickets;OV_ADD_SP=(F $ov.addedSP 0);OV_ADD_TYPES=$ov.addedTypes
 K1_AVG=(F $k1.avgDays 1);K1_N=$k1.n;K1_FEAT=$k1.features;FEAT_TOP=(TopRows $k1.outliers 'key' 'days' 'd')
 K2_AVG=(F $k2.avgSP 2);K2_N=$k2.n
 K4_TOTAL=(F $k4.avgTotal 1);K4_N=$k4.n;K4_WAIT=(F $k4.avgWait 1);K4_WORK=(F $k4.avgWork 1);K4_WAITPCT=$wp.ToString($inv);K4_WORKPCT=$wkp.ToString($inv);STORY_TOP=(TopRows $k4.outliers 'key' 'tot' '')
 K3_TOTAL=$k3.total;K3_TYPES=(($k3.byType|%{"$($_.type) $($_.n) ($(F $_.pct 1)%)"}) -join ' · ')
 K5_STORIES=$k5.addedStories;K5_SP=(F $k5.addedStorySP 0);K5_BUGS=$k5.addedBugs;K5_PULLED=$k5.pulledStories;K5_PULLEDSP=(F $k5.pulledStorySP 0)
 K6_PTR=$k6.plannedTR;K6_P=$k6.planned;K6_PTRSP=(F $k6.plannedTRSP 0);K6_PSP=(F $k6.plannedSP 0);K6_ATR=$k6.addedTR;K6_A=$k6.added;K6_ATRSP=(F $k6.addedTRSP 0);K6_ASP=(F $k6.addedSP 0)
 CHART=$chart }
$hs=@{}; Get-Content (Join-Path (Join-Path $PSScriptRoot 'design-final') 'hashes.txt')|%{ $p=$_ -split '=',2; $hs[$p[0]]=$p[1] }
if((Get-FileHash (Join-Path $PSScriptRoot 'pi-template.html') -Algorithm SHA256).Hash -ne $hs['pitemplate'] -or (Get-FileHash $logoFile -Algorithm SHA256).Hash -ne $hs['logo']){ throw "PI design changed: pi-template.html / assets\logo.jpg differ from the approved design in design-final\. Restore from design-final\*.FINAL.* or update design-final\hashes.txt." }
$html=[IO.File]::ReadAllText((Join-Path $PSScriptRoot 'pi-template.html'),[Text.Encoding]::UTF8)
foreach($key in $pmap.Keys){ $html=$html.Replace("{{$key}}","$($pmap[$key])") }
if($html -match '\{\{\w+\}\}'){ throw "Unreplaced placeholder in PI template: $($Matches[0])" }
[IO.File]::WriteAllText((Join-Path $OUT "pi-$Id.html"),$html,(New-Object Text.UTF8Encoding $true))
([pscustomobject]$res)|ConvertTo-Json -Depth 6
