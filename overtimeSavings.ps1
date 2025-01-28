# ======================================================================
# ������`
# ======================================================================
# CSV�t�@�C���̃p�X�������Ƃ��Ď󂯎��
param (
  [string]$CsvFilePath
)

# ======================================================================
# �֐���`
# ======================================================================
# datetime�^��hh:mm�`���̕�����ɕϊ�
function Convert-TimeSpanToHoursMinutes {
  param (
    [TimeSpan]$timeSpan
  )
  $totalMinutes = [math]::Floor($timeSpan.TotalMinutes)
  $hours = [math]::Floor($totalMinutes / 60)
  $minutes = $totalMinutes % 60
  return "{0}:{1:00}" -f $hours, $minutes
}

# hh:mm�`���𕪒P�ʂɕϊ�
function ConvertToMinutes {
  param (
    [string]$time
  )
  $parts = $time -split ":"
  $hours = [int]$parts[0]
  $minutes = [int]$parts[1]
  return ($hours * 60) + $minutes
}

# ���P�ʂ�hh:mm�`���ɕϊ�
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
# �ϐ���`
# ======================================================================
# CSV�t�@�C����ǂݍ���
$csv = Import-Csv -Path $CsvFilePath

# �c�Ɠ������J�E���g
# debug: �x���o�΂�����@�\���Ȃ��Ȃ�̂ł��̏������������I
$businessDays = $csv | Where-Object { $_."�x���敪" -notmatch "���x|�@�x|�j��" } | Measure-Object | Select-Object -ExpandProperty Count

# �Œ�ғ����Ԃ��v�Z
$minWorkHours = $businessDays * 8

# �Œ�ғ����Ԃ�hh:mm�`���ɕϊ�
$minWorkTimeFormatted = "{0}:{1:00}" -f $minWorkHours, 0

# �������t���擾��������ɕϊ�
$todayDate = (Get-Date).ToString("yyyy/M/dd")

# �ғ����Ԍ����ݏ�����
$totalWorkMinutes = New-TimeSpan -Hours 0 -Minutes 0

# ======================================================================
# �又��
# ======================================================================

foreach ($row in $csv) {
  # ������
  $workHours = "0:00"

  # ���x�A�@�x�A�j���̏ꍇ�X�L�b�v
  # debug: �x���o�΂�����@�\���Ȃ��Ȃ�̂ł��̏������������I
  if ($row."�x���敪" -match "���x|�@�x|�j��") {
    continue
  }

  # �ғ����Ԃ̑��
  if ($row."���t" -eq ${todayDate}) {
    # �������t�̏ꍇ�͌����݂�8h���
    $workHours = "08:00"
  }
  else {
    # �J�����Ԃ����B��̏ꍇ�͌����݂�8h����
    $workHours = if ($row."�J������" -eq "") { "08:00" } else { $row."�J������" }
  }

  # �ғ����Ԃ𕶎��񂩂�datetime�^�ɕϊ�
  $parseWorkHours = [datetime]::ParseExact($workHours, "HH:mm", $null).TimeOfDay
  # �ғ����ԉ��Z
  $totalWorkMinutes = $totalWorkMinutes.Add($parseWorkHours)
}

# �ғ����Ԍ����݂�hh:mm�`���ɕϊ�
$totalWorkTimeFormatted = Convert-TimeSpanToHoursMinutes -timeSpan $totalWorkMinutes

# �Œ�ғ����Ԃ𕪒P�ʂɕϊ�
$minWorkTimeToMinutes = ConvertToMinutes -time $minWorkTimeFormatted

# �ғ����Ԍ����݂𕪒P�ʂɕϊ�
$totalWorkTimeToMinutes = ConvertToMinutes -time $totalWorkTimeFormatted

# �c�ƒ������v�Z
$diffMinutes = $totalWorkTimeToMinutes - $minWorkTimeToMinutes

# �c�ƒ�����hh:mm�`���ɕϊ�
$overtimeBank = ConvertToHoursAndMinutes -totalMinutes $diffMinutes

# ======================================================================
# �o��
# ======================================================================
Write-Output "�����̉c�Ɠ���: ${businessDays}��"
Write-Output "�����̍Œ�ғ�����: ${minWorkTimeFormatted}"
Write-Output "�����̉ғ����Ԍ�����: ${totalWorkTimeFormatted}"
Write-Output "�����̎c�ƒ���: ${overtimeBank}"
