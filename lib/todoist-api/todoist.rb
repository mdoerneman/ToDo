module Todoist
  API_BASE = 'http://todoist.com/API'
  
  ERRORS = [
    '"LOGIN_ERROR"',
    '"ALREADY_REGISTRED"',
    '"TOO_SHORT_PASSWORD"',
    '"INVALID_EMAIL"',
    '"INVALID_TIMEZONE"',
    '"INVALID_FULL_NAME"',
    '"UNKNOWN_ERROR"',
    '"ERROR_PASSWORD_TOO_SHORT"',
    '"ERROR_EMAIL_FOUND"',
    '"ERROR_PROJECT_NOT_FOUND"',
    '"ERROR_NAME_IS_EMPTY"',
    '"ERROR_WRONG_DATE_SYNTAX"',
    '"ERROR_ITEM_NOT_FOUND"'
  ].freeze
  
  class AuthError     < Exception ; end
  class ApiError      < Exception ; end
  
  # Configure API with token
  def self.configure(token)
    Base.configure(token)
  end
  
  # Configure API by authentication
  def self.login(email, password)
    Base.login(email, password)
  end
end