defmodule CybersentinelWeb.Router do
  use Phoenix.Router
  import Plug.Conn
  import Phoenix.Controller

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :browser do
    plug(:accepts, ["html"])
  end

  pipeline :auth do
    plug(CybersentinelWeb.Plugs.AuthPipeline)
  end

  pipeline :admin_only do
    plug(CybersentinelWeb.Plugs.RequireRole, ["administrator"])
  end

  pipeline :analyst_only do
    plug(CybersentinelWeb.Plugs.RequireRole, ["security_analyst"])
  end

  pipeline :manager_only do
    plug(CybersentinelWeb.Plugs.RequireRole, ["manager"])
  end

  # analyst or admin (admin can view/operate the analyst workflow for demos)
  pipeline :analyst_or_admin do
    plug(CybersentinelWeb.Plugs.RequireRole, ["security_analyst", "administrator"])
  end

  ## Public

  scope "/api/auth", CybersentinelWeb do
    pipe_through(:api)

    post("/register", AuthController, :register)
    post("/login", AuthController, :login)
    post("/forgot-password", AuthController, :forgot_password)
    post("/reset-password", AuthController, :reset_password_with_token)
  end

  ## Authenticated (any role)

  scope "/api", CybersentinelWeb do
    pipe_through([:api, :auth])

    post("/auth/logout", AuthController, :logout)
    get("/auth/me", AuthController, :me)
    post("/auth/password-reset", AuthController, :reset_password)

    get("/dashboard/stats", DashboardController, :stats)
  end

  ## Administrator

  scope "/api/admin", CybersentinelWeb.Admin, as: :admin do
    pipe_through([:api, :auth, :admin_only])

    resources("/users", UserController, only: [:index, :show, :update])
    put("/users/:id/status", UserController, :set_status)
    resources("/detection-rules", DetectionRuleController)
    get("/audit-logs", AuditLogController, :index)
  end

  ## Security Analyst (+ admin, for demo convenience)

  scope "/api", CybersentinelWeb do
    pipe_through([:api, :auth, :analyst_or_admin])

    resources("/security-events", SecurityEventController, only: [:index, :show])
    resources("/alerts", AlertController, only: [:index, :show, :update])
    post("/alerts/:id/acknowledge", AlertController, :acknowledge)

    resources("/incidents", IncidentController)
    resources("/investigations", InvestigationController, only: [:index, :show, :create, :update])
    post("/investigations/:id/notes", InvestigationController, :add_note)
    resources("/response-actions", ResponseActionController, only: [:index, :create])

    # Safe simulated event generation
    scope "/simulation", Simulation, as: :simulation do
      post("/failed-login", SimulationController, :failed_login)
      post("/port-scan", SimulationController, :port_scan)
      post("/suspicious-ip", SimulationController, :suspicious_ip)
      post("/data-transfer", SimulationController, :data_transfer)
      post("/access-denied", SimulationController, :access_denied)
      post("/unknown-device", SimulationController, :unknown_device)
    end
  end

  ## Manager

  scope "/api/manager", CybersentinelWeb.Manager, as: :manager do
    pipe_through([:api, :auth, :manager_only])

    get("/incidents", IncidentController, :index)
    get("/incidents/:id", IncidentController, :show)
    get("/alerts", AlertController, :index)
    get("/reports/summary", ReportController, :summary)
    get("/reports/trends", ReportController, :trends)
    get("/reports/export", ReportController, :export)
  end

  if Application.compile_env(:cybersentinel, :dev_routes) do
    scope "/dev" do
      pipe_through([:browser])
      forward("/mailbox", Plug.Swoosh.MailboxPreview)
    end
  end
end
