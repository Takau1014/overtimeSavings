#!/bin/sh
# ジョブカンの勤怠CSVから、今月の残業貯金を算出する (Linux / macOS)
# 使い方: ./overtimeSavings.sh attendance-record-summary-XXXX.csv
set -eu

if [ $# -ne 1 ] || [ ! -f "$1" ]; then
  echo "使い方: $0 <勤怠CSV>" >&2
  exit 1
fi

# バイト単位で比較させるため C ロケールにする（BOM を除けるように）
LC_ALL=C awk -v today="$(date +%Y/%m/%d)" '
  function fail(msg) { print "エラー: " msg > "/dev/stderr"; failed = 1; exit 1 }
  function hhmm(t,  s) { s = t < 0 ? "-" : ""; t = t < 0 ? -t : t; return sprintf("%s%d:%02d", s, int(t / 60), t % 60) }
  # 日付を数値にして比較する（"2026/11/5" と "2026/11/05" を同じ日として扱う）
  function ymd(d,  p) { split(d, p, "/"); return p[1] * 10000 + p[2] * 100 + p[3] }
  # "hh:mm" → 分。空は 0
  function mins(v, name,  t) {
    if (v == "") return 0
    if (v !~ /^[0-9]+:[0-9][0-9]$/) fail(f[D] ": " name "を解釈できません: " v)
    split(v, t, ":"); return t[1] * 60 + t[2]
  }

  {
    if (NR == 1) sub(/^\357\273\277/, "")  # UTF-8 の BOM
    sub(/\r$/, "")
    if ($0 == "") next
    # 日付の列だけ引用符がないので、付けてから "," で分割する（"祝日,公休" のように値にカンマが入るため）
    if ($0 !~ /^"/) { sub(/,"/, "\",\""); $0 = "\"" $0 }
    sub(/^"/, ""); sub(/"$/, "")
    n = split($0, f, "\",\"")
  }

  # 空行を除いた最初の行を見出しとして読む
  !width {
    width = n
    for (i = 1; i <= n; i++) col[f[i]] = i
    if (!("日付" in col) || !("休日区分" in col) || !("労働時間" in col) || !("深夜時間" in col) || !("出勤時刻" in col) || !("退勤時刻" in col)) fail("ジョブカンの勤怠CSVではありません（日付・休日区分・出勤時刻・退勤時刻・労働時間・深夜時間の列がない）")
    D = col["日付"]; H = col["休日区分"]; W = col["労働時間"]; N = col["深夜時間"]; I = col["出勤時刻"]; O = col["退勤時刻"]
    next
  }

  {
    # 途中で切れた行や、値に "," を含んで列がずれた行は、黙って計算せずに止める
    if (n != width) fail(NR "行目: 列の数が見出しと違います（" n "列。見出しは" width "列）")
    date = f[D]; work = f[W]
    if (date !~ /^[0-9]+\/[0-9]+\/[0-9]+$/) fail(NR "行目: 日付を解釈できません: " date)
    worked = mins(work, "労働時間")
    night = mins(f[N], "深夜時間")  # 労働時間に含まれる内数なので、見込みには足さない
    md = substr(date, index(date, "/") + 1)  # 表示用に年を除く
    if (night > 0) { lateNight += night; nightDays = nightDays sprintf("| %s | %s |\n", md, hhmm(night)) }
    past = ymd(date) < ymd(today)

    if (f[H] ~ /公休|法休|祝日/) {
      holidayWork += worked  # 休日出勤はそのまま貯金に加算
      next
    }
    businessDays++
    if (!past) { expected += 480; next }  # 当日・未来日は 8h 働く見込み
    if (work == "") {
      # 打刻漏れは 8h で見込む
      which = (f[I] == "" && f[O] == "") ? "出勤・退勤" : (f[I] == "" ? "出勤" : (f[O] == "" ? "退勤" : "要確認"))
      missing = missing (missing == "" ? "" : ", ") md "（" which "）"
      expected += 480
      next
    }
    expected += worked
  }

  END {
    if (failed) exit 1
    if (businessDays == 0) fail("営業日が1日もありません")
    expected += holidayWork
    required = businessDays * 480
    print "| 項目 | 値 |"
    print "| --- | ---: |"
    print "| 営業日数 | " businessDays "日 |"
    print "| 最低稼働時間 | " hhmm(required) " |"
    print "| 稼働時間見込み | " hhmm(expected) " |"
    print "| 残業貯金（見込み） | " hhmm(expected - required) " |"
    print "| 深夜稼働 | " hhmm(lateNight) " |"
    print "| 休日稼働 | " hhmm(holidayWork) " |"
    if (nightDays != "") printf "\n| 深夜稼働日 | 時間 |\n| --- | ---: |\n%s", nightDays
    if (missing != "") print "\n⚠ 打刻漏れ: " missing
  }
' "$1"
