REM ログファイルのパスを指定
set DIR_ROOT=D:\Froebel運用\Send_JOB_Result
set LOG=%DIR_ROOT%\_LOG\_log_JOB_SEND_%date:~0,4%%date:~5,2%.log

REM 開始ログ出力  7 To 9 
echo 開始ログ出力  7 To 9 
echo =========================================================================== >>%LOG%
echo %DATE% %TIME% 処理開始 夜間ジョブログメール送付 7 To 9 >>%LOG%

cd /d %DIR_ROOT%
powershell %DIR_ROOT%\Send_JOB_Result_2.ps1

echo %DATE% %TIME% 処理終了 夜間ジョブログメール送付 7 To 9 >>%LOG%
echo =========================================================================== >>%LOG%
exit
