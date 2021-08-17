import sqlite3
from germansentiment import SentimentModel


conn = sqlite3.connect("Tweets.db")
c = conn.cursor()
conn2 = sqlite3.connect("Tweet_sentiment.db")
c2 = conn2.cursor()
with conn2:
    c2.execute("CREATE TABLE IF NOT EXISTS data (tweet_id INTEGER, sentiment TEXT)")
    c2.execute("""CREATE INDEX IF NOT EXISTS "index1" ON data ("tweet_id")""")


# get tweets from DB
tweets = c.execute("""SELECT tweet_id, tweet_text FROM Tweet""").fetchall()
#texts = [t[1] for t in tweets]
#print(tweets[0])

#use model to predict sentiment ('oliverguhr/german-sentiment-bert')
model = SentimentModel()


# calculate sentiment in batches (500 tweets)
for i in range(1,1158):
    data = []
    batch_tweets = tweets[500*(i-1):500*i]
    batch_texts = [t[1] for t in batch_tweets]
    result = model.predict_sentiment(batch_texts)
    
    for j in range(0, len(batch_texts)):
        data.append((batch_tweets[j][0], result[j]))

    with conn2:
        c2.executemany("INSERT INTO data VALUES (?,?)", data)
    print("Batch", i, "inserted.")