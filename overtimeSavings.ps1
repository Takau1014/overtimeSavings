# ======================================================================
# 引数定義
# ======================================================================
# CSVファイルのパスを引数として受け取る
param (
  [string]$CsvFilePath
)

# ======================================================================
# 関数定義
# ======================================================================
# datetime型をhh:mm形式の文字列に変換
function Convert-TimeSpanToHoursMinutes {
  param (
    [TimeSpan]$timeSpan
  )
  $totalMinutes = [math]::Floor($timeSpan.TotalMinutes)
  $hours = [math]::Floor($totalMinutes / 60)
  $minutes = $totalMinutes % 60
  return "{0}:{1:00}" -f $hours, $minutes
}

# hh:mm形式を分単位に変換
function ConvertToMinutes {
  param (
    [string]$time
  )
  $parts = $time -split ":"
  $hours = [int]$parts[0]
  $minutes = [int]$parts[1]
  return ($hours * 60) + $minutes
}

# 分単位をhh:mm形式に変換
function ConvertToHoursAndMinutes {
  param (
    [int]$totalMinutes
  )
  $isNegative = $totalMinutes -lt 0
  $totalMinutes = [math]::Abs($totalMinutes)
  $hours = [math]::Floor($totalMinutes / 60)
  $minutes = $totalMinutes % 60
  $result = "{0:00}:{1:00}" -f $hours, $minutes
  if ($isNegative) {
    $result = "-" + $result
  }
  return $result
}

# ======================================================================
# 変数定義
# ======================================================================
# CSVファイルを読み込む
$csv = Import-Csv -Path $CsvFilePath

# 営業日数をカウント
# debug: 休日出勤したら機能しなくなるのでこの条件を見直す！
$businessDays = $csv | Where-Object { $_."休日区分" -notmatch "公休|法休|祝日" } | Measure-Object | Select-Object -ExpandProperty Count

# 最低稼働時間を計算
$minWorkHours = $businessDays * 8

# 最低稼働時間をhh:mm形式に変換
$minWorkTimeFormatted = "{0}:{1:00}" -f $minWorkHours, 0

# 当日日付を取得し文字列に変換
$todayDate = (Get-Date).ToString("yyyy/M/dd")

# 稼働時間見込み初期化
$totalWorkMinutes = New-TimeSpan -Hours 0 -Minutes 0

# ======================================================================
# 主処理
# ======================================================================

foreach ($row in $csv) {
  # 初期化
  $workHours = "0:00"

  # 公休、法休、祝日の場合スキップ
  # debug: 休日出勤したら機能しなくなるのでこの条件を見直す！
  if ($row."休日区分" -match "公休|法休|祝日") {
    continue
  }

  # 稼働時間の代入
  if ($row."日付" -eq ${todayDate}) {
    # 当日日付の場合は見込みで8h代入
    $workHours = "08:00"
  }
  else {
    # 労働時間を代入。空の場合は見込みで8hを代入
    $workHours = if ($row."労働時間" -eq "") { "08:00" } else { $row."労働時間" }
  }

  # 稼働時間を文字列からdatetime型に変換
  $parseWorkHours = [datetime]::ParseExact($workHours, "HH:mm", $null).TimeOfDay
  # 稼働時間加算
  $totalWorkMinutes = $totalWorkMinutes.Add($parseWorkHours)
}

# 稼働時間見込みをhh:mm形式に変換
$totalWorkTimeFormatted = Convert-TimeSpanToHoursMinutes -timeSpan $totalWorkMinutes

# 最低稼働時間を分単位に変換
$minWorkTimeToMinutes = ConvertToMinutes -time $minWorkTimeFormatted

# 稼働時間見込みを分単位に変換
$totalWorkTimeToMinutes = ConvertToMinutes -time $totalWorkTimeFormatted

# 残業貯金を計算
$diffMinutes = $totalWorkTimeToMinutes - $minWorkTimeToMinutes

# 残業貯金をhh:mm形式に変換
$overtimeBank = ConvertToHoursAndMinutes -totalMinutes $diffMinutes

# ======================================================================
# 出力
# ======================================================================
Write-Output "今月の営業日数: ${businessDays}日"
Write-Output "今月の最低稼働時間: ${minWorkTimeFormatted}"
Write-Output "今月の稼働時間見込み: ${totalWorkTimeFormatted}"
Write-Output "今月の残業貯金: ${overtimeBank}"
