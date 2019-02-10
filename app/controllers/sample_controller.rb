# frozen_string_literal: true

class SampleController < ApplicationController
  def create
    collect if build_new_token && @token.save
  end

  def tags
    @token = Token.find_by_uuid(params[:id])
  end

  private

  def build_new_token
    @token = Token.new(token_params)
  end

  def token_params
    params.require(:sample).permit(:word).merge(defaut_values)
  end

  def defaut_values
    { lang: 'all', enable: false }
  end

  def collect
    SampleWorker.perform_async(@token.id)
  end
end
