import pandas as pd
import numpy
import sqlite3
from datetime import date

### Database ###

conn = sqlite3.connect("Tweets.db")
c = conn.cursor()


# pd.set_option('display.max_columns', None)



# checks for users with tweet count > 150 / day and delete user and tweets
def deleteBots():
	sqlQuery = "SELECT * FROM User Order BY created_at ASC"
	df = pd.read_sql_query(sqlQuery, conn)
	df['created_at'] = df['created_at'].str.split('T', 0, expand=True)
	df.created_at = pd.to_datetime(df.created_at)
	df = df.set_index("created_at")

	bots = []
	endtime = pd.Timestamp('2021-03-31')
	for index, row in df.iterrows():
		delta = endtime - index
		if delta.days == 0:
			continue
		if row['tweet_count'] / delta.days > 150:
			# print("bot detected: ", row['name'], row['username'])
			bots.append(row['user_id'])

	with conn:
		for b in bots:
			c.execute("""DELETE FROM Tweet WHERE author_id = '%s'""" % b)
			c.execute("""DELETE FROM User WHERE user_id = '%s'""" % b)

		

	# print(bots)

	# # delete tweets from bots and check resulting nr of tweets
	# sqlQuery = "SELECT * FROM Tweet Order BY created_at ASC"
	# df = pd.read_sql_query(sqlQuery, conn)

	# for bot in bots:
	# 	df = df[df.author_id != bot]

	# print(len(df.index))




def deleteNoise():
	with conn:
		#delete ads
		c.execute("""DELETE FROM Tweet WHERE tweet_text LIKE '%#kleinanzeigen%' """)
		c.execute("""DELETE FROM Tweet WHERE tweet_text LIKE '%#mietwohnungen%' """)
		c.execute("""DELETE FROM Tweet WHERE tweet_text LIKE 'RT%' """)
		
		# # # #delete Bot
		c.execute("""DELETE FROM Tweet WHERE author_id = 2855732137""" )
		c.execute("""DELETE FROM User WHERE user_id = 2855732137""")

		# # #delete remaining tweets with #kunstmatigentelligentie
		c.execute("""DELETE FROM Tweet WHERE tweet_text LIKE '%kunstmatigeintelligentie%' """)
		# # #delete remaining tweet with #toekomst
		c.execute("""DELETE FROM Tweet WHERE tweet_text LIKE '%#toekomst%' """)
		#delete tweets (ads) with the same tweet_text posted by the same user > 5 times
		c.execute("""DELETE FROM Tweet WHERE rowid IN 
			(SELECT rowid from Tweet where tweet_id IN 
			(select tweet_id from tweet, (SELECT tweet_text as tt, author_id as aid FROM Tweet GROUP BY tweet_text, author_id having count(*) > 1)
			where author_id = aid and tweet_text = tt)
			EXCEPT 
			SELECT MIN(rowid) FROM Tweet GROUP BY tweet_text, author_id having count(*) > 1)""")

		#delete tweets with less than 4 words
		c.execute("""DELETE FROM Tweet WHERE tweet_id IN (SELECT tweet_id FROM Tweet WHERE length(tweet_text) - length(replace(tweet_text, ' ', '')) + 1 < 4)""")

		#delete users without tweets
		c.execute("DELETE FROM User WHERE user_id IN (SELECT user_id from User WHERE user_id NOT IN (select author_id from Tweet))")


# deleteBots()
deleteNoise()
conn.close()