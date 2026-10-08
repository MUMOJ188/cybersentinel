defmodule Cybersentinel.UserNotifier do
  import Swoosh.Email
  alias Cybersentinel.Mailer

  def deliver_password_reset(user, reset_url) do
    email =
      new()
      |> to({user.full_name, user.email})
      |> from({"CyberSentinel", "no-reply@cybersentinel.local"})
      |> subject("Reset your CyberSentinel password")
      |> text_body("""
      Hi #{user.full_name},

      Someone requested a password reset for your CyberSentinel account.
      If this was you, click the link below to set a new password. This
      link expires in 1 hour and can only be used once.

      #{reset_url}

      If you didn't request this, you can safely ignore this email.
      """)

    Mailer.deliver(email)
  end
end
