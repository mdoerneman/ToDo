module Todoist
  class Base
    @@api_token = nil
    
    def self.configure(token)
      @@api_token = token
    end
    
    def self.login(email, password)
      raise ArgumentError, 'Email required' if email.to_s.empty?
      raise ArgumentError, 'Password required' if password.to_s.empty?
      
      resp = request('login', :email => email, :password => password)
      unless resp.nil?
        @@api_token = resp['api_token']
        return @@api_token
      else
        raise AuthError, 'Invalid email or password!'
      end
    end
    
    def self.request(method, params={})
      if @@api_token.nil? && !['login', 'register'].include?(method)
        raise Todoist::AuthError, "Authentication required!"
      end
      
      url = "#{API_BASE}/#{method}"
      params[:token] = @@api_token unless @@api_token.nil?
      resp = RestClient.get(url, :accept => :json, :params => params) { |response, request, result, &block|
        case response.code
          when 200
            response.return!(request, result, &block)
          when 400
            raise Todoist::ApiError, result.body
          when 401
            raise Todoist::AuthError
        end
      }
      
      unless ERRORS.include?(resp.body)
        resp.body == '"ok"' ? true : JSON.parse(resp.body)
      else
        raise Todoist::ApiError.new(resp.body)
      end
    end
    
    def request(method, params={})
      Base.request(method, params)
    end
  end
end
