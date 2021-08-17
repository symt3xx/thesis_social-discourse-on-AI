import sqlite3
import re
import regex
import emoji
import random

conn = sqlite3.connect("Tweets.db")
conn2 = sqlite3.connect("Preprocessed_tweets.db")
c = conn.cursor()
c2 = conn2.cursor()

with conn2:
	c2.execute("CREATE TABLE IF NOT EXISTS data (tweet_text TEXT, verified INTEGER, created_at TEXT)")
with conn:
	res = c.execute("SELECT tweet_text, verified, Tweet.created_at from Tweet, User WHERE Tweet.author_id = User.user_id").fetchall()

tweets = []

# randomly pick 50000 numbers/tweets from the dataset
# randoms = random.sample(range(0,len(res)-1), 50000)

for r in res:
	t = r[0]
	# print(r[2])

	# remove hyperlinks
	t = re.sub("http[^\s]+", "", t)
	# remove any words starting with "@"
	t = re.sub("@#?[^\s]+", "", t)
	# remove special character
	t = re.sub("&amp[^\s]+", "", t)
	#remove hashtag symbol
	t = t.replace("#","")
	#remove newline
	t = t.replace("\n", " ")
	# remove smileys
	t = emoji.get_emoji_regexp().sub(r'',t)

	tweets.append((t, r[1], r[2]))


with conn2:
	c2.executemany("INSERT INTO data VALUES (?,?,?)", tweets)

