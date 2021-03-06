require 'json'
require 'cgi'
require File.dirname(__FILE__) + '/request'

module EasyTranslate

  module Detection

    # Detect language
    # @param [String, Array] texts - A single string or set of strings to detect for
    # @param [Hash] options - Extra options to pass along with the request
    # @return [String, Array] The resultant language or languages
    def detect(texts, options = nil, http_options={})
      request = DetectionRequest.new(texts, options, http_options)
      # Turn the response into an array of detections
      raw = request.perform_raw
      detections = JSON.parse(raw)['data']['detections'].map do |res|
        res.empty? ? nil : res.first['language']
      end
      # And then return, if they only asked for one, only give one back
      request.multi? ? detections : detections.first
    end

    # A convenience class for wrapping a detection request
    class DetectionRequest < EasyTranslate::Request

      # Set the texts and options
      # @param [String, Array] texts - The text (or texts) to translate
      # @param [Hash] options - Options to override or pass along with the request
      def initialize(texts, options = {}, http_options = {})
        super(options, http_options)
        if replacement_api_key = @options.delete(:api_key)
          @options[:key] = replacement_api_key
        end
        self.texts = texts
      end

      # The params for this request
      # @return [Hash] the params for the request
      def params
        params = super || {}
        params.merge! @options if @options
        params
      end

      # The path for the request
      # @return [String] The path for the request
      def path
        '/language/translate/v2/detect'
      end

      # The body for the request
      # @return [String] the body for the request, URL escaped
      def body
        @texts.map { |t| "q=#{CGI::escape(t)}" }.join '&'
      end

      # Whether or not this was a request for multiple texts
      # @return [Boolean]
      def multi?
        @multi
      end

      private

      # Set the texts for this request
      # @param [String, Array] texts - The text or texts for this request
      def texts=(texts)
        if texts.is_a?(String)
          @multi = false
          @texts = [texts]
        else
          @multi = true
          @texts = texts
        end 
      end

    end

  end

end
