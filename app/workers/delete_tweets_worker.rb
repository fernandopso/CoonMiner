class DeleteTweetsWorker
  include Sidekiq::Worker

  MAX_TWEETS_TO_DELETE = 1000

  LOG_NAME = 'DeleteTweetsWorker >'

  def perform
    logger.info "#{LOG_NAME} start"

    number_of_tokens_executed = 0

    Token.collect_at_desc.take(15).each do |token|

      bag = token.bag_of_word

      tweets_deleted = false

      if token.tweets.not_rated.more_than_seven_days.any?
        tweets = token.tweets.not_rated.more_than_seven_days.take(MAX_TWEETS_TO_DELETE)
        logger.info "#{LOG_NAME} Take #{tweets.count} old tweets and will be deleted"
      elsif token.company.free? && token.tweets.not_rated.count > Company::MAX_TWEETS
        tweets = token.tweets.not_rated.publish_at_asc.take(MAX_TWEETS_TO_DELETE)
        logger.info "#{LOG_NAME} Free Account - rechead the max limit of tweets - Take #{tweets.count} to be deleted"
      else
        tweets = []
      end

      tweets.each do |tweet|
        logger.info "#{LOG_NAME} Try DeleteTweet to #{tweet}"
        DeleteTweet.new(tweet, bag).process(save_bag_of_words = false)
        tweet.destroy
        tweets_deleted = true
      end

      if tweets_deleted
        number_of_tokens_executed += 1
        bag.save
      end

      break if number_of_tokens_executed == 2
    end

    logger.info "#{LOG_NAME} done"
  end
end
