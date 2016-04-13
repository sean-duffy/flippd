require 'json'

module QuizUtils
    def is_quiz_passed(user_id, quiz_id)
        matches = QuizResult.first(:user_id => user_id, :json_id => quiz_id, :pass => true)
        if matches == nil
            return false
        else
            return true
        end
    end
end
