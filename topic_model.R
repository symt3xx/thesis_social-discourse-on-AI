library(stm)
library(quanteda)
library(RSQLite)
library(ggplot2)
library(wordcloud)


#get data from database, create text corpus

conn <- RSQLite::dbConnect(RSQLite::SQLite(), "Preprocessed_tweets.db")
data <- RSQLite::dbGetQuery(conn, "SELECT * FROM data")
processed <- textProcessor(data$tweet_text, language = "de", customstopwords = c("mal", "wäre", "hätte", "denen", "rund", "eben", "vielleicht", "jemand", "gar", "beim", "daraus", "daran", "schon", "statt", "daher", "dafür", "darin", "darum", "dass", "darüber", "davon"))
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 5)



#remove tweets from "tweets" that have been deleted during textProcessor()
c <- 1
tweets_r <- c()
for (i in 1:length(tweets)) {
  if(i %in% tweets_to_remove) {
    next
  }
  tweets_r[c] <- tweets[i]
  c <- c+1
  }

#remove tweets from "tweets_r" that have been deleted during PrepDocuments()
tweets_to_remove2 <- out$docs.removed
d <- 1
tweets_r2 <- c()
for (i in 1:length(tweets_r)) {
  if(i %in% tweets_to_remove2) {
    next
  }
  tweets_r2[d] <- tweets_r[i]
  d <- d+1
}




#plotRemoved(processed$documents, lower.thresh = seq(1, 15, by = 1))
#storage <- searchK(out$documents, out$vocab, K = c(5,50))
#options(max.print=10000)
#print words for a document
#for (word in docs[[111]][1,]) {
#  print(vocab[[word]])
#}



# Estimate topic models for different K

model1 <- stm(documents = out$documents, vocab = out$vocab, K = 10, max.em.its = 20, data = out$meta, init.type = "Spectral")
model2 <- stm(documents = out$documents, vocab = out$vocab, K = 20, max.em.its = 20, data = out$meta, init.type = "Spectral")
model3 <- stm(documents = out$documents, vocab = out$vocab, K = 30, max.em.its = 20, data = out$meta, init.type = "Spectral")
model4 <- stm(documents = out$documents, vocab = out$vocab, K = 40, max.em.its = 20, data = out$meta, init.type = "Spectral")
model5 <- stm(documents = out$documents, vocab = out$vocab, K = 50, max.em.its = 20, data = out$meta, init.type = "Spectral")
model6 <- stm(documents = out$documents, vocab = out$vocab, K = 60, max.em.its = 20, data = out$meta, init.type = "Spectral")
model7 <- stm(documents = out$documents, vocab = out$vocab, K = 70, max.em.its = 20, data = out$meta, init.type = "Spectral")
model8 <- stm(documents = out$documents, vocab = out$vocab, K = 80, max.em.its = 20, data = out$meta, init.type = "Spectral")
model9 <- stm(documents = out$documents, vocab = out$vocab, K = 100, max.em.its = 20, data = out$meta, init.type = "Spectral")




# Estimate topic model with topical prevalence parameter (created_at)
topicLabels = c("Chatbots", "Text processing", "AI creates art", "Ethics / data privacy / regulation", "Deepfake / fake news", "Conferences / talks about logistics, IT-security, e-commerce", "Cryptocurrency trading", "Potential / application and risks of AI", "Education / job offers", "Robots / autonomous cars", "Impact of AI on the labour market", "Future technologies", "Google search algorithm", "AI Strategy of federal government / politics", "Big Data, IoT", "Social Media (reach)", "Image recognition / face recognition", "Microsoft", "Promoting articles", "Events", "Events / conferences about digitization / digital transformation", "Content suggestions from algorithms", "Facebook / Twitter news feed algorithm", "Facebook algorithm", "Decisions made by machines", "Deep Learning / Machine Learning", "Human brain vs AI / linking human brain with AI", "Voice Assistants")

# generate numeric day variable
convertToInteger <- function(created_at) {
  startDate = as.Date("2008-01-03")
  for (i in 1:length(created_at)) {
    date = as.Date(strsplit(created_at[[i]], "T")[[1]][1])
  #print(as.numeric(date-startDate))
    created_at[[i]] = as.integer(date-startDate)
  }
  return(created_at)
}



#estimate topic model with topical prevalence covariates created_at and verified
#conn <- RSQLite::dbConnect(RSQLite::SQLite(), "Preprocessed_tweets.db")
#data <- RSQLite::dbGetQuery(conn, "SELECT * FROM data WHERE created_at > '2007-12-31'")
#data$created_at <- convertToInteger(data$created_at)
#processed <- textProcessor(data$tweet_text, metadata = data, language = "de", customstopwords = c("mal", "wäre", "hätte", "denen", "rund", "eben", "vielleicht", "jemand", "gar", "beim", "daraus", "daran", "schon", "statt", "daher", "dafür", "darin", "darum", "dass", "darüber", "davon"))
#out$meta$created_at <- as.integer(out$meta$created_at)
#model6 <- stm(documents = out$documents, vocab = out$vocab, K = 60, prevalence =~ verified + s(created_at), max.em.its = 20, data = out$meta, init.type = "Spectral")
#prep <- estimateEffect(1:60 ~ verified + s(created_at), model6, meta = out$meta, uncertainty = "Global")


#estimate topic model with topical prevalence covariates influencer, media, most_liked, most_replied, most_retweeted
#conn <- RSQLite::dbConnect(RSQLite::SQLite(), "Preprocessed_tweets2.db")
#data <- RSQLite::dbGetQuery(conn, "SELECT * FROM data")
#processed <- textProcessor(data$tweet_text, metadata = data[c(1,3,4,5,6,7,8,9)], language = "de", customstopwords = c("mal", "wäre", "hätte", "denen", "rund", "eben", "vielleicht", "jemand", "gar", "beim", "daraus", "daran", "schon", "statt", "daher", "dafür", "darin", "darum", "dass", "darüber", "davon"))
#out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 5)
#model6 <- stm(documents = out$documents, vocab = out$vocab, K = 60, prevalence =~ influencer + media + most_liked + most_replied + most_retweeted + company + politician, max.em.its = 20, data = out$meta, init.type = "Spectral")
#prep <- estimateEffect(1:60 ~ influencer + media + most_liked + most_replied + most_retweeted + company + politician, model6, meta = out$meta, uncertainty = "Global")

#estimate topic model with topical prevalence covariate sentiment
conn <- RSQLite::dbConnect(RSQLite::SQLite(), "Preprocessed_tweets3.db")
data <- RSQLite::dbGetQuery(conn, "SELECT tweet_text, sentiment FROM data")
processed <- textProcessor(data$tweet_text, metadata = data, language = "de", customstopwords = c("mal", "wäre", "hätte", "denen", "rund", "eben", "vielleicht", "jemand", "gar", "beim", "daraus", "daran", "schon", "statt", "daher", "dafür", "darin", "darum", "dass", "darüber", "davon"))
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 5)
model6_sentiment <- stm(documents = out$documents, vocab = out$vocab, K = 60, prevalence =~ sentiment, max.em.its = 20, data = out$meta, init.type = "Spectral")
prep_sentiment <- estimateEffect(1:60 ~ sentiment, model6_sentiment, meta = out$meta, uncertainty = "Global")


#estimate topic model with topical prevalence covariate sentiment*day
conn <- RSQLite::dbConnect(RSQLite::SQLite(), "Preprocessed_tweets3.db")
data <- RSQLite::dbGetQuery(conn, "SELECT tweet_text, created_at, sentiment FROM data")
data$created_at <- convertToInteger(data$created_at)
processed <- textProcessor(data$tweet_text, metadata = data, language = "de", customstopwords = c("mal", "wäre", "hätte", "denen", "rund", "eben", "vielleicht", "jemand", "gar", "beim", "daraus", "daran", "schon", "statt", "daher", "dafür", "darin", "darum", "dass", "darüber", "davon"))
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 5)
out$meta$created_at <- as.integer(out$meta$created_at)
model6_moderation <- stm(documents = out$documents, vocab = out$vocab, K = 60, prevalence =~ sentiment * s(created_at), max.em.its = 20, data = out$meta, init.type = "Spectral")
prep_moderation <- estimateEffect(1:60 ~ sentiment * s(created_at), model6_moderation, metadata = out$meta, uncertainty = "Global")


#estimate topic model with moderation
conn <- RSQLite::dbConnect(RSQLite::SQLite(), "Preprocessed_tweets3.db")
data <- RSQLite::dbGetQuery(conn, "SELECT * FROM data")
processed <- textProcessor(data$tweet_text, metadata = data, language = "de", customstopwords = c("mal", "wäre", "hätte", "denen", "rund", "eben", "vielleicht", "jemand", "gar", "beim", "daraus", "daran", "schon", "statt", "daher", "dafür", "darin", "darum", "dass", "darüber", "davon"))
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 5)
model6_moderation2 <- stm(documents = out$documents, vocab = out$vocab, K = 60, prevalence =~ sentiment * influencer + sentiment * media + sentiment * most_liked + sentiment * most_replied + sentiment * most_retweeted + sentiment * company + sentiment * politician, max.em.its = 20, data = out$meta, init.type = "Spectral")
prep_moderation2 <- estimateEffect(1:60 ~ sentiment * influencer + sentiment * media + sentiment * most_liked + sentiment * most_replied + sentiment * most_retweeted + sentiment * company + sentiment * politician, model6_moderation2, metadata = out$meta, uncertainty = "Global")


#estimate topic model with covariate location and moderation location * sentiment (germany, austria, switzerland)
conn <- RSQLite::dbConnect(RSQLite::SQLite(), "Tweets_covariate_location_sentiment.db")
data <- RSQLite::dbGetQuery(conn, "SELECT tweet_text, location, sentiment FROM data")
processed <- textProcessor(data$tweet_text, metadata = data, language = "de", customstopwords = c("mal", "wäre", "hätte", "denen", "rund", "eben", "vielleicht", "jemand", "gar", "beim", "daraus", "daran", "schon", "statt", "daher", "dafür", "darin", "darum", "dass", "darüber", "davon"))
out <- prepDocuments(processed$documents, processed$vocab, processed$meta, lower.thresh = 5)
model6_location <- stm(documents = out$documents, vocab = out$vocab, K = 60, prevalence =~ location + sentiment * location, max.em.its = 20, data = out$meta, init.type = "Spectral")
prep_location <- estimateEffect(1:60 ~ location + sentiment * location, model6_location, meta = out$meta, uncertainty = "Global")




### plot the effects of the covariates and moderation



#plot covariates created_at and verified
plot1 <- plot.estimateEffect(prep, "created_at", method = "continuous", topics = c(11,28), ci.level= 0,  model = model6, printlegend = TRUE, xaxt = "n", xlab = "Time")
monthseq <- seq(from = as.Date("2008-01-01"), to = as.Date("2020-07-01"), by = "year")
monthnames <- months(monthseq)
axis(1,at = as.numeric(monthseq) - min(as.numeric(monthseq)), labels = c("2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020"))

topicLabels2 = c("Conferences / talks about logistics, IT-security, e-commerce", "Ethics / data privacy / regulation", "Deepfake / fake news", "Chatbots", "Cryptocurrency trading", "Potential / application and risks of AI", "Education / job offers", "Impact of AI on the labour market", "Google search algorithm", "AI Strategy of federal government / politics", "Big Data, IoT", "Social Media (reach)", "Microsoft", "Events", "Facebook / Twitter news feed algorithm", "Facebook algorithm",  "Deep Learning / Machine Learning","Decisions made by machines", "Events about digitization / digital transformation")
plot.estimateEffect(prep, covariate = "verified", topics = c(14,11,12,3,15,16,17,22,25,26,28,32,36,39,44,52,57,53,40), model = model6, method = "difference", cov.value1 = 1, cov.value2 = 0,
                    xlab = "Non-verified ... verified", xlim = c(-.025, .025), labeltype = "custom",
                    custom.labels = topicLabels2)

#plot covarites influencer, media, most_liked, most_replied, most_retweeted, company
topicLabels2 = c("Conferences / talks about logistics, IT-security, e-commerce", "Ethics / data privacy / regulation", "Deepfake / fake news", "Chatbots", "Cryptocurrency trading", "Potential / application and risks of AI", "Education / job offers", "Impact of AI on the labour market", "Google search algorithm", "AI Strategy of federal government / politics", "Big Data, IoT", "Social Media (reach)", "Microsoft", "Events", "Facebook / Twitter news feed algorithm", "Facebook algorithm",  "Deep Learning / Machine Learning","Decisions made by machines", "Events about digitization / digital transformation")
plot.estimateEffect(prep, covariate = "most_retweeted", topics = c(3,7,10,11,12,14,15,16,17,20,22,23,25,26,28,32,34,36,37,39,40,43,44,52,53,57,58,59), model = model6, method = "difference", cov.value1 = 1, cov.value2 = 0,
                    xlab = "Non-company ... company", xlim = c(-.05, .05), labeltype = "custom",
                    custom.labels = topicLabels, width = 40)



# plot covariate sentiment
plot.estimateEffect(prep_sentiment, covariate = "sentiment", topics = c(3,7,10,11,12,14,15,16,17,20,22,23,25,26,28,32,34,36,37,39,40,43,44,52,53,57,58,59), 
                    model = model6_sentiment, method = "difference", cov.value1 = "positive", cov.value2 = "neutral",
                    xlab = "Non-verified ... verified", xlim = c(-.05, .05), labeltype = "custom",
                    custom.labels = topicLabels)


#plot the moderation of created_at * sentiment
plot.estimateEffect(prep_moderation, topics=c(16), covariate = "created_at", model = model6_moderation, method = "continuous", xlab = "Year", moderator = "sentiment",
                    moderator.value = "positive", linecol = "green", ylim = c(0, .05), printlegend = F, ci.level = 0, xaxt = "n")
plot(prep_moderation, covariate = "created_at", model = model6_moderation, method = "continuous", xlab = "Days", moderator = "sentiment",
     moderator.value = "neutral", linecol = "blue", add = T, printlegend = F, ci.level = 0)
plot(prep_moderation, covariate = "created_at", model = model6_moderation, method = "continuous", moderator = "sentiment",
     moderator.value = "negative", linecol = "red", add = T, printlegend = F, ci.level = 0, xlab = "Time")

monthseq <- seq(from = as.Date("2008-01-01"), to = as.Date("2020-07-01"), by = "year")
monthnames <- months(monthseq)
axis(1,at = as.numeric(monthseq) - min(as.numeric(monthseq)), labels = c("2008", "2009", "2010", "2011", "2012", "2013", "2014", "2015", "2016", "2017", "2018", "2019", "2020"))
legend(0, .05, c("Positive", "Neutral", "Negative"), lwd = 2, col = c("green", "blue", "red"))


# plot moderation of covariates * sentiment
plot.estimateEffect(prep_moderation2, covariate = "sentiment", topics = c(3,7,10,11,12,14,15,16,17,20,22,23,25,26,28,32,34,36,37,39,40,43,44,52,53,57,58,59), 
                    model = model6_moderation2, method = "difference", cov.value1 = "positive", cov.value2 = "negative",
                    moderator = "influencer", moderator.value = 1, xlab = "negative ... positive", xlim = c(-.1, .1), labeltype = "custom",
                    custom.labels = topicLabels)

# plot covariate location
plot.estimateEffect(prep_location, covariate = "location", topics = c(3,7,10,11,12,14,15,16,17,20,22,23,25,26,28,32,34,36,37,39,40,43,44,52,53,57,58,59), 
                    model = model6_location, method = "difference", cov.value1 = "germany", cov.value2 = "austria",
                    xlab = "Non-verified ... verified", xlim = c(-.05, .05), labeltype = "custom",
                    custom.labels = topicLabels)









#summary(prep, topics=c(3,11,22))


### Evaluate model performance


# create vector with semCoh and exclu for all models
semCoh <- semanticCoherence(model = model1, documents = out$documents)
semCoh <- c(semCoh, semanticCoherence(model = model2, documents = out$documents))
semCoh <- c(semCoh, semanticCoherence(model = model3, documents = out$documents))
semCoh <- c(semCoh, semanticCoherence(model = model4, documents = out$documents))
semCoh <- c(semCoh, semanticCoherence(model = model5, documents = out$documents))
semCoh <- c(semCoh, semanticCoherence(model = model6, documents = out$documents))
semCoh <- c(semCoh, semanticCoherence(model = model7, documents = out$documents))
semCoh <- c(semCoh, semanticCoherence(model = model8, documents = out$documents))
semCoh <- c(semCoh, semanticCoherence(model = model9, documents = out$documents))
exclu <- exclusivity(model = model1)
exclu <- c(exclu, exclusivity(model = model2))
exclu <- c(exclu, exclusivity(model = model3))
exclu <- c(exclu, exclusivity(model = model4))
exclu <- c(exclu, exclusivity(model = model5))
exclu <- c(exclu, exclusivity(model = model6))
exclu <- c(exclu, exclusivity(model = model7))
exclu <- c(exclu, exclusivity(model = model8))
exclu <- c(exclu, exclusivity(model = model9))

#calculate semantic coherence and exclusivity for all models
semCoh_model1 <- semanticCoherence(model = model1, documents = out$documents)
semCoh_model2 <- semanticCoherence(model = model2, documents = out$documents)
semCoh_model3 <- semanticCoherence(model = model3, documents = out$documents)
semCoh_model4 <- semanticCoherence(model = model4, documents = out$documents)
semCoh_model5 <- semanticCoherence(model = model5, documents = out$documents)
semCoh_model6 <- semanticCoherence(model = model6, documents = out$documents)
semCoh_model7 <- semanticCoherence(model = model7, documents = out$documents)
semCoh_model8 <- semanticCoherence(model = model8, documents = out$documents)
semCoh_model9 <- semanticCoherence(model = model9, documents = out$documents)

exclu_model1 <- exclusivity(model = model1)
exclu_model2 <- exclusivity(model = model2)
exclu_model3 <- exclusivity(model = model3)
exclu_model4 <- exclusivity(model = model4)
exclu_model5 <- exclusivity(model = model5)
exclu_model6 <- exclusivity(model = model6)
exclu_model7 <- exclusivity(model = model7)
exclu_model8 <- exclusivity(model = model8)
exclu_model9 <- exclusivity(model = model9)



#generate dataframe
color <- c()
for (i in 1:10) {
  if (i == 9) {
    next
  }
  for (j in (1:(10*i))) {
    color = c(color, paste("t",i,sep=""))
  }
}
dataf <- data.frame(semCoh, exclu, color)


# plot semantic coherence and exclusivity in scatterplot
ggplot(dataf, aes(x=semCoh, y=exclu, color=color ))+
  geom_point(size = 1, alpha = 0.7) +
  labs(x = "Semantic coherence",
       y = "Exclusivity")





# create data frame with mean semantic coherence and mean exclusivity by number of topics
df <- data.frame(topics=c(10,20,30,40,50,60,70,80,100), semCoh=c(mean(semCoh_model1), mean(semCoh_model2), mean(semCoh_model3), mean(semCoh_model4), mean(semCoh_model5), mean(semCoh_model6), mean(semCoh_model7), mean(semCoh_model8), mean(semCoh_model9)))
df2 <- data.frame(topics=c(10,20,30,40,50,60,70,80,100), exclu=c(mean(exclu_model1), mean(exclu_model2), mean(exclu_model3), mean(exclu_model4), mean(exclu_model5), mean(exclu_model6), mean(exclu_model7), mean(exclu_model8), mean(exclu_model9)))

# plot semantic coherence in line chart
ggplot(data=df, aes(x=topics, y=semCoh, group=1)) +
  geom_line()+
  geom_point()+
  labs(x = "Number of topics",
       y = "Semantic Coherence")+
  scale_x_continuous(n.breaks = 10)+
  theme_bw()+
  theme(
    plot.background = element_blank(),
    #panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    axis.line = element_line(color = 'black'),
    text = element_text(size=14),
    axis.title.x = element_text(margin = margin(t = 20, r = 0, b = 0, l = 0), size=13),
    axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0), size=13)
    )

# plot exclusivity in line chart
ggplot(data=df2, aes(x=topics, y=exclu, group=1)) +
  geom_line()+
  geom_point()+
  labs(x = "Number of topics",
       y = "Exclusivity")+
  scale_x_continuous(n.breaks = 10)+
  theme_bw()+
  theme(
    plot.background = element_blank(),
    #panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.border = element_blank(),
    axis.line = element_line(color = 'black'),
    text = element_text(size=14),
    axis.title.x = element_text(margin = margin(t = 20, r = 0, b = 0, l = 0), size=13),
    axis.title.y = element_text(margin = margin(t = 0, r = 20, b = 0, l = 0), size=13)
  )
  



#print topic keywords
labels <-labelTopics(model6, n =25)
for (i in 1:length(labels$prob[,1])) {
  cat(paste("Topic",i,"\n"))
  for (j in 1:length(labels$prob[1,])) {
    cat(paste(labels$prob[i,j],"\n"), sep =" ")
  }
  cat("\n")
}





nrtopics = 34

#display word cloud for topics' keywords
cloud(model6, topic=nrtopics, max.words = 80)

#inpsect tweets that are highly associated with a topic
findThoughts(model = model6, topics = nrtopics, texts = tweets_r2, n=500)$docs
#options(max.print=1000)

# visualize topic correlations
topicCor <- topicCorr(model6, cutoff = 0.01)
plot.topicCorr(topicCor, topics = c(3,7,10,11,12,14,15,16,17,20,22,23,25,26,28,32,34,36,37,39,40,43,44,52,53,57,58,59), vlabels = topicLabels)

topicCor$cor[3,40]


# visualize topic proportions
plot.STM(model6, type ="summary", topics = c(3,7,10,11,12,14,15,16,17,20,22,23,25,26,28,32,34,36,37,39,40,43,44,52,53,57,58,59), topic.names = c("") ,custom.labels = topicLabels)
plot.STM(model6, type="perspectives", topics = c(39,37))





#labels <- c("topic1","topic2","topic3","topic4","topic5","topic6","topic7","topic8","topic9","topic10","topic11","topic12","topic13",
#            "topic14","topic15","topic16","topic17","topic18","topic19","topic20",)
#proportion <- as.data.frame(colSums(model6$theta/nrow(model6$theta)))

#df <- proportion
#df <- df[order(-proportion), ] 