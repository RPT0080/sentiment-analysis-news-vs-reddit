from vaderSentiment.vaderSentiment import SentimentIntensityAnalyzer
import praw
import pandas as pd
import os
from datetime import datetime

#  Same themes as in NewsAPI script
themes = {
    "mental_health": {
        "query": "mental health OR mindfulness OR coping skills OR anxiety OR therapy OR psychology OR self-help",
        "subs": ["mentalhealth", "anxiety", "psychology", "depression", "BPD", "selfhelp"]
    },
    "global_conflict": {
        "query": "war OR protest OR refugee OR diplomacy OR international relations OR united nations",
        "subs": ["worldnews", "politics", "geopolitics", "collapse", "InternationalRelations"]
    },
    "crime_justice": {
        "query": "crime OR trial OR community safety OR police OR justice OR public safety OR legal reform",
        "subs": ["news", "TrueCrime", "justice", "crime", "Law"]
    },
    "climate": {
        "query": "climate OR wildfire OR climate change OR sustainability OR environment OR conservation OR renewable energy",
        "subs": ["climate", "environment", "sustainability", "collapse", "RenewableEnergy"]
    },
    "economy_jobs": {
        "query": "job search OR unemployment OR hiring OR layoffs OR economic growth OR career OR economy OR inflation OR workforce OR cost of living",
        "subs": ["careerguidance", "jobs", "economy", "recruitinghell", "overemployed"]
    },
    "education_learning": {
        "query": "education OR school OR college OR tuition OR university OR learning OR studying OR degree OR literacy OR higher education",
        "subs": ["education", "college", "AskAcademia", "teachers", "learnprogramming"]
    },
    "wellness_growth": {
        "query": "wellness OR well-being OR self-care OR self improvement OR habits OR journaling OR meditation OR growth mindset OR lifestyle",
        "subs": ["selfimprovement", "GetDisciplined", "meditation", "DecidingToBeBetter", "productivity"]
    },
    "tech_innovation": {
        "query": "innovation OR research OR breakthrough OR GPT-4 OR space OR quantum computing OR AI development OR clean tech OR robotics OR future technology",
        "subs": ["Futurology", "singularity", "machinelearning", "space", "technology"]
    },
    "culture_media": {
        "query": "film OR television OR pop culture OR music OR art OR media OR entertainment OR literature OR fashion OR social media",
        "subs": ["television", "movies", "popculturechat", "Music", "Art", "books", "FashionReps"]
    }
}


# 🗝 Reddit API connection
reddit = praw.Reddit(
    client_id="your_id_here",
    client_secret="your_secret_here",
    user_agent="your_user_agent_here"
)

#  Sentiment analyzer
analyzer = SentimentIntensityAnalyzer()

#  Storage for all results
results = []

#  Loop through each theme
for theme_name, data in themes.items():
    query = data["query"]
    subreddits = data["subs"]

    for sub in subreddits:
        print(f"Pulling from r/{sub} for theme: {theme_name}")
        try:
            for post in reddit.subreddit(sub).search(query, sort='new', time_filter='month', limit=50):
                text = post.title
                score = analyzer.polarity_scores(text)['compound']
                results.append({
                    "theme": theme_name,
                    "subreddit": sub,
                    "title": text,
                    "sentiment": score,
                    "created_utc": post.created_utc,
                    "date": datetime.utcfromtimestamp(post.created_utc).date()
                })
            
        except Exception as e:
             print(f" Skipping r/{sub} due to error: {e}")
             continue

print(f" Finished. Total Reddit posts pulled: {len(results)}")

# 📊 Convert to DataFrame
df_reddit = pd.DataFrame(results)


# still need to adjust both this and news api to save inside new project folder cleaned files
# 💾 Save to CSV
timestamp = datetime.now().strftime("%Y%m%d_%H%M")

# Define the folder where you want to save
save_dir = r"SAVE DIRECTORY"

# Make sure the folder exists
os.makedirs(save_dir, exist_ok=True)


# Build the full file path
filename = f"reddit_themes_{timestamp}.csv"
filepath = os.path.join(save_dir, filename)

df_reddit.to_csv(filepath, index=False)
print(f" Saved: {filepath}")