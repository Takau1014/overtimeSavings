# overtimeSavings
* ジョブカンの勤怠csvから、今月の残業貯金を算出するスクリプト
* 目指せ、残業0時間！(むり)

## EXEC

### Linux / Mac
```sh
./overtimeSavings.sh ./attendance-record-summary-XXXXXXXX.csv
```

### Windows（旧版）
```PowerShell
.\overtimeSavings.ps1 .\attendance-record-summary-XXXXXXXX.csv
```

## 出力例
Linux / Mac 版の出力（マークダウンの表。数値は架空）

```md
| 項目 | 値 |
| --- | ---: |
| 営業日数 | 19日 |
| 最低稼働時間 | 152:00 |
| 稼働時間見込み | 160:10 |
| 残業貯金（見込み） | 8:10 |
| 深夜稼働 | 1:00 |
| 休日稼働 | 4:00 |

| 深夜稼働日 | 時間 |
| --- | ---: |
| 11/9 | 1:00 |

⚠ 打刻漏れ: 11/11（出勤）
```

## 計算方法
* 最低稼働時間 = 営業日数（公休・法休・祝日以外）× 8h
* 稼働時間見込み = 各日の労働時間の合計。当日・未来日・労働時間が空の営業日は 8h で見込む
* 休日出勤の労働時間も見込みに加算する（Linux / Mac 版のみ）
* Linux / Mac 版は以下も出力する
  * 深夜稼働の合計と日付
  * 休日稼働の合計
  * 打刻漏れの日（労働時間が空の過去の営業日）

## MEMO
* Windows 版は休日出勤に未対応
