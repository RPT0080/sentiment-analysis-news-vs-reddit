Sentiment Analysis: News vs Reddit
This project uses Python to collect news headlines (via NewsAPI) and Reddit posts across key social themes and to run sentiment analysis. R was then used for further statistical exploration, and Tableau was used to visualize the results.

This case study asks:

Do Reddit and news sources mirror each other in sentiment trends?

Which themes generate the strongest emotional gaps?

Are spikes in Reddit sentiment leading or lagging the news?

Are extreme or clickbait stories driving stronger engagement?

Do weekday or hourly cycles reveal patterns in sentiment flow?

1. 📌 Project Overview

Automates data pulls from NewsAPI and Reddit API.

Cleans and processes text in R (sentiment scoring, theme mapping, reaction gaps).

Builds interactive Tableau dashboards for exploring:

Average sentiment by theme.

Who leads (News vs Reddit).

Daily posting volume.

Sentiment shifts by weekday.

Clickbait vs non-clickbait differences.

2. 🌍 Themes / Scope

The analysis tracks broad themes to compare coverage across sources:

🧠 Mental Health

🌍 Global Conflict

⚖️ Crime & Justice

🌱 Climate & Environment

💼 Economy & Jobs

🎓 Education & Learning

🌿 Wellness & Growth

🤖 Tech & Innovation

🎭 Culture & Media

Each theme is defined by a set of keywords (see Python/R scripts).

3. ⚙️ Setup Instructions
Python

Requires Python 3.8+

Install dependencies:

pip install -r requirements.txt

Add api keys into scripts NewsAPI Script  Reddit Api Script

R

Install the following packages:

install.packages(c("dplyr", "tidyr", "readr", "stringr"))


Run scripts from /Scripts to process data with python scripts first then R, or using Automate.bat(explained below).

Tableau

Open the workbook: tableau/sentiment_dashboard.twb

Point it to your cleaned_data folder.

📝 Note: If you want to union multiple files (e.g., multiple days of cleaned stats), you can connect Tableau to the entire folder instead of a single CSV. 

4. ▶️ How to Run
Pull data with Python
python src/newsapi_template.py
python src/reddit_template.py

Clean & process with R
source("src/clean_data.R")


Outputs will be saved in /Data/cleaned_data/.

Explore in Tableau

Open sentiment_dashboard.twb.

Refresh the data source → dashboards update automatically.
Option B: Run the automated pipeline


A batch script (Automate.bat) is included in the Automation Folder

Double-clicking Automate.bat will:

Activate your Python environment.

Run the NewsAPI and Reddit API pulls.

Trigger the R cleaning script.

Save cleaned data into /Data/cleaned_data/.

⚠️ Note: You’ll need Python, R, and required libraries installed for this automation to work.
5. 📂 Repo Layout
Sentiment_Analysis/
│
├── Data/
│   ├── raw_data/          # Sample raw inputs (Reddit + NewsAPI)
│   ├── cleaned_data/      # Cleaned data outputs
│   └── outputs/           # Figures, screenshots , Tableau workbok Dashboard.twb
│
├── Scripts/                   # Scripts
│   ├── News_API_Script.py
│   ├── Reddit_APP_Script.py
│   ├── 
│   └── Analysis.R
│
│

6. 📝 Notes & Credits

Data from NewsAPI
 and Reddit API.

.twb workbook is provided (lightweight); .twbx extracts are excluded.
