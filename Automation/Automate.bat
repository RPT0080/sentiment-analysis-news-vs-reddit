
@echo off
REM === Activate venv ===
REM Update the path below to your virtual environment activate script
call "<PATH_TO_VENV>\Scripts\activate.bat"

REM === Run Python scripts ===
REM Replace <PYTHON_SCRIPT_DIR> with your scripts folder
python "<PYTHON_SCRIPT_DIR>\newsapi_pull.py" >> runlog.txt 2>&1
python "<PYTHON_SCRIPT_DIR>\reddit_apipull.py" >> runlog.txt 2>&1

REM === Run R script ===
REM Update <RSCRIPT_EXE> to the path of your Rscript.exe
REM Update <R_SCRIPT> to the path of your .R file
"<RSCRIPT_EXE>" "<R_SCRIPT>" >> runlog.txt 2>&1

REM === Done ===
echo ✅ Automation complete!
pause
