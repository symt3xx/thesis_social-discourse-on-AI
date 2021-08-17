import os
import json
import time
import sqlite3
from TwitterAPI import TwitterAPI
import time




### Database ###

conn = sqlite3.connect("Tweets.db")
c = conn.cursor()

def create_database():
	with conn:
		c.execute("""CREATE TABLE IF NOT EXISTS Tweet
			/* Tweet.fields */ (tweet_id INTEGER, tweet_text TEXT, created_at TEXT, author_id INTEGER, context_annotations TEXT, entities TEXT, conversation_id INTEGER,
			/* public metrics */ retweet_count INTEGER, reply_count INTEGER, like_count INTEGER, quote_count INTEGER, 
			reply_settings TEXT, source TEXT, withheld TEXT, attachments TEXT, place_id TEXT,
			UNIQUE(tweet_id), FOREIGN KEY (author_id) REFERENCES User (user_id),  FOREIGN KEY (place_id) REFERENCES Place (place_id))""")
		c.execute("""CREATE INDEX IF NOT EXISTS Index_TweetID ON Tweet (tweet_id)""")
		c.execute("""CREATE INDEX IF NOT EXISTS Index_AuthorID ON Tweet (author_id)""")


		c.execute("""CREATE TABLE IF NOT EXISTS User (user_id INTEGER, created_at TEXT, description TEXT, entities TEXT, location TEXT, name TEXT, username TEXT, verified TEXT, 
			/* public metrics */ followers_count INTEGER, following_count INTEGER, tweet_count INTEGER, listed_count INTEGER, withheld TEXT, protected TEXT, UNIQUE(user_id))""")
		c.execute("""CREATE INDEX IF NOT EXISTS Index_UserID ON User (user_id)""")


		c.execute("""CREATE TABLE IF NOT EXISTS Place (place_id TEXT, full_name TEXT, country TEXT, geo TEXT, name TEXT, place_type TEXT, UNIQUE(place_id))""")
# c.execute("""CREATE TABLE IF NOT EXISTS Media (media_id TEXT, type TEXT, duration_ms INTEGER, view_count INTEGER, url TEXT, UNIQUE(media_id))""")
		




def insertTweet(tweet_id, tweet_text, created_at, author_id, context_annotations, entities, conversation_id, retweet_count, reply_count, 
	like_count, quote_count, reply_settings, source, withheld, attachments, place_id):
	# print("inserting Tweet: ", tweet_id)
	with conn:
		c.execute("INSERT OR IGNORE INTO Tweet VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (tweet_id, tweet_text, created_at, author_id, context_annotations, entities, conversation_id, retweet_count, reply_count, 
	like_count, quote_count, reply_settings, source, withheld, attachments, place_id))		


def insertUser(user_id, created_at, description, entities, location, name, username, verified, followers_count, following_count, tweet_count, listed_count, withheld, protected):
	with conn:
		c.execute("INSERT OR IGNORE INTO User VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)", (user_id, created_at, description, entities, location, name, username, verified, 
			followers_count, following_count, tweet_count, listed_count, withheld, protected))	


# def insertMedia(media_id, type, duration_ms, view_count, url):
# 	with conn:
# 		c.execute("INSERT OR IGNORE INTO Media VALUES (?,?,?,?,?)", (media_id, type, duration_ms, view_count, url))

def insertPlace(place_id, full_name, country, geo, name, place_type):
	with conn:
		c.execute("INSERT OR IGNORE INTO Place VALUES (?,?,?,?,?,?)", (place_id, full_name, country, geo, name, place_type))






### TwitterAPI ###



def requestTweets():
	next_token = ""
	start_time = time.time()

	while True:
		# check request limit
		while time.time() - start_time < 3.1:
			time.sleep(0.3)

		start_time = time.time()
		consumer_key = os.environ.get("TAPI_KEY")	
		consumer_secret = os.environ.get("TAPI_SKEY")
		QUERY = '("Künstliche Intelligenz" OR "Algorithmus" OR "Algorithmen" OR "Artificial Intelligence" OR #AI OR #KI) lang:de -is:retweet'
		START_TIME = "2006-03-21T00:00:00Z"
		END_TIME = "2020-07-01T00:00:00Z"
		MAX_RESULTS = 500
		EXPANSIONS = 'author_id,attachments.media_keys,geo.place_id'
		TWEET_FIELDS = 'created_at,author_id,public_metrics,context_annotations,entities,conversation_id,attachments,reply_settings,source,withheld'
		USER_FIELDS = 'created_at,description,entities,name,username,location,verified,public_metrics,withheld,protected'
		MEDIA_FIELDS = 'type,url,public_metrics,duration_ms'
		PLACE_FIELDS = 'country,name,place_type,geo'


		api = TwitterAPI(consumer_key, consumer_secret, auth_type="oAuth2", api_version='2')

		search_params = {
					'query': {QUERY}, 
					'start_time': START_TIME,
					'end_time': END_TIME,
					'max_results': MAX_RESULTS,
					'expansions': EXPANSIONS,
					'media.fields': MEDIA_FIELDS,
					'tweet.fields': TWEET_FIELDS,
					'user.fields': USER_FIELDS,
					'place.fields': PLACE_FIELDS,
				}
		# print(search_params)
		if next_token:
			search_params['next_token'] = next_token

		# print(search_params)

		# request data
		r = api.request('tweets/search/all', search_params, hydrate_tweets=True)

		# for each result: insert user if not exists and insert tweet into db
		for t in r:
			# print(t, end="\n\n")
			user = t['author_id']		
			insertUser(user['id'], user['created_at'], str(user['description']), str(user.get("entities","")), user.get("location",""), user['name'], user['username'], user['verified'],
				user['public_metrics']['followers_count'], user['public_metrics']['following_count'], user['public_metrics']['tweet_count'], user['public_metrics']['listed_count'], 
				str(user.get("withheld","")), user.get("protected",""))
			
			p_id = ""
			if 'geo' in t:
				p = t['geo']['place_id']
				insertPlace(p.get('id', ""), p.get('full_name', ""), p.get('country', ""), str(p.get('geo', "")), p.get('name', ""), p.get('place_type', ""))
				p_id = p.get('id', "")

			insertTweet(t['id'], t['text'], t['created_at'], t['author_id']['id'], str(t.get("context_annotations", "")), str(t.get("entities", "")), t['conversation_id'], 
				t['public_metrics']['retweet_count'], t['public_metrics']['reply_count'], t['public_metrics']['like_count'], t['public_metrics']['quote_count'],
				 t['reply_settings'], t.get('source',""), str(t.get('withheld',"")), str(t.get('attachments', "")), p_id)


		# print('\nINCLUDES')
		# print(r.json()['includes'])
		
		metaData = r.json()['meta']
		# time.sleep(3)


		# get the next_token if more data is available (get next page of results)
		if 'next_token' in metaData:
			# print("weitere Daten verfügbar:\n", metaData['next_token'])
			next_token = metaData['next_token']
		else:
			print("keine weiteren Daten verfügbar")
			break
		# print(r.json()['meta']['next_token'])
		# print('\nQUOTA')
		print(r.get_quota())




create_database()
requestTweets()

conn.close()


