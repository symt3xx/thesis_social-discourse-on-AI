# add metadata as topic prevalence covariates
import csv
import sqlite3
import re
import emoji
import pandas as pd


conn = sqlite3.connect("Tweets.db")
conn2 = sqlite3.connect("Preprocessed_tweets2.db")
conn3 = sqlite3.connect("Tweet_sentiment.db")
conn4 = sqlite3.connect("Preprocessed_tweets3.db")
conn5 = sqlite3.connect("Tweets_covariate_location_sentiment.db")
c = conn.cursor()
c2 = conn2.cursor()
c3 = conn3.cursor()
c4 = conn4.cursor()
c5 = conn5.cursor()

# c2.execute("""ALTER TABLE data ADD most_retweeted INTEGER""")
#c2.execute("""UPDATE data SET most_retweeted=-1""")
#conn2.commit()

def add_covariates():

	with conn2:
		c2.execute("CREATE TABLE IF NOT EXISTS data (tweet_text TEXT, tweet_id INTEGER, influencer INTEGER, media INTEGER, most_liked INTEGER, most_replied INTEGER, most_retweeted INTEGER, company INTEGER, politician INTEGER)")
		c2.execute("""CREATE INDEX IF NOT EXISTS "index1" ON data ("tweet_id")""")
	with conn:
		res = c.execute("SELECT tweet_text, tweet_id from Tweet, User WHERE Tweet.author_id = User.user_id AND Tweet.created_at > '2007-12-31'").fetchall()


	tweets = []
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

		tweets.append((t, r[1], -1, -1, -1, -1, -1, -1, -1))


	with conn2:
		c2.executemany("INSERT INTO data VALUES (?,?,?,?,?,?,?,?,?)", tweets)



	print("start adding meta data")
	#18854 tweets
	influencer = c.execute("""SELECT tweet_id FROM Tweet, (SELECT user_id FROM User WHERE followers_count > 30000) 
	WHERE author_id = user_id""").fetchall()
	for i in influencer:
		c2.execute("""UPDATE data SET influencer=1 WHERE tweet_id= '%s'""" % i[0])
	conn2.commit()




	most_liked = c.execute("""SELECT tweet_id FROM Tweet WHERE like_count > 20""").fetchall() # 7339 tweets 
	most_replied = c.execute("""SELECT tweet_id FROM Tweet WHERE reply_count > 3""").fetchall() # 3931 tweets
	most_retweeted = c.execute("""SELECT tweet_id FROM Tweet WHERE retweet_count > 8""").fetchall() #6817 tweets

	for m in most_liked:
		c2.execute("""UPDATE data SET most_liked=1 WHERE tweet_id= '%s'""" % m[0])
	conn2.commit()

	for m in most_replied:
		c2.execute("""UPDATE data SET most_replied=1 WHERE tweet_id= '%s'""" % m[0])
	conn2.commit()

	for m in most_retweeted:
		c2.execute("""UPDATE data SET most_retweeted=1 WHERE tweet_id= '%s'""" % m[0])
	conn2.commit()


	media_handelsblatt = c.execute("""SELECT tweet_id FROM Tweet WHERE author_id = 5776022""").fetchall()
	media_faz = c.execute("""SELECT tweet_id FROM Tweet WHERE author_id = 18016521""").fetchall()
	media_SZ = c.execute("""SELECT tweet_id FROM Tweet WHERE author_id = 17803524 OR author_id = 19767324""").fetchall() # SZ Top-News, SZ Digital
	media_diezeit = c.execute("""SELECT tweet_id FROM Tweet WHERE author_id = 1081459807""").fetchall()
	media_bild = c.execute("""SELECT tweet_id FROM Tweet WHERE author_id = 9204502 OR author_id = 35707087""").fetchall() # BILD, BILD Digital
	media_t3n = c.execute("""SELECT tweet_id FROM Tweet WHERE author_id = 11060982""").fetchall()
	media_heise = c.execute("""SELECT tweet_id FROM Tweet WHERE author_id = 3197921""").fetchall()


	for m in media_handelsblatt:
		c2.execute("""UPDATE data SET media=1 WHERE tweet_id= '%s'""" % m[0])
	for m in media_faz:
		c2.execute("""UPDATE data SET media=1 WHERE tweet_id= '%s'""" % m[0])
	for m in media_SZ:
		c2.execute("""UPDATE data SET media=1 WHERE tweet_id= '%s'""" % m[0])
	for m in media_diezeit:
		c2.execute("""UPDATE data SET media=1 WHERE tweet_id= '%s'""" % m[0])
	for m in media_bild:
		c2.execute("""UPDATE data SET media=1 WHERE tweet_id= '%s'""" % m[0])
	for m in media_t3n:
		c2.execute("""UPDATE data SET media=1 WHERE tweet_id= '%s'""" % m[0])
	for m in media_heise:
		c2.execute("""UPDATE data SET media=1 WHERE tweet_id= '%s'""" % m[0])

	conn2.commit()


	with open('companies_DACH_user_ids.csv', 'r') as file:
	    reader = csv.reader(file)
	    for row in reader:
	        company_tweets = c.execute("""SELECT tweet_id from Tweet WHERE author_id = '%s'""" % row[3]).fetchall()
	        for comp in company_tweets:
	            #tweets.append(comp[0])
	            c2.execute("""UPDATE data SET company=1 WHERE tweet_id= '%s'""" % comp[0])
	conn2.commit()

	with open('politicians.csv', 'r') as file:
	    reader = csv.reader(file)
	    for row in reader:
	        politicians_tweets = c.execute("""SELECT tweet_id from Tweet WHERE author_id = '%s'""" % row[3]).fetchall()
	        for tweet in politicians_tweets:
	            #tweets.append(tweet[0])
	            c2.execute("""UPDATE data SET politician=1 WHERE tweet_id= '%s'""" % tweet[0])
	conn2.commit()


	c2.execute("""UPDATE data SET influencer = 0 WHERE influencer = -1""")
	c2.execute("""UPDATE data SET most_liked = 0 WHERE most_liked = -1""")
	c2.execute("""UPDATE data SET most_replied = 0 WHERE most_replied = -1""")
	c2.execute("""UPDATE data SET most_retweeted = 0 WHERE most_retweeted = -1""")
	c2.execute("""UPDATE data SET media = 0 WHERE media = -1""")
	c2.execute("""UPDATE data SET company = 0 WHERE company = -1""")
	c2.execute("""UPDATE data SET politician = 0 WHERE politician = -1""")
	conn2.commit()



def add_sentiment_covariate():
	df1 = pd.read_sql_query("SELECT tweet_id, created_at FROM Tweet", conn)
	df2 = pd.read_sql_query("SELECT * FROM data", conn2)
	df3 = pd.read_sql_query("SELECT tweet_id, sentiment FROM data", conn3)


	df = pd.merge(df1,df2, how="inner", on="tweet_id")
	df = pd.merge(df,df3, how="inner", on="tweet_id")

	df.to_sql(name='data', con=conn4, index=False)



def add_country_covariate():
	tweets_germany = pd.read_sql_query(""" SELECT tweet_id, location FROM Tweet, (SELECT user_id, location FROM User WHERE location LIKE '%Germany%' OR location LIKE '%Deutschland%' OR location LIKE '%Berlin%' OR location LIKE '%München%' OR location LIKE '%Hamburg%')
								WHERE Tweet.author_id = user_id """, conn)
	tweets_germany['location'] = "germany"

	tweets_austria = pd.read_sql_query("""SELECT tweet_id, location FROM Tweet, (SELECT user_id, location FROM User WHERE location LIKE '%Austria%' OR location LIKE '%Österreich%' OR location LIKE '%Wien%' OR location LIKE '%Linz%' OR location LIKE '%Graz%')
								WHERE Tweet.author_id = user_id """, conn)
	tweets_austria['location'] = "austria"

	tweets_switzerland = pd.read_sql_query("""SELECT tweet_id, location FROM Tweet, (SELECT user_id, location FROM User WHERE location LIKE '%Switzerland%' OR location LIKE '%Schweiz%' OR location LIKE '%Zürich%' OR location LIKE '%Aarau%' OR location LIKE '%Bern%')
								WHERE Tweet.author_id = user_id """, conn)
	tweets_switzerland['location'] = "switzerland"

	sentiments = pd.read_sql_query("SELECT tweet_id, sentiment FROM data", conn3)
	tweets_DACH = pd.concat([tweets_germany, tweets_austria, tweets_switzerland], ignore_index=True, sort=False)

	tweets_text = pd.read_sql_query("""SELECT tweet_id, tweet_text FROM data""", conn4)

	df = pd.merge(tweets_DACH,sentiments, how="inner", on="tweet_id")
	df = pd.merge(df,tweets_text, how="inner", on="tweet_id")

	df = df.drop_duplicates(subset=['tweet_id'])


	df.to_sql(name='data', con=conn5, index=False)


# add_covariates()
# add_sentiment_covariate()
add_country_covariate()


conn2.close()


