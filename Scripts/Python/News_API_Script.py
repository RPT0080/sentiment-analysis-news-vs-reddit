# news_scraper.py     IMPORT FROM NEWS API
import requests
import csv
import os
from textblob import TextBlob
from datetime import datetime, timedelta


API_KEY = 'INSERT API KEY HERE'

themes = {
    "mental_health": "mental health OR mindfulness OR coping skills OR anxiety OR therapy OR psychology OR self-help",
    "global_conflict": "war OR protest OR refugee OR diplomacy OR international relations OR united nations",
    "crime_justice": "crime OR trial OR community safety OR police OR justice OR public safety OR legal reform",
    "climate": "climate OR wildfire OR climate change OR sustainability OR environment OR conservation OR renewable energy",
    "economy_jobs": "job search OR unemployment OR hiring OR layoffs OR economic growth OR career OR economy OR inflation OR workforce OR cost of living",
    "education_learning": "education OR school OR college OR tuition OR university OR learning OR studying OR degree OR literacy OR higher education",
    "wellness_growth": "wellness OR well-being OR self-care OR self improvement OR habits OR journaling OR meditation OR growth mindset OR lifestyle",
    "tech_innovation": "innovation OR research OR breakthrough OR GPT-4 OR space OR quantum computing OR AI development OR clean tech OR robotics OR future technology",
    "culture_media": "film OR television OR pop culture OR music OR art OR media OR entertainment OR literature OR fashion OR social media"
}




#  Date range for past month
to_date = datetime.today().strftime('%Y-%m-%d')
from_date = (datetime.today() - timedelta(days=30)).strftime('%Y-%m-%d')


def get_sentiment(text):
    return TextBlob(text).sentiment.polarity  # -1 (negative) to 1 (positive)

def fetch_news(query, theme_name):
    endpoint = f"https://newsapi.org/v2/everything?q={query}&language=en&pageSize=100&from={from_date}&to={to_date}&sortBy=publishedAt&apiKey={API_KEY}"
    response = requests.get(endpoint)
    articles = response.json().get('articles', [])
    data = []

    
    for article in articles:
        title = article.get('title', '') or ''
        description = article.get('description', '') or ''
        full_text = f"{title}. {description}"
        sentiment = get_sentiment(full_text)

        # ⏰ use publishedAt if present, otherwise fallback to "now"
        published_at = article.get('publishedAt')
        if published_at:
            try:
                # convert ISO string to epoch
                published_at = datetime.fromisoformat(published_at.replace("Z", "+00:00")).timestamp()
            except Exception:
                published_at = datetime.utcnow().timestamp()
        else:
            published_at = datetime.utcnow().timestamp()

        data.append({
            'title': title,
            'description': description,
            'sentiment': sentiment,
            'created_utc': published_at,
            'theme': query
        })
    
    
    print(f"Pulled {len(articles)} articles.")
    return data

def save_to_csv(data, filename):
    if not data:
        print("no data to save")
        return
    with open(filename, mode='w', newline='', encoding='utf-8') as file:
        writer = csv.DictWriter(file, fieldnames=data[0].keys())
        writer.writeheader()
        writer.writerows(data)
        
if __name__ == "__main__":
    all_data = []
    for theme_name, query in themes.items():
        all_data.extend(fetch_news(query, theme_name))

    timestamp = datetime.now().strftime("%Y%m%d_%H%M")
     # target folder
    save_dir = r"SAVE DIRECTORY"
    os.makedirs(save_dir, exist_ok=True)
    
      # build full file path
    filename = f"newsapi_themes_{timestamp}.csv"
    filepath = os.path.join(save_dir, filename)
    
    # save
    save_to_csv(all_data, filepath)
    print(f"Saved {len(all_data)} headlines to {filepath}")
