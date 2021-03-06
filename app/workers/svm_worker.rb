class SvmWorker
  include Sidekiq::Worker

  sidekiq_options retry: 0

  def perform(token_id = nil)
    logger.info "start"

    token = token_id.present? ? Token.find(token_id) : take_token_for_svm

    if token.present?
      logger.info "Try Svm::Rate to #{token.word}"
      count = Svm::Rate.new(token).process
      logger.info "Rated #{count} tweets to #{token.word}"
    else
      logger.info "Token not found to Svm::Rate"
    end

    logger.info "done"
  end

  private

  def take_token_for_svm
    Token.active.where(svm_rated_at: nil).svm_rated_at_asc.each do |token|
      if token.present? && Svm::Rate.new(token).can_rate?
        token.update(svm_rated_at: DateTime.current)
      else
        logger.info "Token: #{token.word} not avaliable to run on SVM"
      end
    end.first
  end
end
