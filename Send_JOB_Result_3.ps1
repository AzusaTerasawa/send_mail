###-----------------------------------------------------------------------------
###	夜間ジョブのログを自動配信するシェル
###	2017/12/25
###	Memo：Main_Run内で主処理を実装すること
###-----------------------------------------------------------------------------

##	
##	iniファイルの設定
##	
$DIR_INIT  = "D:\Froebel運用\Send_JOB_Result"
$INIT_FILE = "Send_JOB_Result_3.ini"

## iniファイルの内容をハッシュキー化
##$INI_Hash_ALL = @{}

##
##	Iniファイルを読み込んでハッシュとして溜め込む
## 	In:ファイルのパス(ファイル名込み)
## 	Out:Iniのハッシュ項目全て
function read_ini($filename)
{
	$lines = get-content $filename
	$_hash_local = @{}

	foreach($line in $lines)
	{
		# コメント(";")と空行を除外する
		if($line -match "^$"){ continue }
		if($line -match "^\s*;"){ continue }

		$param = $line.split("=",2)
		
		## 内部変数にハッシュキー、値をセット
		$_hash_local.add($param[0], $param[1])
	}
	return $_hash_local
}

##	
##	ファイル読み込み
## 	In:ファイルのパス(ファイル名込み)
## 	Out:ファイルの内容
function read_txt($filename)
{
	$return_value = ""
	try
	{
		$lines = get-content $filename
		foreach($line in $lines)
		{
			$return_value += $line
			if ($return_value.length -ne 0)
			{
				$return_value += "`n"
			}
		}
	}
	catch
	{
		exit -1
	}
	return $return_value
}

##
##	メール送信
##	IN:以下のパラメータ参照
function SendMail(
	[string]$From,		# 送信元アドレス
	        $To,		# 宛先アドレス
	[string]$Subject,	# 件名
	[string]$Body,		# 本文
	[string]$SmtpSrv,	# SMTPサーバ
	[string]$SmtpUser,	# SMTP認証ユーザ
	[string]$SmtpPW,	# SMTP認証パスワード
    [int]$Port,			# ポート
	$attach )			# 添付ファイルのパス（あえて、[string] をつけないことで $null が入るようになる）
{

	$enc = [Text.Encoding]::GetEncoding("csISO2022JP");
	$s64 = [Convert]::ToBase64String($enc.GetBytes($Subject), [Base64FormattingOptions]::None)

	$message = New-Object Net.Mail.MailMessage

    $message.SubjectEncoding = [Text.Encoding]::GetEncoding("ISO-2022-JP")
	$message.Subject = [String]::Format("=?{0}?B?{1}?=", $enc.HeaderName, $s64)
	$view = [Net.Mail.AlternateView]::CreateAlternateViewFromString($Body, $enc, [Net.Mime.MediaTypeNames]::Text.Plain)
	$view.TransferEncoding = [Net.Mime.TransferEncoding]::SevenBit
	$message.AlternateViews.Add($view)

 	# 送信元を登録
	$message.From = $From
	# 複数宛先を登録
	foreach($el in $To)
	{
#		Write-Host ("Elemet is " + $el)
		$message.To.Add($el)
	}

	# 複数添付ファイルを登録(ファイルが見つからない場合は対象ファイルはスキップ)
	foreach($el_attach in $attach)
	{
		try {
			$temp = new-object System.Net.Mail.Attachment($el_attach)
			$message.Attachments.Add($temp)
		} catch {
			Write-Host "エラー有り"
			Write-Error "-----------------------------------------------------------------------------"
			Write-Error("エラー"+$_.Exception)
			Write-Error "-----------------------------------------------------------------------------"
		} finally {
			## 何もしない
		}
	}


	# 送信
	$smtp = new-object System.Net.Mail.SmtpClient($SmtpSrv)
	if ($Port -gt 0)
	{
		$smtp.Port = $Port
	}
	if ($SmtpUser -ne $null -and $SmtpPW -ne $null)
	{
		# SMTP認証設定
		$smtp.Credentials = new-object System.Net.NetworkCredential($SmtpUser, $SmtpPW)
	}
	$smtp.Send($message)

	$message.Dispose()
}
################################################################################

#
#
# メインファンクション
function Main_Run()
{
Write-Host "開始"

	# iniファイル読み込み
	$Ini_Path = $DIR_INIT + "\" + $INIT_FILE
	$INI_ALL = read_ini($Ini_Path)

	# 日付置換フォーマット
	$MM_DD			= Get-Date -Format "MM/dd"
	$YYYYMMDD		= Get-Date -Format "yyyyMMdd"

    ### $mail_body = read_txt $env:FILE_BODY  ### 改行本文の読み込み方　サンプル
	$DIR_ROOT		= $INI_ALL["DIR_ROOT"]
	$CSV_ROOT		= $INI_ALL["DIR_CSV"]
	$CSV_1_FILE		= $CSV_ROOT + "\" + $INI_ALL["CSV_1"]
#	$CSV_2_FILE		= $CSV_ROOT + "\" + $INI_ALL["CSV_2"]
#	$CSV_3_FILE		= $CSV_ROOT + "\" + $INI_ALL["CSV_3"]
	## 添付ファイルを処理日のファイル名に変更
##	iniファイルの設定内容
##	CSV_1=[実施日YYYMMDD](零時～朝方)_夜間JOB(全部)_ログ添付用.zip
##	CSV_2=[実施日YYYMMDD](零時～朝方)_夜間バッチ起動確認結果.csv
##	CSV_3=[実施日YYYMMDD]_支店送信結果.csv
	$CSV_1_FILE		= $CSV_1_FILE.Replace("[実施日YYYYMMDD]", $YYYYMMDD)
#	$CSV_2_FILE		= $CSV_2_FILE.Replace("[実施日YYYYMMDD]", $YYYYMMDD)
#	$CSV_3_FILE		= $CSV_3_FILE.Replace("[実施日YYYYMMDD]", $YYYYMMDD)
#	$ATTACHED_FILE	= @($CSV_1_FILE, $CSV_2_FILE, $CSV_3_FILE)
	$ATTACHED_FILE	= @($CSV_1_FILE)
	
    ## メール設定
	#	件名
    $TITLE_PATH		= $DIR_ROOT + "\" + $INI_ALL["Mail_Title_File"]
	$Title_Read		= read_txt($TITLE_PATH)
	$Title_Read		= $Title_Read.Replace("[実施日MMDD]" , $MM_DD)
    $Title_Read		= $Title_Read.replace("`n", "") #改行コード除去
	#	本文
	$BODY_PATH		= $DIR_ROOT + "\" + $INI_ALL["Mail_Body_File"]
	$Body_Read 		= read_txt($BODY_PATH)
	$Body_Read		= $Body_Read.Replace("[実施日MMDD]" , $MM_DD)
	
	#	SMTP関連
	$Mail_From			= $INI_ALL["Mail_From"]
    $To_Array			= $INI_ALL["Mail_To"]
	$Mail_To			= $To_Array.split(",")
	
	$Mail_Title			= $Title_Read
    $Mail_Body			= $Body_Read
    $Mail_SMTP_SERVER	= $INI_ALL["Mail_SMTP_SERVER"]
    $Mail_User			= $INI_ALL["Mail_User"]
    $Mail_PW			= $INI_ALL["Mail_PW"]
	$Mail_Port			= 25
    $Mail_Attach		= $ATTACHED_FILE

    ## メール送信
    SendMail $Mail_From $Mail_To $Mail_Title $Mail_Body $Mail_SMTP_SERVER $Mail_User $Mail_PW $Mail_Port $Mail_Attach

Write-Host "終了"
}

##
##
## メイン処理実行
Main_Run
