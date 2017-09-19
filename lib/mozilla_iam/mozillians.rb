module MozillaIAM
  class Mozillians
    class User
      def initialize()
        @url = 'https://mozillians.org/api/v2/users/'
        @api_key = SiteSetting.mozillians_api_key
      end

      def find_by_email(email)
        result = query(email: email)
        if (result && result['count'] == 1)
          profile = query({}, result['results'][0]['_url'])
        else
          false
        end
      end

      private

      def query(params = {}, url = @url)
        uri = URI(url)
        # workaround for mozillians api returning http urls
        uri.scheme = 'https'
        uri = URI(uri.to_s)
        # end workaround
        uri.query = URI.encode_www_form(params)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri.request_uri)
        request['X-API-KEY'] = @api_key

        response = http.request(request)

        if response.code.to_i == 200
          JSON.parse(response.body)
        else
          false
        end
      end
    end
  end
end
