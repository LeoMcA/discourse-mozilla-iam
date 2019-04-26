module MozillaIAM
  module ApplicationExtensions
    def check_iam_session
      begin
        return unless current_user
        return if current_user.id < 0

        mozilla_session_data = SessionData.find_or_create(session, request.cookies)

        last_refresh = mozilla_session_data.last_refresh
        logout_delay =
          Rails.cache.fetch('mozilla-iam/logout_delay') do
            ::PluginStore.get('mozilla-iam', 'logout_delay')
          end || 7.days

        if last_refresh + logout_delay < Time.now
          pp <<~EOF
            Mozilla IAM: User session expired
            user_id: #{current_user.id}, last_refresh: #{last_refresh}, logout_delay: #{logout_delay}
          EOF
        else
          mozilla_session_data.update!(last_refresh: Profile.refresh(current_user))
          aal = mozilla_session_data.aal
          unless Profile.for(current_user).is_aal_enough?(aal)
            pp <<~EOF
              Mozilla IAM: AAL not enough, user logged out
              user_id: #{current_user.id}, aal: #{aal},
              session: #{session.to_hash}
            EOF
          end
        end
      rescue => e
        pp("Killed session for user #{current_user.id}: #{e.class} (#{e.message})\n")
        reset_session
        log_off_user
      end
    end
  end
end
