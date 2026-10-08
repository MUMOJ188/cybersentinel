import { useEffect, useState } from "react";
import { Layout } from "../../components/Layout";
import { ADMIN_NAV } from "./Dashboard";
import { api } from "../../api/client";

interface AdminUser {
  id: string;
  full_name: string;
  username: string;
  email: string;
  status: "active" | "disabled";
  role: string;
}

export default function Users() {
  const [users, setUsers] = useState<AdminUser[]>([]);

  async function reload() {
    const { data } = await api.get("/admin/users");
    setUsers(data.users);
  }

  useEffect(() => {
    reload();
  }, []);

  async function toggleStatus(u: AdminUser) {
    const status = u.status === "active" ? "disabled" : "active";
    await api.put(`/admin/users/${u.id}/status`, { status });
    reload();
  }

  return (
    <Layout title="Administrator" nav={ADMIN_NAV}>
      <h1 className="text-lg font-semibold mb-4">Users</h1>
      <div className="cs-table-wrap">
      <table className="w-full text-sm">
        <thead className="text-slate-500 text-xs uppercase text-left">
          <tr>
            <th className="py-2">Name</th>
            <th>Username</th>
            <th>Email</th>
            <th>Role</th>
            <th>Status</th>
            <th></th>
          </tr>
        </thead>
        <tbody>
          {users.map((u) => (
            <tr key={u.id} className="border-t border-slate-800">
              <td className="py-2">{u.full_name}</td>
              <td>{u.username}</td>
              <td className="text-slate-400">{u.email}</td>
              <td>{u.role}</td>
              <td>
                <span className={u.status === "active" ? "text-emerald-400" : "text-red-400"}>{u.status}</span>
              </td>
              <td>
                <button
                  onClick={() => toggleStatus(u)}
                  className="text-xs bg-slate-800 hover:bg-slate-700 border border-slate-700 rounded px-2 py-1"
                >
                  {u.status === "active" ? "Disable" : "Enable"}
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
      </div>
      {users.length === 0 && <div className="text-slate-600 text-sm mt-4">No users yet.</div>}
    </Layout>
  );
}
