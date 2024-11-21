# overtimeSavings
* ジョブカンの勤怠csvから、今月の残業貯金を算出するスクリプト
* 目指せ、残業0時間！(むり)

## EXEC
```PowerShell
.\overtimeSavings.ps1 .\attendance-record-summary-202411211536673ed4dc76d46.csv
```

## MEMO
* 土日・休日出勤に対応できてない
* ソースの最適化が出来てない(関数周りが冗長)
