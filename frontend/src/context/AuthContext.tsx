import { createContext, useContext, useEffect, useState, ReactNode } from "react";
import { api } from "../api/client";
import type { User } from "../types";

interface RegisterPayload {
  full_name: string;
  username: string;
  email: string;
  password: string;
  password_confirmation: string;
  role_name: "administrator" | "security_analyst" | "manager";
}

interface AuthContextValue {
  user: User | null;
  token: string | null;
  loading: boolean;
  login: (identifier: string, password: string) => Promise<User>;
  register: (payload: RegisterPayload) => Promise<void>;
  logout: () => void;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const [token, setToken] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const storedToken = localStorage.getItem("cybersentinel_token");
    const storedUser = localStorage.getItem("cybersentinel_user");
    if (storedToken && storedUser) {
      setToken(storedToken);
      setUser(JSON.parse(storedUser));
    }
    setLoading(false);
  }, []);

  function persist(newToken: string, newUser: User) {
    localStorage.setItem("cybersentinel_token", newToken);
    localStorage.setItem("cybersentinel_user", JSON.stringify(newUser));
    setToken(newToken);
    setUser(newUser);
  }

  async function login(identifier: string, password: string) {
    const { data } = await api.post("/auth/login", { identifier, password });
    persist(data.token, data.user);
    return data.user as User;
  }

  async function register(payload: RegisterPayload) {
    // Intentionally does NOT persist the returned token/user — registration
    // creates the account only; the person must log in separately afterward.
    await api.post("/auth/register", payload);
  }

  function logout() {
    api.post("/auth/logout").catch(() => {});
    localStorage.removeItem("cybersentinel_token");
    localStorage.removeItem("cybersentinel_user");
    setToken(null);
    setUser(null);
  }

  return (
    <AuthContext.Provider value={{ user, token, loading, login, register, logout }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}