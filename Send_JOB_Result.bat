REM ���O�t�@�C���̃p�X���w��
set DIR_ROOT=D:\Froebel�^�p\Send_JOB_Result
set LOG=%DIR_ROOT%\_LOG\_log_JOB_SEND_%date:~0,4%%date:~5,2%.log

REM �J�n���O�o��
echo =========================================================================== >>%LOG%
echo %DATE% %TIME% �����J�n ��ԃW���u���O���[�����t�@>>%LOG%

cd /d %DIR_ROOT%
powershell %DIR_ROOT%\Send_JOB_Result.ps1

echo %DATE% %TIME% �����I�� ��ԃW���u���O���[�����t�@>>%LOG%
echo =========================================================================== >>%LOG%
exit
